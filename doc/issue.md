# issue

- [x] issue 2026-03-26-182735
  - where: demand/SystemSetupProfile/Get-...
  - solution

    ```powershell
    $driveEject = New-Object -ComObject Shell.Application
    $driveEject.Namespace(17).ParseName("$driveLetter`:\").InvokeVerb("Eject")
    ```

  - howto

    ```powershell
    Get-Volume -DriveLetter $driveLetter |
      ForEach-Object {
          $_ | Get-Partition | Get-Disk
      } |
      Set-Disk -IsOffline $true
    ```

  - actual

    ```text
    Set-Disk: Not Supported
    
    Extended information:
    Removable media cannot be set to offline.
    
    
    Activity ID: {705b985d-bcd0-0002-51c2-0071d0bcdc01}
    ```

- [x] issue 2026-03-23-030236
  - retrieved: 2022-08-02
  - description: after removing Photos app, cannot change default program for jpeg (\*.jpg) files
  - howto

    ```powershell
    Remove-AppxPackage -Name Microsoft.Windows.Photos
    ```

  - link
    - url: <https://learn.microsoft.com/en-us/answers/questions/4251953/widows-11-setting-default-program-for-jpg-files-is?forum=windows-all&referrer=answers>
    - retrieved: 2026-03-23

---

[← Go Back](../readme.md)

