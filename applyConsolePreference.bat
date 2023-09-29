@echo off

set "path=%~dp0"
set "resourcePath=%path%res\ConsolePreference.reg"
set "commandPath=%SystemRoot%\System32\reg.exe"
set "command=%commandPath% import %resourcePath%"

echo Applying Registry change...
%command%

