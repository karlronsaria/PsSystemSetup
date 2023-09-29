@echo off

set "logFile=log_-_%~n0"
set "powershell=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe"

%powershell% -Command Set-ExecutionPolicy RemoteSigned

%powershell% -Command Write-Output %logFile%_$(Get-Date -f yyyy_MM_dd_HHmmss).txt

%powershell% -Command Write-Output "%logFile%_$(Get-Date -f yyyy_MM_dd_HHmmss).txt"

%powershell% -Command Write-Output ('%logFile%' + '_' + $(Get-Date -f yyyy_MM_dd_HHmmss) + '.txt')

%powershell% -Command ('%logFile%' + '_' + $(Get-Date -f yyyy_MM_dd_HHmmss) + '.txt') ^| Write-Output

