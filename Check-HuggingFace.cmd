@echo off
REM Double-click this. Do not paste Check-HuggingFace.ps1 into PowerShell.
cd /d "%~dp0"

if not exist "%~dp0Check-HuggingFace.ps1" (
  echo Check-HuggingFace.ps1 is missing. Getting it onto C:\ ...
  if exist "%~dp0Get-CheckHuggingFace.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Get-CheckHuggingFace.ps1"
    goto :end
  )
  if exist "C:\EV_Operator\Get-CheckHuggingFace.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "C:\EV_Operator\Get-CheckHuggingFace.ps1"
    goto :end
  )
  echo Save Check-HuggingFace.ps1 to C:\EV_Operator\Check-HuggingFace.ps1 then run this again.
  goto :end
)

if not exist "C:\EV_Operator\Check-HuggingFace.ps1" (
  mkdir "C:\EV_Operator" >nul 2>&1
  copy /Y "%~dp0Check-HuggingFace.ps1" "C:\EV_Operator\Check-HuggingFace.ps1" >nul
)
if not exist "C:\EV_Files\teaka_trading_app\Check-HuggingFace.ps1" (
  mkdir "C:\EV_Files\teaka_trading_app" >nul 2>&1
  copy /Y "%~dp0Check-HuggingFace.ps1" "C:\EV_Files\teaka_trading_app\Check-HuggingFace.ps1" >nul
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Check-HuggingFace.ps1" %*

:end
echo.
pause
