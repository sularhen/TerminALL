[CmdletBinding()]
param([switch]$NoPosition)

$ErrorActionPreference = 'Stop'
$repoRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
Import-Module (Join-Path $repoRoot 'TerminALL.Common.psm1') -Force

$terminal = Resolve-TerminALLTerminalExecutable -RepoRoot $repoRoot
$arguments = Get-TerminALLLayoutArguments
$argumentString = ConvertTo-TerminALLArgumentString -ArgumentList $arguments

Write-Verbose "Terminal: $terminal"
Write-Verbose "Arguments: $argumentString"
Start-Process -FilePath $terminal -ArgumentList $argumentString -WorkingDirectory $repoRoot

if (-not $NoPosition) {
    $positionScript = Join-Path $repoRoot 'position-terminal-window.ps1'
    if (Test-Path -LiteralPath $positionScript) {
        Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$positionScript`""
    }
}
