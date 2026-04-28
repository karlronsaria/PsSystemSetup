:: Requires RunAsAdministrator

@echo off
set "path=%~dp0./script/"
set "machineType=Personal"
set "logFile=log_-_%~n0"

powershell -Command Set-ExecutionPolicy RemoteSigned
powershell -Command . %path%SystemPrepare.ps1; Start-SystemPrepare -Verbose -AppxDebloatingPreference %machineType%
powershell -Command . %path%GlobalAssemblyCache.ps1; Update-Gac -Verbose

%path%Install-Chocolatey.bat

:: TODO:
:: WARNING: It's very likely you will need to close and reopen your shell before you can use choco.
%path%Install-ChocolateyPackages.bat

