@echo off

set "path=%~dp0"
set "argsPath=%path%res\command.json"
set "sourcePath=%path%script\SystemPrepare.ps1"

echo Changing script execution policy...
powershell -Command Set-ExecutionPolicy RemoteSigned

set "command=powershell -Command . %sourcePath%"
set "command=%command%; Invoke-FromArgumentFile"
set    "command=%command% -FilePath %argsPath% -All"

echo Starting...
%command%

