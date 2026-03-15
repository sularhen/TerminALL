[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$BackgroundFolder = Join-Path $ScriptRoot 'terminal-background'
$SupportedExtensions = '.png', '.jpg', '.jpeg', '.bmp', '.gif'

function Get-CurrentBackgroundImage {
    if (-not (Test-Path $BackgroundFolder)) {
        return $null
    }

    $images = Get-ChildItem -Path $BackgroundFolder -File -ErrorAction SilentlyContinue |
        Where-Object { $SupportedExtensions -contains $_.Extension.ToLowerInvariant() } |
        Sort-Object -Property @(
            @{ Expression = 'LastWriteTimeUtc'; Descending = $true },
            @{ Expression = 'Name'; Descending = $false }
        )

    return $images | Select-Object -First 1
}

function Update-SettingsFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$BackgroundImagePath
    )

    if (-not (Test-Path $Path)) {
        return
    }

    $settings = Get-Content -Path $Path -Raw | ConvertFrom-Json
    if ($null -eq $settings.profiles) {
        return
    }

    if ($null -eq $settings.profiles.defaults) {
        $settings.profiles | Add-Member -NotePropertyName 'defaults' -NotePropertyValue ([pscustomobject]@{})
    }

    $defaults = $settings.profiles.defaults

    if ($BackgroundImagePath) {
        if ($null -eq $defaults.PSObject.Properties['backgroundImage']) {
            $defaults | Add-Member -NotePropertyName 'backgroundImage' -NotePropertyValue $BackgroundImagePath
        }
        else {
            $defaults.backgroundImage = $BackgroundImagePath
        }

        if ($null -eq $defaults.PSObject.Properties['backgroundImageOpacity']) {
            $defaults | Add-Member -NotePropertyName 'backgroundImageOpacity' -NotePropertyValue 0.45
        }
        else {
            $defaults.backgroundImageOpacity = 0.45
        }
    }
    else {
        if ($null -ne $defaults.PSObject.Properties['backgroundImage']) {
            $defaults.PSObject.Properties.Remove('backgroundImage')
        }

        if ($null -ne $defaults.PSObject.Properties['backgroundImageOpacity']) {
            $defaults.PSObject.Properties.Remove('backgroundImageOpacity')
        }
    }

    $settings | ConvertTo-Json -Depth 100 | Set-Content -Path $Path -Encoding UTF8
}

$backgroundImage = Get-CurrentBackgroundImage
$backgroundPath = if ($backgroundImage) { $backgroundImage.FullName } else { $null }

$settingsPaths = @(
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $ScriptRoot 'windows-terminal-portable\app\terminal-1.24.10621.0\settings\settings.json')
)

foreach ($settingsPath in $settingsPaths) {
    Update-SettingsFile -Path $settingsPath -BackgroundImagePath $backgroundPath
}
