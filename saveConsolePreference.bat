@echo off

set "path=%~dp0"
set "resourcePath=%path%res\ConsolePreference.reg"
:: TODO:
set "powershell=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "reg=%SystemRoot%\System32\reg.exe"
set "key=hkcu\console"
set "command=%powershell% -Command Get-Date -f yyyy_MM_dd_HHmmss"

setlocal EnableDelayedExpansion

echo Running PowerShell...

for /f %%i in ('%command%') do (
    set "dtstamp=%%i"
)

set "filename=%path%res\my_-_!dtstamp!_ConsolePreference.reg"
set "command=%reg% export %key% !filename!"

echo Saving Registry key %key% to !filename!
%command%

endlocal

