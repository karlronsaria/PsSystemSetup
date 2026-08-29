<#
.DESCRIPTION
Tags: alert, privacy, debloat, zoicware, copilot, ai, removeai

.LINK
* zoicware - RemoveWindowsAI
  - Url: <https://github.com/zoicware/RemoveWindowsAI>
  - Retrieved: 2026-05-06
#>
function Start-WebZoicwareRemoveWindowsAi {
    Param(
        [int]
        $TimeoutSeconds = 10
    )

    $protection = Get-MpComputerStatus | ForEach-Object RealTimeProtectionEnabled
    Set-MpPreference -DisableRealtimeMonitoring $false

    $deadline = [datetime]::UtcNow + ($TimeoutSeconds * 1000)

    do {
        if (-not (Get-MpComputerStatus | ForEach-Object RealTimeProtectionEnabled)) {
            break
        }

        Start-Sleep -Milliseconds 500
    }
    while ([datetime]::UtcNow -lt $deadline)

    # Running the script with PowerShell 7 is no longer supported and it WILL cause issues.
    # To avoid this ensure you are running Windows PowerShell (5.1).
    powershell -Command '& ([scriptblock]::Create((Invoke-RestMethod "https://raw.githubusercontent.com/zoicware/RemoveWindowsAI/main/RemoveWindowsAi.ps1"))) -nonInteractive -AllOptions'

    Set-MpPreference -DisableRealtimeMonitoring $protection
}

<#
.DESCRIPTION
Tags: gpedit

.LINK
* howto: Re-enable Group Policy Editor
  - <https://drive.google.com/file/d/1H3WiXQpaYOQ7rMZGh_sEfDue-KUhomDW/view>
  - retrieved: 2025-07-24
 
.LINK
* howto: Re-enable Group Policy Editor
  - <https://drive.usercontent.google.com/download?id=1H3WiXQpaYOQ7rMZGh_sEfDue-KUhomDW&export=download&authuser=0>
  - retrieved: 2025-07-24
#>
function Add-WebGroupPolicyEditor {
    "Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum",
    "Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum" |
    ForEach-Object {
        Get-ChildItem "${env:SystemRoot}/servicing/Packages/$_"
    } |
    ForEach-Object {
        dism /online /norestart /add-package:"$($_.FullName)"
    }
}

<#
.DESCRIPTION
Tags: hyperv
#>
function Set-WebFeatureWindowsHyperV {
    [CmdletBinding()]
    Param(
        [bool]
        $Value
    )

    if ($Value) {
        Get-WindowsOptionalFeature -Online |
            Where-Object FeatureName -like "*yper-v*" |
            Enable-WindowsOptionalFeature -Online -All
    }
    else {
        Get-WindowsOptionalFeature -Online |
            Where-Object FeatureName -like "*yper-v*" |
            Disable-WindowsOptionalFeature -Online -All
    }
}

