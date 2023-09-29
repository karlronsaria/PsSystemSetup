:: Requires RunAsAdministrator

@echo off
set "path=%~dp0"
set "machineType=Personal"
set "logFile=log_-_%~n0"

:: TODO:
:: Copy \devlib\ from \OneDrive\Documents\__KASLOVT01\

:: TODO:
:: 'powershell' is not recognized as an internal or external command, operable program or batch file.
set "powershell=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe"

%powershell% -Command Set-ExecutionPolicy RemoteSigned
%powershell% -Command . %path%SystemPrepare.ps1; Start-SystemPrepare -Verbose -AppxDebloatingPreference %machineType%
%powershell% -Command . %path%GlobalAssemblyCache.ps1; Update-Gac -Verbose

%path%Install-Chocolatey.bat

:: TODO:
:: WARNING: It's very likely you will need to close and reopen your shell before you can use choco.
%path%Install-ChocolateyPackages.bat

