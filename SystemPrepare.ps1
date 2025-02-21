#Requires -RunAsAdministrator

<#
    .LINK
        Link:
            https://stackoverflow.com/questions/4491999/configure-windows-explorer-folder-options-through-powershell
        Retrieved:
            2021-11-18
#>
function Set-ExplorerPreference {
    [CmdletBinding(DefaultParameterSetName = 'ByString')]
    Param(
        [Parameter(ParameterSetName = 'ByString')]
        $Json,

        [Parameter(ParameterSetName = 'ByObject')]
        $InputObject,

        [Parameter(ParameterSetName = 'GetDefaultString')]
        $GetDefaults
    )

    $defaultsJson = @"
{
    "Start_SearchFiles":  2,
    "ServerAdminUI":  0,
    "Hidden":  1,
    "ShowCompColor":  1,
    "HideFileExt":  0,
    "DontPrettyPath":  0,
    "ShowInfoTip":  1,
    "HideIcons":  0,
    "MapNetDrvBtn":  0,
    "WebView":  1,
    "Filter":  0,
    "ShowSuperHidden":  0,
    "SeparateProcess":  0,
    "AutoCheckSelect":  1,
    "IconsOnly":  0,
    "ShowTypeOverlay":  1,
    "ShowStatusBar":  1,
    "StoreAppsOnTaskbar":  1,
    "ListviewAlphaSelect":  1,
    "ListviewShadow":  1,
    "TaskbarAnimations":  1,
    "ShowCortanaButton":  1,
    "ReindexedProfile":  1,
    "StartMenuInit":  13,
    "StartMigratedBrowserPin":  1,
    "HideDrivesWithNoMedia":  0
}
"@

    if ($GetDefaults) {
        return $defaultsJson
    }

    $path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\'

    if ($PsCmdlet.ParameterSetName -eq 'ByString') {
        if ([String]::IsNullOrWhiteSpace($Json)) {
            $Json = $defaultsJson
        }

        $InputObject = ConvertFrom-Json $Json
    }

    $properties = $InputObject | Get-Member -MemberType NoteProperty

    foreach ($property in $properties) {
        $name = $property.Name
        $value = $InputObject.$name
        $oldValue = (Get-ItemProperty -Path $path -Name $name).$name

        if ($null -ne (Compare-Object ($value) ($oldValue))) {
            Write-Verbose "Setting option $name from $oldValue to $value"
        }

        Set-ItemProperty -Path $path -Name $name -Value $value -Force
    }

    # link: https://stackoverflow.com/questions/4491999/configure-windows-explorer-folder-options-through-powershell
    # retrieved: 2021-11-18
    Stop-Process -Name explorer -Force
    Start-Sleep -Seconds 1

    if ($null -eq (Get-Process | ? ProcessName -eq 'explorer')) {
        Start-Process explorer
    }

    $result = [PsCustomObject]@{
        Success = $true;
        Path = $path;
        Failures = @();
    }

    foreach ($property in $properties) {
        $name = $property.Name
        $value = $InputObject.$name
        $newValue = (Get-ItemProperty -Path $path -Name $name).$name
        $success = $null -eq (Compare-Object ($value) ($newValue))

        if (-not $success) {
            $result.Failures += [PsCustomObject]@{
                Name = $name;
                Actual = $newValue
                Expected = $value;
            }
        }

        $result.Success = $result.Success -and $success
    }

    return $result
}

function Set-UserAccountControl {
    [CmdletBinding(DefaultParameterSetName = 'On')]
    Param(
        [Parameter(ParameterSetName = 'On')]
        [Switch]
        $On,

        [Parameter(ParameterSetName = 'Off')]
        [Switch]
        $Off
    )

    $path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    $version = (Get-CimInstance 'Win32_OperatingSystem').Version.Split('.')[0]

    if ($version -eq 10) {
        $name = 'ConsentPromptBehaviorAdmin'
    } elseif ($version -eq 6) {
        $minor = $version.split('.')[1]

        if ($minor -eq 1 -or $minor -eq 0) {
            $name = 'EnableLUA'
        } else {
            $name = 'ConsentPromptBehaviorAdmin'
        }
    } elseif ($version -eq 5) {
        $name = 'EnableLUA'
    } else {
        $name = 'ConsentPromptBehaviorAdmin'
    }

    $value = switch ($PsCmdlet.ParameterSetName) {
        'On' { '1' }
        'Off' { '0' }
    }

    Set-ItemProperty -Path $path -Name $name -Value $value
}

