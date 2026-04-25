@echo off

:: link: Re-enable Group Policy Editor
:: - url
::   - <https://drive.google.com/file/d/1H3WiXQpaYOQ7rMZGh_sEfDue-KUhomDW/view>
::   - <https://drive.usercontent.google.com/download?id=1H3WiXQpaYOQ7rMZGh_sEfDue-KUhomDW&export=download&authuser=0>
:: - retrieved: 2025-07-24

pushd "%~dp0"

dir /b %SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum >List.txt
dir /b %SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum >>List.txt

for /f %%i in ('findstr /i . List.txt 2^>nul') do dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i"
pause
popd

