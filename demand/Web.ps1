<#
.DESCRIPTION
Tags: alert, privacy, debloat, zoicware, copilot, ai, removeai

.LINK
* zoicware - RemoveWindowsAI
  - Url: <https://github.com/zoicware/RemoveWindowsAI>
  - Retrieved: 2026-05-06
#>
function Start-WebZoicwareRemoveWindowsAi {
    & ([scriptblock]::Create((Invoke-RestMethod "https://raw.githubusercontent.com/zoicware/RemoveWindowsAI/main/RemoveWindowsAi.ps1"))) -nonInteractive -AllOptions
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
    "${env:SystemRoot}/servicing/Packages" |
    Get-ChildItem `
        "Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum",
        "Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum" |
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

