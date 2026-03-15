@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-terminal.ps1"
exit /b %errorlevel%