<#
    .LINK
        https://thomas.vanhoutte.be/miniblog/delete-windows-10-apps/

    .LINK
        https://github.com/W4RH4WK/Debloat-Windows-10
#>
function Set-AppxPackage {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String[]]
        $Name,

        [ValidateSet('Add', 'Remove')]
        [String]
        $Action,

        [ValidateSet('Personal', 'Thin')]
        [String]
        $Preference = 'Personal'
    )

    Process {
        $packages = @()

        if ($Name) {
            $packages = $Name | % {
                Get-AppxPackage -AllUsers -Name $_ | select Name, PackageFullName
            }
        }

        switch ($Action) {
            'Add' {
                $packages | % { `
                    Add-AppxPackage `
                        -DisableDevelopmentMode `
                        -Register "$($_.InstallLocation)\AppXManifest.xml"
                }
            }

            'Remove' {
                $packages | Remove-AppxPackage
            }

            default {
                Write-Output $packages
            }
        }
    }

    End {
        if ($Action -eq 'Remove' -and -not $Name) {
            $patterns = ((cat $PsScriptRoot\res\appx.json | ConvertFrom-Json `
                ).Clients `
                | ? Name -eq $Preference `
                ).Patterns

            Write-Verbose "`r`nRemoving default packages...`r`n"

            $patterns | ? { -not [String]::IsNullOrWhiteSpace($_) } | % {
                Get-AppxPackage -Name $_ | Remove-AppxPackage
            }
        }
    }
}

function Enable-WindowsHyperVFeature {
    [CmdletBinding()]
    Param()

    Get-WindowsOptionalFeature -Online `
        | ? FeatureName -like "*yper-v*" `
        | Enable-WindowsOptionalFeature -Online -All
}

<#
    .LINK
        Link: https://superuser.com/questions/1246790/can-i-disable-windows-10-animations-with-a-batch-file
        Link: https://superuser.com/users/380318/ben-n
        Retrieved: 2022-02-22
