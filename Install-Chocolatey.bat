:: Link: https://gist.github.com/KristofferRisa/4cfd1ca3fec4e86e550c
:: Retrieved: 2021-11-15
@echo off

:: TODO:
:: 'powershell' is not recognized as an internal or external command, operable program or batch file.
set "powershell=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe"
%powershell% -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin
