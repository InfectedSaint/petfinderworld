@echo off
setlocal

REM Path to your PowerShell push script
set "SCRIPT=D:\Pet finder world website\push-site.ps1"

REM Use any text you type after the .bat as the commit message
set "MSG=%*"

REM If no message was passed, ask for one
if "%MSG%"=="" (
  set /p MSG=Commit message (e.g., Add new pet page): 
)

REM Run the PowerShell script with safe permissions
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Message "%MSG%"

echo.
pause