#>
function Set-ExplorerAnimationPreference {
    [CmdletBinding(DefaultParameterSetName = "ByInputObject")]
    Param(
        [Parameter(ParameterSetName = "ByInputObject")]
        [Bool]
        $InputObject,

        [Parameter(ParameterSetName = "BySwitchEnable")]
        [Switch]
        $Enable,

        [Parameter(ParameterSetName = "BySwitchDisable")]
        [Switch]
        $Disable
    )

    $preference = switch ($PsCmdlet.ParameterSetName) {
        "ByInputObject" {
            $InputObject
        }

        "BySwitchEnable" {
            $true
        }

        "BySwitchDisable" {
            $false
        }
    }

    # link: https://stackoverflow.com/questions/3369662/can-you-remove-an-add-ed-type-in-powershell-again
    # link: https://stackoverflow.com/users/221631/start-automating
    # link: https://stackoverflow.com/users/645511/katie-kilian
    # retrieved: 2022-02-22

    $job = Start-Job `
        -ArgumentList $preference `
        -ScriptBlock {
            Param([Bool] $Preference)

            Add-Type -TypeDefinition `
@"
    using System;
    using System.Runtime.InteropServices;
    [StructLayout(LayoutKind.Sequential)] public struct ANIMATIONINFO {
        public uint cbSize;
        public bool iMinAnimate;
    }
    public class PInvoke { 
        [DllImport("user32.dll")] public static extern bool SystemParametersInfoW(uint uiAction, uint uiParam, ref ANIMATIONINFO pvParam, uint fWinIni);
    }
"@

            $animInfo = New-Object ANIMATIONINFO
            $animInfo.cbSize = 8
            $animInfo.iMinAnimate = $Preference

            return [PsCustomObject]@{
                EnableAnimations = $animInfo.iMinAnimate;
                Success = [PInvoke]::SystemParametersInfoW(0x49, 0, [ref]$animInfo, 3);
            }
        }

    Wait-Job $job | Out-Null
    return Receive-Job $job
}

<#
    .TODO
        Link:
            https://answers.microsoft.com/en-us/bing/forum/bing_apps-bing_install-bing_appdev_win8/remove-news-feed-from-task-bar/6ec30157-33a8-4908-9363-a25e74bf0677?auth=1
        Retrieved:
            2022-02-22
#>
function Set-WindowsFeedPreference {
    [CmdletBinding(DefaultParameterSetName = "ByInputObject")]
    Param(
        [Parameter(ParameterSetName = "ByInputObject")]
        [Bool]
        $InputObject,

        [Parameter(ParameterSetName = "BySwitchEnable")]
        [Switch]
        $Enable,

        [Parameter(ParameterSetName = "BySwitchDisable")]
        [Switch]
        $Disable
    )

    $params = @{
        Value = switch ($PsCmdlet.ParameterSetName) {
            "ByInputObject" {
                switch ($InputObject) {
                    $true { "1" }
                    $false { "0" }
                }
            }
            "BySwitchEnable" { "1" }
            "BySwitchDisable" { "0" }
        };
        Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds";
        Name = "EnableFeeds";
        PropertyType = "DWORD";
        Force = $true;
    }

    if (!(Test-Path $params.Path)) {
        New-Item -Path $params.Path -Force:$params.Force | Out-Null
    }

    New-ItemProperty @params | Out-Null
}

<#
    .LINK
        Link:
            http://lifehacker.com/how-to-completely-uninstall-onedrive-in-windows-10-1725363532
        Retrieved:
            2021-11-25
#>
function Uninstall-OneDrive {
    [CmdletBinding()]
    Param()

    taskkill /f /im OneDrive.exe
    C:\Windows\SysWOW64\OneDriveSetup.exe /uninstall
}

function Start-SystemPrepare {
    [CmdletBinding()]
    Param(
        [ValidateSet('Allow', 'Deny')]
        [String]
        $GeoLocation = 'Allow',

        [ValidateSet('Allow', 'Deny')]
        [String]
        $AutoTimeSync = 'Allow',

        [ValidateSet('Allow', 'Deny')]
        [String]
        $AutoSetTimeZone = 'Allow',

        [ValidateSet('Allow', 'Deny')]
        [String]
        $RemoteDesktop = 'Allow',

        [ValidateSet('Allow', 'Deny')]
        [String]
        $UserAccountControl = 'Deny',

        [ValidateSet('Allow', 'Deny')]
        [String]
        $NetworkDiscovery = 'Allow',

        [ValidateSet('Allow', 'Deny')]
        [String]
        $FileSharing = 'Allow',

        [ValidateSet('Allow', 'Deny')]
        [String]
        $ExplorerAnimations = 'Deny',

        [ValidateSet('Allow', 'Deny')]
        [String]
        $WindowsFeed = 'Deny',

        [ValidateSet('Allow', 'Deny')]
        [String]
        $UpdatePsHelp = 'Allow',

        [ValidateSet('Personal', 'Thin')]
        [String]
        $AppxDebloatingPreference = 'Personal'
    )

    # link: https://www.top-password.com/blog/enable-or-disable-set-time-zone-automatically-in-windows-10/
    # retrieved: 2021-11-18

    Write-Verbose "Device geolocation services: $GeoLocation"
    $path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'
    Set-ItemProperty -Path $path -Name Value -Value $GeoLocation

    $value = switch ($AutoTimeSync) {
        'Allow' { 'NTP' }
        'Deny' { 'NoSync' }
    }

    Write-Verbose "Automatic time synchronization: $AutoTimeSync"
    $path = 'HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters'
    Set-ItemProperty -Path $path -Name Type -Value $value

    $value = switch ($AutoSetTimeZone) {
        'Allow' { 3 }
        'Deny' { 4 }
    }

    Write-Verbose "Automatic time zone update: $AutoSetTimeZone"
    $path = 'HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate'
    Set-ItemProperty -Path $path -Name Start -Value $value

    $value = switch ($RemoteDesktop) {
        'Allow' { 0 }
        'Deny' { 1 }
    }

    Write-Verbose "Remote Desktop connections to this device: $RemoteDesktop"
    $path = 'HKLM:\System\CurrentControlSet\Control\Terminal Server'
    Set-ItemProperty -Path $path -Name fDenyTSConnections -Value $value

    $value = switch ($RemoteDesktop) {
        'Allow' { 'True' }
        'Deny' { 'False' }
    }

    # link: https://vmarena.com/how-to-enable-remote-desktop-rdp-remotely-using-powershell/
    # retrieved: 2021-11-18

    Get-NetFirewallRule -DisplayGroup 'Remote Desktop' `
        | Set-NetFirewallRule -Profile 'Any' -Enabled $value

    Write-Verbose "Setting Explorer options..."
    $result = Set-ExplorerPreference
    $success = $null -ne $result -and $result.Success

    if (-not $success) {
        $result | select Success, Path
        "`r`nFailures:`r`n"
        $result.Failures | Format-Table
    }

    $resultMessage = if ($null -ne $result -and $result.Success) {
        "Success"
    } else {
        "Fail"
    }

    Write-Verbose "Setting Explorer options: $resultMessage"
    Write-Verbose "User Account Control: $UserAccountControl"

    switch ($UserAccountControl) {
        "Allow" {
            Set-UserAccountControl -On
        }

        "Deny" {
            Set-UserAccountControl -Off
        }
    }

    Write-Verbose "Network Discovery: $NetworkDiscovery"

    $profiles = 'Any' # 'Private, Domain'

    $value = switch ($NetworkDiscovery) {
        'Allow' { 'True' }
        'Deny' { 'False' }
    }

    # link: https://thegeekpage.com/how-to-enable-and-disable-network-discovery-in-windows-10/
    # retrieved: 2021-11-18
    Get-NetFirewallRule -DisplayGroup 'Network Discovery' `
        | Set-NetFirewallRule -Profile $profiles -Enabled $value

    Write-Verbose "File-sharing: $FileSharing"

    $value = switch ($FileSharing) {
        'Allow' { 'True' }
        'Deny' { 'False' }
    }

    # link: https://www.c-sharpcorner.com/article/how-to-enable-or-disable-file-and-printer-sharing-in-windows-102/
    # retrieved: 2021-11-18
    Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing' `
        | Set-NetFirewallRule -Profile $profiles -Enabled $value

    Write-Verbose "Explorer animations: $ExplorerAnimations"

    $value = switch ($ExplorerAnimations) {
        'Allow' { $true }
        'Deny' { $false }
    }

    Set-ExplorerAnimationPreference -InputObject $value

    Write-Verbose "Windows Feed: $WindowsFeed"

    $value = switch ($WindowsFeed) {
        'Allow' { $true }
        'Deny' { $false }
    }

    Set-WindowsFeedPreference -InputObject $value

    Write-Verbose "Removing Appx packages..."

    Set-AppxPackage -Action Remove -Preference $AppxDebloatingPreference

    Write-Verbose "Update PowerShell Help Uri: $UpdatePsHelp"

    $value = switch ($UpdateHelp) {
        'Allow' {
            # link: https://answers.microsoft.com/en-us/windows/forum/all/updateing-powershell-user-help-files/07afd880-c543-4e56-9446-1e9eb509003d
            # retrieved: 2021-11-25
            Update-Help -Force -ErrorAction SilentlyContinue
        }
    }
}

<#
    .LINK
        Link: https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-pscustomobject?view=powershell-7.2
        Retrieved: 2021-11-21
#>
function ConvertTo-Hashtable {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [PsCustomObject]
        $InputObject
    )

    # I really feel like I shouldn't have to do this.

    Process {
        $table = @{}

        foreach ($property in $InputObject.PsObject.Properties.Name) {
            $table[$property] = $InputObject.$property
        }

        return $table
    }
}

