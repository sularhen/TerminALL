[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DistroName,
    [string]$FriendlyName = $DistroName,
    [string]$UserName
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

function Invoke-WslProbe {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,
        [int]$TimeoutSeconds = 20
    )

    $stdoutPath = [System.IO.Path]::GetTempFileName()
    $stderrPath = [System.IO.Path]::GetTempFileName()
    $argumentString = ($ArgumentList | ForEach-Object {
            if ($_ -match '[\s"]') {
                '"' + ($_ -replace '"', '\"') + '"'
            }
            else {
                $_
            }
        }) -join ' '

    try {
        $process = Start-Process -FilePath 'wsl.exe' -ArgumentList $argumentString -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            try {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            }
            catch {
            }

            return [pscustomobject]@{
                TimedOut = $true
                ExitCode = $null
                StdOut = (Get-Content -Path $stdoutPath -Raw -ErrorAction SilentlyContinue)
                StdErr = (Get-Content -Path $stderrPath -Raw -ErrorAction SilentlyContinue)
            }
        }

        return [pscustomobject]@{
            TimedOut = $false
            ExitCode = $process.ExitCode
            StdOut = (Get-Content -Path $stdoutPath -Raw -ErrorAction SilentlyContinue)
            StdErr = (Get-Content -Path $stderrPath -Raw -ErrorAction SilentlyContinue)
        }
    }
    finally {
        Remove-Item -Path $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

function Show-LauncherHelp {
    param([string]$Detail)

    Write-Host ''
    Write-Host "[$FriendlyName] WSL is not responding right now." -ForegroundColor Yellow
    Write-Host "[$FriendlyName] WSL no esta respondiendo en este momento." -ForegroundColor Yellow
    if ($Detail) {
        Write-Host ''
        Write-Host $Detail -ForegroundColor DarkYellow
    }
    Write-Host ''
    Write-Host 'Reboot Windows to reset WSL/Hyper-V, then open Terminal again.' -ForegroundColor Cyan
    Write-Host 'Reinicia Windows para reiniciar WSL/Hyper-V y luego abre Terminal de nuevo.' -ForegroundColor Cyan
    Write-Host 'If it keeps happening, run setup-terminal.cmd again.' -ForegroundColor Cyan
    Write-Host 'Si sigue pasando, ejecuta setup-terminal.cmd otra vez.' -ForegroundColor Cyan
    Write-Host ''
    Read-Host 'Press ENTER / Presiona ENTER' | Out-Null
}

function Get-WslArguments {
    param(
        [string[]]$CommandArguments = @()
    )

    $arguments = @('-d', $DistroName)
    if ($UserName) {
        $arguments += @('-u', $UserName)
    }

    if ($CommandArguments) {
        $arguments += $CommandArguments
    }

    return $arguments
}

try {
    $status = Invoke-WslProbe -ArgumentList @('--status') -TimeoutSeconds 20
    if ($status.TimedOut) {
        Show-LauncherHelp
        exit 1
    }

    $distros = Invoke-WslProbe -ArgumentList @('-l', '-q') -TimeoutSeconds 20
    if ($distros.TimedOut) {
        Show-LauncherHelp
        exit 1
    }

    $distroList = @(
        ($distros.StdOut -split "`r?`n") |
        ForEach-Object { $_.ToString().Replace([string][char]0, '').Trim() } |
        Where-Object { $_ }
    )

    if ($distroList -notcontains $DistroName) {
        Show-LauncherHelp -Detail "The distro '$DistroName' is not installed yet. / La distro '$DistroName' todavia no esta instalada."
        exit 1
    }

    $probe = Invoke-WslProbe -ArgumentList (Get-WslArguments -CommandArguments @('--', 'sh', '-lc', 'echo WSL_READY')) -TimeoutSeconds 25
    $probeOutput = ($probe.StdOut -replace [string][char]0, '').Trim()
    $probeExitCode = if ($null -eq $probe.ExitCode -and $probeOutput -match 'WSL_READY') { 0 } else { $probe.ExitCode }
    if ($probe.TimedOut -or ($null -ne $probeExitCode -and $probeExitCode -ne 0) -or $probeOutput -notmatch 'WSL_READY') {
        $detail = @($probe.StdErr, $probe.StdOut) | Where-Object { $_ -and $_.Trim() } | Select-Object -First 1
        Show-LauncherHelp -Detail $detail
        exit 1
    }

    & wsl.exe @(Get-WslArguments)
    exit $LASTEXITCODE
}
catch {
    Show-LauncherHelp -Detail $_.Exception.Message
    exit 1
}
