Set-StrictMode -Version 2.0

function Get-TerminALLLocalConfigPath {
    [CmdletBinding()]
    param([string]$LocalAppData = $env:LOCALAPPDATA)

    if (-not $LocalAppData) { return $null }
    return Join-Path $LocalAppData 'TerminALL\terminal-config.json'
}

function Get-TerminALLConfiguredExecutable {
    [CmdletBinding()]
    param([string]$LocalAppData = $env:LOCALAPPDATA)

    $configPath = Get-TerminALLLocalConfigPath -LocalAppData $LocalAppData
    if (-not $configPath -or -not (Test-Path -LiteralPath $configPath -PathType Leaf)) { return $null }
    try {
        $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        return ([string]$config.terminalExecutable).Trim()
    }
    catch {
        throw "Configuracion local de TerminALL invalida: $configPath. $($_.Exception.Message)"
    }
}

function Get-TerminALLPortableSettingsPath {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ExecutablePath)

    return Join-Path (Split-Path -Parent $ExecutablePath) 'settings\settings.json'
}

function ConvertTo-FlatText {
    [CmdletBinding()]
    param([AllowNull()]$Value)

    if ($null -eq $Value) { return '' }
    $parts = @($Value) | ForEach-Object { if ($null -ne $_) { [string]$_ } }
    return (($parts -join [Environment]::NewLine) -replace [string][char]0, '').Trim()
}

function Get-TerminALLTerminalCandidates {
    [CmdletBinding()]
    param([string]$RepoRoot = $PSScriptRoot, [string]$LocalAppData = $env:LOCALAPPDATA)

    $configured = Get-TerminALLConfiguredExecutable -LocalAppData $LocalAppData
    $portable = @()
    $portableRoot = Join-Path $RepoRoot 'windows-terminal-portable'
    if (Test-Path -LiteralPath $portableRoot) {
        $portable = @(Get-ChildItem -LiteralPath $portableRoot -Filter 'WindowsTerminal.exe' -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending | ForEach-Object { $_.FullName })
    }
    $windowsApps = if ($LocalAppData) { Join-Path $LocalAppData 'Microsoft\WindowsApps\wt.exe' } else { $null }
    return @($configured) + @($portable) + @($windowsApps, 'wt.exe') | Where-Object { $_ }
}

function Resolve-TerminALLTerminalExecutable {
    [CmdletBinding()]
    param([string]$RepoRoot = $PSScriptRoot, [string]$LocalAppData = $env:LOCALAPPDATA)

    $configured = Get-TerminALLConfiguredExecutable -LocalAppData $LocalAppData
    if ($configured -and -not (Test-Path -LiteralPath $configured -PathType Leaf)) {
        $configPath = Get-TerminALLLocalConfigPath -LocalAppData $LocalAppData
        throw "Windows Terminal configurado no esta disponible: $configured. Revisa: $configPath"
    }
    foreach ($candidate in @(Get-TerminALLTerminalCandidates -RepoRoot $RepoRoot -LocalAppData $LocalAppData)) {
        if ([System.IO.Path]::IsPathRooted($candidate)) {
            if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
            continue
        }
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    $checked = @(Get-TerminALLTerminalCandidates -RepoRoot $RepoRoot -LocalAppData $LocalAppData) -join [Environment]::NewLine
    throw "Windows Terminal no fue encontrado. Rutas comprobadas / checked paths:$([Environment]::NewLine)$checked"
}

function Get-TerminALLSettingsCandidates {
    [CmdletBinding()]
    param([string]$LocalAppData = $env:LOCALAPPDATA, [string]$RepoRoot = $PSScriptRoot)

    $configured = Get-TerminALLConfiguredExecutable -LocalAppData $LocalAppData
    $configuredSettings = if ($configured) { Get-TerminALLPortableSettingsPath -ExecutablePath $configured } else { $null }
    $portableSettings = @()
    $portableRoot = Join-Path $RepoRoot 'windows-terminal-portable'
    if (Test-Path -LiteralPath $portableRoot) {
        $portableSettings = @(Get-ChildItem -LiteralPath $portableRoot -Filter 'WindowsTerminal.exe' -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending |
            ForEach-Object { Get-TerminALLPortableSettingsPath -ExecutablePath $_.FullName })
    }
    if (-not $LocalAppData) { return $portableSettings }
    return @(@($configuredSettings) + @($portableSettings) + @(
        (Join-Path $LocalAppData 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json')
        (Join-Path $LocalAppData 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json')
        (Join-Path $LocalAppData 'Microsoft\Windows Terminal\settings.json')
    ) | Where-Object { $_ })
}

function Resolve-TerminALLSettingsPath {
    [CmdletBinding()]
    param([string]$LocalAppData = $env:LOCALAPPDATA, [string]$RepoRoot = $PSScriptRoot, [switch]$CreateStoreDirectory)

    $candidates = @(Get-TerminALLSettingsCandidates -LocalAppData $LocalAppData -RepoRoot $RepoRoot)
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath (Split-Path -Parent $candidate) -PathType Container) { return $candidate }
    }
    if ($CreateStoreDirectory) {
        $storePath = if ($LocalAppData) { Join-Path $LocalAppData 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json' } else { $null }
        if ($storePath) {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $storePath) | Out-Null
            return $storePath
        }
    }
    return $null
}

function Get-TerminALLLayoutArguments {
    [CmdletBinding()]
    param()

    # Portable Terminal parses PowerShell switches after split-pane unreliably.
    # These profiles run wsl.exe directly, avoiding that second command parser.
    $arguments = @('-w', 'new', 'new-tab', '--title', 'Kali Linux', '-p', 'TerminALL Kali')
    $arguments += @(
        ';', 'split-pane', '-H', '-s', '0.45', '--title', 'Windows PowerShell', '-p', 'TerminALL PowerShell',
        ';', 'split-pane', '-V', '--title', 'Ubuntu', '-p', 'TerminALL Ubuntu',
        ';', 'move-focus', 'up'
    )
    return $arguments
}

function ConvertTo-TerminALLArgumentString {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string[]]$ArgumentList)

    return (($ArgumentList | ForEach-Object {
                if ($_ -eq ';') { return ';' }
                if ($_ -notmatch '[\s"]') { return $_ }
                return '"' + ($_ -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
            }) -join ' ')
}

Export-ModuleMember -Function ConvertTo-FlatText, Get-TerminALLLocalConfigPath, Get-TerminALLConfiguredExecutable, Get-TerminALLPortableSettingsPath, Get-TerminALLTerminalCandidates, Resolve-TerminALLTerminalExecutable, Get-TerminALLSettingsCandidates, Resolve-TerminALLSettingsPath, Get-TerminALLLayoutArguments, ConvertTo-TerminALLArgumentString