function Invoke-FromArgumentFile {
    [CmdletBinding()]
    Param(
        [String]
        $FilePath,

        [Parameter(ParameterSetName = "SingleCommand")]
        [String]
        $CommandName,

        [Parameter(ParameterSetName = "AllCommands")]
        [Switch]
        $All
    )

    function Get-Property {
        Param(
            [PsCustomObject]
            $InputObject,

            [String]
            $PropertyName
        )

        $hasProperty = ($InputObject | GM | ? MemberType -eq NoteProperty).Name -contains $PropertyName

        $value = if ($hasProperty) {
            $InputObject.$PropertyName
        } else {
            $null
        }

        return $value
    }

    function Invoke-FromObject {
        Param(
            [PsCustomObject]
            $InputObject
        )

        $arguments = $InputObject.ArgumentList `
            | ConvertTo-Hashtable

        $startMsg = Get-Property `
            -InputObject $InputObject `
            -PropertyName StartMessage

        if ($null -ne $startMsg) {
            Write-Output $startMsg
        }

        iex -Command "$($InputObject.CommandName) @arguments"
    }

    $list = cat $FilePath | ConvertFrom-Json

    switch ($PsCmdlet.ParameterSetName) {
        "SingleCommand" {
            $cmd = $list.Children | ? CommandName -eq $CommandName
            Invoke-FromObject -InputObject $cmd
        }

        "AllCommands" {
            foreach ($cmd in $list.Children) {
                Invoke-FromObject -InputObject $cmd
            }
        }
    }
}

