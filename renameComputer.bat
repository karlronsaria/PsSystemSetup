@echo off

set "path=%~dp0"
set "sourcePath=%path%script\SystemPrepare.ps1"
set "argsPath=%path%res\command.json"

echo Changing script execution policy...
powershell -Command Set-ExecutionPolicy RemoteSigned

set "command=powershell -Command . %sourcePath%"
set "command=%command%; Invoke-FromArgumentFile"
set    "command=%command% -FilePath %argsPath%"
set    "command=%command% -CommandName 'Rename-Computer'"

echo Starting...
%command%

