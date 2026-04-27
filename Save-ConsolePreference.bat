@echo off

set "path=%~dp0"
:: Uses DateTimeStamp
set "command=powershell -Command Get-Date -f yyyy-MM-dd-HHmmss"

echo Running PowerShell...

for /f %%i in ('%command%') do set "dtstamp=%%i"

set "filename=%path%res\my_-_%dtstamp%_ConsolePreference.reg"
set "command=reg export hkcu\console %filename%"

echo Saving Registry key %key% to %filename%
%command%

