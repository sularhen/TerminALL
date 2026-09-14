[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$DistroName,
    [string]$FriendlyName = $DistroName,
    [string]$UserName,
    [ValidateRange(1, 5)][int]$RetryCount = 3
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom
$repoRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
Import-Module (Join-Path $repoRoot 'TerminALL.Common.psm1') -Force

function Invoke-WslProbe {
    param([Parameter(Mandatory = $true)][string[]]$ArgumentList, [int]$TimeoutSeconds = 12)

    $stdoutPath = [System.IO.Path]::GetTempFileName()
    $stderrPath = [System.IO.Path]::GetTempFileName()
    $argumentString = ($ArgumentList | ForEach-Object {
            if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
        }) -join ' '
    try {
        $process = Start-Process -FilePath 'wsl.exe' -ArgumentList $argumentString -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            return [pscustomobject]@{ TimedOut = $true; ExitCode = $null; StdOut = ConvertTo-FlatText (Get-Content -LiteralPath $stdoutPath -ErrorAction SilentlyContinue); StdErr = ConvertTo-FlatText (Get-Content -LiteralPath $stderrPath -ErrorAction SilentlyContinue) }
        }
        return [pscustomobject]@{ TimedOut = $false; ExitCode = $process.ExitCode; StdOut = ConvertTo-FlatText (Get-Content -LiteralPath $stdoutPath -ErrorAction SilentlyContinue); StdErr = ConvertTo-FlatText (Get-Content -LiteralPath $stderrPath -ErrorAction SilentlyContinue) }
    }
    finally {
        Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-WslProbeWithRetry {
    param([Parameter(Mandatory = $true)][string[]]$ArgumentList, [int]$TimeoutSeconds = 12)

    $last = $null
    for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
        $last = Invoke-WslProbe -ArgumentList $ArgumentList -TimeoutSeconds $TimeoutSeconds
        if (-not $last.TimedOut -and ($null -eq $last.ExitCode -or $last.ExitCode -eq 0)) { return $last }
        if ($attempt -lt $RetryCount) { Start-Sleep -Milliseconds (350 * $attempt) }
    }
    return $last
}

function Show-LauncherHelp {
    param([string]$Detail)

    Write-Host "[$FriendlyName] WSL is not ready after $RetryCount quick attempts." -ForegroundColor Yellow
    Write-Host "[$FriendlyName] WSL no esta listo despues de $RetryCount intentos rapidos." -ForegroundColor Yellow
    if ($Detail) { Write-Host $Detail -ForegroundColor DarkYellow }
    Write-Host 'Try: wsl --shutdown, wait a few seconds, and open TerminALL again.' -ForegroundColor Cyan
    Write-Host 'Prueba: wsl --shutdown, espera unos segundos y abre TerminALL otra vez.' -ForegroundColor Cyan
    Write-Host 'Then inspect: wsl --status and wsl --list --verbose. Update with wsl --update if needed.' -ForegroundColor Cyan
    Write-Host 'Luego revisa: wsl --status y wsl --list --verbose. Actualiza con wsl --update si hace falta.' -ForegroundColor Cyan
    Write-Host 'A Windows reboot is the last fallback, not the first step. / Reiniciar Windows es el ultimo recurso.' -ForegroundColor DarkGray
}

function Get-WslArguments {
    param([string[]]$CommandArguments = @())
    $arguments = @('-d', $DistroName)
    if ($UserName) { $arguments += @('-u', $UserName) }
    if ($CommandArguments) { $arguments += $CommandArguments }
    return $arguments
}

try {
    $status = Invoke-WslProbeWithRetry -ArgumentList @('--status')
    if ($status.TimedOut -or ($null -ne $status.ExitCode -and $status.ExitCode -ne 0)) {
        Show-LauncherHelp -Detail (ConvertTo-FlatText @($status.StdErr, $status.StdOut))
        exit 1
    }

    $distros = Invoke-WslProbeWithRetry -ArgumentList @('-l', '-q')
    $distroList = @((ConvertTo-FlatText $distros.StdOut) -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($distros.TimedOut -or $distroList -notcontains $DistroName) {
        Show-LauncherHelp -Detail "The distro '$DistroName' is not installed. / La distro '$DistroName' no esta instalada."
        exit 1
    }

    if ($DistroName -eq 'kali-linux') {
        $versions = Invoke-WslProbeWithRetry -ArgumentList @('-l', '-v')
        $kaliLine = @((ConvertTo-FlatText $versions.StdOut) -split "`r?`n" | Where-Object { $_ -match '(?i)kali-linux' }) | Select-Object -First 1
        if ($kaliLine -and $kaliLine -notmatch '\s2\s*$') {
            Show-LauncherHelp -Detail 'Kali must remain on WSL 2. Run: wsl --set-version kali-linux 2 / Kali debe permanecer en WSL 2.'
            exit 1
        }
    }

    $probe = Invoke-WslProbeWithRetry -ArgumentList (Get-WslArguments -CommandArguments @('--', 'sh', '-lc', 'printf WSL_READY')) -TimeoutSeconds 15
    # Windows PowerShell 5 can expose ExitCode=$null for redirected wsl.exe
    # processes, and WSL2 may keep its relay alive after writing stdout. The
    # explicit marker proves the command ran inside the requested distro.
    if ($probe.StdOut -notmatch 'WSL_READY') {
        Show-LauncherHelp -Detail (ConvertTo-FlatText @($probe.StdErr, $probe.StdOut))
        exit 1
    }

    & wsl.exe @(Get-WslArguments)
    exit $LASTEXITCODE
}
catch {
    Show-LauncherHelp -Detail $_.Exception.Message
    exit 1
}
