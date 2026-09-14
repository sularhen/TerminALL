@echo off
setlocal
set "SYNC_SCRIPT=%~dp0sync-terminal-background.ps1"
set "LAYOUT_SCRIPT=%~dp0launch-terminal-layout.ps1"

if exist "%SYNC_SCRIPT%" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SYNC_SCRIPT%"
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%LAYOUT_SCRIPT%"

exit /b %errorlevel%
