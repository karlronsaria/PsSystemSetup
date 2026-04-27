#Requires -RunAsAdministrator

. "$PsScriptRoot/Firewall.ps1"

<#
.LINK
Url: <https://thomas.vanhoutte.be/miniblog/delete-windows-10-apps/>
Retrieved: 2026-04-26

.LINK
Url: <https://github.com/W4RH4WK/Debloat-Windows-10>
Retrieved: 2026-04-26
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
            Write-Verbose "`r`nRemoving default packages...`r`n"

            "$PsScriptRoot/../res/appx.json" |
                Get-Item |
                Get-Content |
                ConvertFrom-Json |
                ForEach-Object Clients |
                Where-Object Name -eq $Preference |
                ForEach-Object Patterns |
                Where-Object { -not [String]::IsNullOrWhiteSpace($_) } |
                ForEach-Object { Get-AppxPackage -Name $_ | Remove-AppxPackage }
        }
    }
}

<#
.LINK
Url: <https://superuser.com/questions/1246790/can-i-disable-windows-10-animations-with-a-batch-file>
Retrieved: 2022-02-22

.LINK
Url: <https://superuser.com/users/380318/ben-n>
Retrieved: 2022-02-22
#>
function Set-ExplorerAnimationPreference {
    Param(
        [Bool]
        $Value
    )

    # link
    # - url
    #   - <https://stackoverflow.com/questions/3369662/can-you-remove-an-add-ed-type-in-powershell-again>
    #   - <https://stackoverflow.com/users/221631/start-automating>
    #   - <https://stackoverflow.com/users/645511/katie-kilian>
    # - retrieved: 2022-02-22

    $job = Start-Job `
        -ArgumentList $Value `
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
.LINK
Url: <http://lifehacker.com/how-to-completely-uninstall-onedrive-in-windows-10-1725363532>
Retrieved: 2021-11-25
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
        $RemoteDesktop = 'Allow',

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
        $UpdatePsHelp = 'Allow',

        [ValidateSet('Personal', 'Thin')]
        [String]
        $AppxDebloatingPreference = 'Personal'
    )

    Write-Verbose "Uninstalling OneDrive"
    Uninstall-OneDrive

    Write-Verbose "Remote Desktop: $RemoteDesktop"
    Set-FeatureRemoteDesktop -Value $($RemoteDesktop -eq 'Allow')

    Write-Verbose "Network Discovery: $NetworkDiscovery"
    Set-FeatureNetworkDiscovery -Value $($NetworkDiscovery -eq 'Allow')

    Write-Verbose "File-sharing: $FileSharing"
    Set-FeatureFileAndPrinterSharing -Value $($FileSharing -eq 'Allow')

    Write-Verbose "Explorer animations: $ExplorerAnimations"
    Set-ExplorerAnimationPreference -Value $($ExplorerAnimations -eq 'Allow')

    Write-Verbose "Removing Appx packages..."
    Set-AppxPackage -Action Remove -Preference $AppxDebloatingPreference

    Write-Verbose "Update PowerShell Help Uri: $UpdatePsHelp"

    $value = switch ($UpdateHelp) {
        'Allow' {
            # link
            # - <https://answers.microsoft.com/en-us/windows/forum/all/updateing-powershell-user-help-files/07afd880-c543-4e56-9446-1e9eb509003d>
            # - retrieved: 2021-11-25
            Update-Help -Force -ErrorAction SilentlyContinue
        }
    }
}

<#
.LINK
Url: <https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-pscustomobject?view=powershell-7.2>
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

        $arguments = $InputObject.ArgumentList |
            ConvertTo-Hashtable

        $startMsg = Get-Property `
            -InputObject $InputObject `
            -PropertyName StartMessage

        if ($null -ne $startMsg) {
            Write-Output $startMsg
        }

        Invoke-Expression -Command "$($InputObject.CommandName) @arguments"
    }

    $list = Get-Content $FilePath | ConvertFrom-Json

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

