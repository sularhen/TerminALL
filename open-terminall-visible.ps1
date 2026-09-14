$ErrorActionPreference = 'Stop'

$repoRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$launcher = Join-Path $repoRoot 'launch-terminal-layout-admin.cmd'

if (-not (Test-Path -LiteralPath $launcher)) {
    throw "No se encontro el launcher: $launcher"
}

Start-Process -FilePath $launcher -WorkingDirectory $repoRoot
