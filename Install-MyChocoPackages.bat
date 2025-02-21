:: Andrew_D 2021-11-15

@echo off
set packages=
set packages=%packages% sudo
set packages=%packages% googlechrome
set packages=%packages% 7zip
set packages=%packages% everything
set packages=%packages% git
set packages=%packages% irfanview
set packages=%packages% neovim

:: TODO:
:: Copy 'init.vim' from file share

set command=choco install -y%packages%

if "%~1" == "-whatif" (
    echo What if: %command%
    exit /b
)

@echo on
%command%

@echo off
%~dp0.\res\nvimsettings\script\SetAll.bat

