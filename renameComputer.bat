@echo off

set "path=%~dp0"
set "argsPath=%path%res\command.json"
:: TODO:
set "powershell=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe"

echo Changing script execution policy...
%powershell% -Command Set-ExecutionPolicy RemoteSigned

set "command=%powershell% -Command . %path%SystemPrepare.ps1"
set "command=%command%; Invoke-FromArgumentFile"
set    "command=%command% -FilePath %argsPath%"
set    "command=%command% -CommandName 'Rename-Computer'"

echo Starting...
%command%

