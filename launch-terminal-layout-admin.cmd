@echo off
setlocal

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -Verb RunAs -FilePath '%ComSpec%' -ArgumentList '/c ""%~f0"" --elevated'"
    exit /b 0
)

set "SYNC_SCRIPT=%~dp0sync-terminal-background.ps1"
set "LAYOUT_SCRIPT=%~dp0launch-terminal-layout.ps1"

if exist "%SYNC_SCRIPT%" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SYNC_SCRIPT%"
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%LAYOUT_SCRIPT%"

exit /b %errorlevel%
