@echo off
REM Double-click this. Do not paste Check-HuggingFace.ps1 into PowerShell.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Check-HuggingFace.ps1" %*
echo.
pause
