@echo off
reg add HKLM\Software\Microsoft\Windows\CurrentVersion\OOBE /v SkipMachineOOBE /t REG_DWORD /d 1 /f

:: link: elevenforum.com
:: - url: <https://www.elevenforum.com/t/user-oobe-broker-always-running-in-background-how-to-disable.8275/>
:: - retrieved: 2026-04-24
takeown /s %computername% /u %username% /f "%WINDIR%\System32\oobe\UserOOBEBroker.exe"
icacls "%WINDIR%\System32\oobe\UserOOBEBroker.exe" /inheritance:r /grant:r %username%:F
taskkill /im UserOOBEBroker.exe /f
del "%WINDIR%\System32\oobe\UserOOBEBroker.exe" /s /f /q

:: link: ideasawakened.com
:: - url: <https://ideasawakened.com/post/microsoft-windows-11-local-account-oobe-bypassnro-fails>
:: - retrieved: 2026-04-24
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f
echo Please restart your computer

