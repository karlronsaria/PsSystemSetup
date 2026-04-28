@echo off

:: link: unidentified
:: - broken: 2026-04-27
:: - url: <https://gist.github.com/KristofferRisa/4cfd1ca3fec4e86e550c>
:: - retrieved: 2021-11-15

:: issue 2026-04-27-051555
:: - last seen: 2021-11-15
:: - actual: 'powershell' is not recognized as an internal or external command, operable program or batch file.

powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

