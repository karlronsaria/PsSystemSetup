@echo off

:: Windows 11 keeps a secret activity log. Here's how to stop it.
:: - tag: #privacy
:: - link: SysHack - I Found Windows 11’s Secret Activity Log — Here’s What’s Inside And How to Delete It
::   - url: <https://www.youtube.com/watch?v=vNZjuGONj2s>
::   - retrieved: 2025-11-07

taskkill /f /im CDPUserSvc.exe
taskkill /f /im RuntimeBroker.exe
taskkill /f /im explorer.exe

cd %LOCALAPPDATA%\ConnectedDevicesPlatform
del ActivitesCache.db
del ActivitesCache.db-shm
del ActivitesCache.db-wal

start explorer.exe

reg add "HKLM\Software\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f

echo Please restart the computer.

