@echo off
setlocal
set "PORTABLE_WT=%~dp0windows-terminal-portable\app\terminal-1.24.10621.0\WindowsTerminal.exe"
set "WT_EXE=%LOCALAPPDATA%\Microsoft\WindowsApps\wt.exe"
set "SYNC_SCRIPT=%~dp0sync-terminal-background.ps1"
set "POSITION_SCRIPT=%~dp0position-terminal-window.ps1"

if exist "%SYNC_SCRIPT%" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SYNC_SCRIPT%"
)

if exist "%PORTABLE_WT%" (
    start "" "%PORTABLE_WT%"
) else if exist "%WT_EXE%" (
    start "" "%WT_EXE%"
) else (
    start "" wt.exe
)

if exist "%POSITION_SCRIPT%" (
    start "" powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%POSITION_SCRIPT%"
)

exit /b 0
