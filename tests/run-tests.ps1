[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $repoRoot 'TerminALL.Common.psm1') -Force
$failures = New-Object System.Collections.Generic.List[string]
$passes = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { $script:passes++; Write-Host "PASS $Message" -ForegroundColor Green }
    else { $script:failures.Add($Message); Write-Host "FAIL $Message" -ForegroundColor Red }
}

# Parse every PowerShell source file without running setup, launchers, or external commands.
foreach ($file in Get-ChildItem -LiteralPath $repoRoot -File -Recurse | Where-Object { $_.Extension -in @('.ps1', '.psm1') }) {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
    Assert-True ($errors.Count -eq 0) "syntax: $($file.FullName.Substring($repoRoot.Length + 1))"
}

$flat = ConvertTo-FlatText @(' first ', 'second', $null)
Assert-True ($flat -eq "first $([Environment]::NewLine)second") 'stdout arrays normalize to one trimmed string'

$layout = @(Get-TerminALLLayoutArguments)
$kaliIndex = [Array]::IndexOf($layout, 'Kali Linux')
$powerShellIndex = [Array]::IndexOf($layout, 'Windows PowerShell')
$ubuntuIndex = [Array]::IndexOf($layout, 'Ubuntu')
Assert-True ($kaliIndex -ge 0 -and $kaliIndex -lt $powerShellIndex -and $powerShellIndex -lt $ubuntuIndex) 'explicit three-pane layout has deterministic split order'
Assert-True ($layout -contains 'TerminALL Kali' -and $layout -contains 'TerminALL Ubuntu' -and $layout -notcontains '--') 'layout uses portable-safe WSL profiles without PowerShell switches'

$settingsCandidates = @(Get-TerminALLSettingsCandidates -LocalAppData 'C:\LocalData' -RepoRoot $repoRoot)
Assert-True ($settingsCandidates.Count -eq 3) 'settings resolver covers Store, Preview, and unpackaged installs'
Assert-True ($settingsCandidates[1] -match 'WindowsTerminalPreview') 'Preview settings path is included'

$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('terminall-test-' + [guid]::NewGuid().ToString('N'))
try {
    $portableFolder = Join-Path $temporaryRoot 'windows-terminal-portable\app\terminal-test'
    New-Item -ItemType Directory -Path $portableFolder -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $portableFolder 'WindowsTerminal.exe') -Force | Out-Null
    $portableCandidates = @(Get-TerminALLSettingsCandidates -LocalAppData 'C:\LocalData' -RepoRoot $temporaryRoot)
    Assert-True ($portableCandidates[0] -eq (Join-Path $portableFolder 'settings\settings.json')) 'portable settings path follows detected executable version'

    $localData = Join-Path $temporaryRoot 'local-data'
    $configuredFolder = Join-Path $temporaryRoot 'external-terminal'
    New-Item -ItemType Directory -Path $configuredFolder -Force | Out-Null
    $configuredExe = Join-Path $configuredFolder 'WindowsTerminal.exe'
    New-Item -ItemType File -Path $configuredExe -Force | Out-Null
    $configPath = Get-TerminALLLocalConfigPath -LocalAppData $localData
    New-Item -ItemType Directory -Path (Split-Path -Parent $configPath) -Force | Out-Null
    @{ terminalExecutable = $configuredExe } | ConvertTo-Json | Set-Content -LiteralPath $configPath
    Assert-True ((Resolve-TerminALLTerminalExecutable -LocalAppData $localData -RepoRoot $temporaryRoot) -eq $configuredExe) 'local terminal selection has highest priority'
    Assert-True ((Get-TerminALLSettingsCandidates -LocalAppData $localData -RepoRoot $temporaryRoot)[0] -eq (Join-Path $configuredFolder 'settings\settings.json')) 'configured portable uses its private settings folder'
    @{ terminalExecutable = (Join-Path $configuredFolder 'missing\WindowsTerminal.exe') } | ConvertTo-Json | Set-Content -LiteralPath $configPath
    $invalidFailed = $false
    try { [void](Resolve-TerminALLTerminalExecutable -LocalAppData $localData -RepoRoot $temporaryRoot) }
    catch { $invalidFailed = $_.Exception.Message -match 'no esta disponible' -and $_.Exception.Message -match 'terminal-config.json' }
    Assert-True $invalidFailed 'invalid local terminal selection fails with checked configuration path'
}
finally { Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue }

$launchSource = Get-Content -LiteralPath (Join-Path $repoRoot 'launch-terminal-layout.ps1') -Raw
$setupSource = Get-Content -LiteralPath (Join-Path $repoRoot 'setup-terminal.ps1') -Raw
$wslSource = Get-Content -LiteralPath (Join-Path $repoRoot 'launch-wsl-profile.ps1') -Raw
Assert-True ($launchSource -notmatch 'startupActions|Set-Content.*settings') 'launcher does not mutate Windows Terminal settings'
Assert-True ($setupSource.Contains('Remove-ObjectProperty -Object $settings -Name ''startupActions''')) 'setup removes legacy global startupActions'
Assert-True ($setupSource -notmatch '--set-version\s+Ubuntu') 'setup never converts Ubuntu version'
Assert-True ($setupSource -match '\$ConfigureOnly' -and $setupSource -match 'if \(-not \$ConfigureOnly\)') 'configure-only mode skips WSL and Kali installation'
Assert-True ($setupSource -match 'Disable-ConflictingTerminalHotkeys' -and $setupSource -match '\$shortcut\.Hotkey = ''''') 'setup backs up and clears competing desktop hotkeys'
Assert-True ($setupSource -match "action = 'togglePaneZoom'" -and $setupSource -match "alt\+shift\+enter") 'setup configures pane zoom hotkey'
$setupCmdSource = Get-Content -LiteralPath (Join-Path $repoRoot 'setup-terminal.cmd') -Raw
Assert-True ($setupCmdSource -match '%\*') 'setup command forwards configure-only arguments'
Assert-True ($wslSource -notmatch 'Read-Host') 'WSL failure path never blocks waiting for ENTER'
Assert-True ($wslSource -match 'RetryCount') 'WSL probes use bounded retries'
$markerCondition = 'if ($probe.StdOut -notmatch ''WSL_READY'')'
$legacyCondition = '$probe.TimedOut -or $probe.ExitCode -ne 0'
Assert-True ($wslSource.Contains($markerCondition) -and -not $wslSource.Contains($legacyCondition)) 'WSL readiness trusts the in-distro marker when PowerShell omits ExitCode'

Assert-True ($setupSource.Contains('Ensure-ObjectProperty -Object $defaults -Name ''useAcrylic'' -Value $false') -and $setupSource.Contains('Ensure-ObjectProperty -Object $defaults -Name ''opacity'' -Value 100')) 'terminal defaults use an opaque high-contrast surface'
Assert-True ($setupSource.Contains('Ensure-ObjectProperty -Object $defaults -Name ''experimental.retroTerminalEffect'' -Value $false')) 'terminal defaults disable retro effect for readable output'
Assert-True ($setupSource.Contains("`$powerShellCommand = 'powershell.exe'")) 'portable PowerShell profile uses a directly executable command'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $repoRoot 'ai'))) 'public project has no AI integration files'

Write-Host "`n$passes passed; $($failures.Count) failed."
if ($failures.Count -gt 0) { throw ('TerminALL tests failed: ' + ($failures -join '; ')) }
