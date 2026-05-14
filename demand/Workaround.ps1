#Requires -Version 3 -RunAsAdministrator

<#
.DESCRIPTION
Tags: alert, privacy, consumeraction

Windows 11 (win11) caught storing quiet screenshots.
Use this command to remove and block Microsoft spyware.

.LINK
* Windows 11 is Hiding Your Personal Data in THIS Folder
  - Url: <https://www.youtube.com/watch?v=x8GA1GnEl3o>
  - Retrieved: 2025-11-06
#>
function Clear-QuietCapture {
    [CmdletBinding()]
    Param(
        [switch]
        $SetInRegistry
    )

    $itemPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ScreenClipBlock"
    $itemName = "BlockScreenClip"
    $itemType = 'DWord'
    $itemValue = 1

    $item = Get-ItemProperty `
        -Path $itemPath |
        ForEach-Object $itemName

    if ($item -eq $itemValue) {
        if ($SetInRegistry) {
            "SetInRegistry: Quiet screen capture is already blocked on your device."
        }
    }
    else {
        if ($SetInRegistry) {
            New-ItemProperty `
                -Path $itemPath `
                -Name $itemName `
                -PropertyType $itemType `
                -Value $itemValue
        }
        else {
            $cmdletName = Get-PSCallStack |
                Select-Object -ExpandProperty FunctionName -Skip 1 -First 1

            "Quiet screen capture is not blocked on your device."
            "Consider disabling it indefinitely with"
            ""
            "    $($PsStyle.Foreground.BrightYellow)$cmdletName -SetInRegistry$($PsStyle.Reset)"
            ""
        }
    }

    Get-ChildItem `
        -Path "$env:LOCALAPPDATA\Packages" `
        -Recurse `
        -Include *.dat, *ScreenClip `
        -ErrorAction SilentlyContinue |
    Remove-Item `
        -Force `
        -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
Permanantly and forcefully removes Microsoft Edge, and attempts to make auto-reinstall difficult for the next update of Windows.

.DESCRIPTION
Tags: alert, privacy, consumeraction, debloat

Permanantly and forcefully removes Microsoft Edge, and attempts to make auto-reinstall difficult for the next update of Windows. Be prepared to call this script whenever Windows updates.

.LINK
* motive
  - Url: <https://www.youtube.com/watch?v=w8EGomuEX8>
  - Retrieved: 2024-02-02

.LINK
* howto uninstall, prevent reinstall
  - Url: <https://www.tomsguide.com/how-to/how-to-uninstall-microsoft-edge>
  - Retrieved: 2024-02-02

.LINK
* howto remove AppX package
  - Url: <https://www.process.st/how-to/uninstall-microsoft-edge/>
  - Retrieved: 2024-02-02
#>
function Uninstall-MsEdge {
    # *********************
    # * --- Uninstall --- *
    # *********************

    $app_path = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\*\Installer\setup.exe"
    $app_args = "setup.exe --uninstall --system-level --verbose-logging --force-uninstall"

    Get-ChildItem $app_path -Recurse |
    ForEach-Object {
        Invoke-Expression "$app_path $app_args"
    }

    # ********************************
    # * --- Discourage Reinstall --- *
    # ********************************

    $reg_path = "HKLM:\SOFTWARE\Microsoft\EdgeUpdate"
    $reg_name = "DoNotUpdateToEdgeWithChromium"
    $reg_type = 'REG_DWORD'

    if (-not (Test-Path $reg_path)) {
        New-Item `
            -Path $reg_path `
            -Force
    }

    New-ItemProperty `
        -Path $reg_path `
        -Name $reg_name `
        -PropertyType $reg_type `
        -Value 1 `
        -Force

    # *******************************
    # * --- Remove AppX Package --- *
    # *******************************

    Get-AppXPackage `
        -Name "*MicrosoftEdge*" `
        -AllUsers |
    Remove-AppXPackage `
        -Force
}

<#
.DESCRIPTION
Tags: alert, privacy, debloat

.LINK
* howto: uninstall OneDrive
  - Url: <http://lifehacker.com/how-to-completely-uninstall-onedrive-in-windows-10-1725363532>
  - Retrieved: 2021-11-25
#>
function Uninstall-OneDrive {
    [CmdletBinding()]
    Param()

    taskkill /f /im OneDrive.exe
    C:\Windows\SysWOW64\OneDriveSetup.exe /uninstall
}

<#
.SYNOPSIS
Part of a two-step process of improving PowerShell startup time.
Optimize PowerShell startup by building Global Assemblies Cache (GAC).

.DESCRIPTION
Tags: GAC, powershell

Part of a two-step process of improving PowerShell startup time.
Optimize PowerShell startup by building Global Assemblies Cache (GAC).

.LINK
* howto
  - Url: <https://www.andrewcbancroft.com/2015/12/16/using-powershell-to-install-a-dll-into-the-gac/>
  - Retrieved: 2021-11-23
#>
function Update-PowerShellGac {
    [CmdletBinding()]
    Param()

    $items = [AppDomain]::CurrentDomain.GetAssemblies() |
        Where-Object { -not [String]::IsNullOrWhiteSpace($_.Location) } |
        Sort-Object { Split-Path $_.Location -Leaf }

    $assembly = "System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a"
    Write-Verbose "Updating Global Assembly Cache..."
    [System.Reflection.Assembly]::Load($assembly)
    $publish = New-Object System.EnterpriseServices.Internal.Publish

    foreach ($item in $items) {
        Write-Output $item
        $publish.GacInstall($item)
    }
}

<#
.SYNOPSIS
Part of a two-step process of improving PowerShell startup time.
Optimize PowerShell startup by reducing JIT compile time with "ngen.exe"

.DESCRIPTION
Tags: GAC, powershell

Part of a two-step process of improving PowerShell startup time.
Optimize PowerShell startup by reducing JIT compile time with "ngen.exe".
Script requires administrative permissions.

###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  OptimizePowerShellStartup.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Optimize PowerShell startup by reduce JIT compile time with ngen.exe
# Repository   :  https://github.com/BornToBeRoot/PowerShell
###############################################################################################################

.LINK
* main repo
  - Url: <https://github.com/BornToBeRoot/PowerShell/blob/master/Documentation/Script/OptimizePowerShellStartup.README.md>
  - Retrieved: 2025-02-05
#>
function Update-PowerShellNgen {
    Process {
        $is_admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
            IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

        # Restart script/console as admin with parameters
        if (-not $is_admin) {
            Start-Process `
                PowerShell.exe `
                -Verb RunAs `
                -ArgumentList "& '$($MyInvocation.MyCommand.Definition)'"

            return
        }

        # Set ngen path
        $ngen_path = Join-Path -Path $env:windir -ChildPath "Microsoft.NET"

        $child_path = if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
            'Framework64'
        }
        else {
            'Framework'
        }

        $ngen_path = Join-Path -Path $ngen_path -ChildPath "$child_path\ngen.exe"

        # Find latest ngen.exe
        $ngen_application_path = Get-ChildItem -Path $ngen_path -Filter "ngen.exe" -Recurse |
            Where-Object { $_.Length -gt 0 } |
            Select-Object -Last 1
            ForEach-Object Fullname

        # Get assemblies and call ngen.exe
        [System.AppDomain]::CurrentDomain.GetAssemblies() |
            ForEach-Object { & $ngen_application_path install $_.Location /nologo /verbose }
    }
}

function Rename-UserProfile {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Caption')]
    Param(
        [Parameter(ParameterSetName = 'Caption')]
        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )

            $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

            Get-WmiObject -Class Win32_UserAccount |
                ForEach-Object { $_.Caption } |
                ForEach-Object { $CompletionResults.Add($_) }

            return $CompletionResults
        })]
        [string]
        $Caption,

        [Parameter(ParameterSetName = 'FullName')]
        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )

            $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

            Get-WmiObject -Class Win32_UserAccount |
                ForEach-Object { $_.FullName } |
                Where-Object { $_ } |
                ForEach-Object { if ($_ -like "* *") { "`"$_`"" } else { $_ } } |
                ForEach-Object { $CompletionResults.Add($_) }

            return $CompletionResults
        })]
        [string]
        $FullName,

        [string]
        $NewName,

        [switch]
        $Force
    )

    <# Example
        $Name = "Karl Ronsaria"
        $NewName = "karlr"
    #>

    $propertyPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

    $sid = switch ($PsCmdlet.ParameterSetName) {
        'Caption' {
            Get-WmiObject -Class Win32_UserAccount |
                Where-Object { $_.Caption -eq $Caption } |
                ForEach-Object { $_.SID }
        }

        'FullName' {
            Get-WmiObject -Class Win32_UserAccount |
                Where-Object { $_.FullName -eq $FullName } |
                ForEach-Object { $_.SID }
        }
    }

    Write-Verbose "SID: $sid"

    $oldUserDirPath = (Get-ItemProperty `
        -Path (Join-Path $propertyPath $sid) `
        -Name "ProfileImagePath" `
    ).ProfileImagePath

    $newUserDirPath = "C:\Users\$NewName"

    Rename-Item `
        -Path $oldUserDirPath `
        -NewName $newUserDirPath `
        -Force:$Force

    Set-ItemProperty `
        -Path (Join-Path $propertyPath $sid) `
        -Name ProfileImagePath `
        -Value $newUserDirPath `
        -Force:$Force
}

<#
.DESCRIPTION
Part of a two-step process of taking ownership of items on the hard drive that are otherwise blocked.

.LINK
* howto
  - Url: <https://superuser.com/questions/1336012/access-to-the-path-is-denied-powershell-rename-item-script>
  - Retrieved: 2021-11-16

.LINK
* list of privilege constants
  - url: <http://msdn.microsoft.com/en-us/library/bb530716(VS.85).aspx>
  - retrieved: 2026-04-26
#>
function Set-SePrivilege {
    Param(
        [ValidateSet(
            "SeAssignPrimaryTokenPrivilege", "SeAuditPrivilege", "SeBackupPrivilege",
            "SeChangeNotifyPrivilege", "SeCreateGlobalPrivilege", "SeCreatePagefilePrivilege",
            "SeCreatePermanentPrivilege", "SeCreateSymbolicLinkPrivilege", "SeCreateTokenPrivilege",
            "SeDebugPrivilege", "SeEnableDelegationPrivilege", "SeImpersonatePrivilege", "SeIncreaseBasePriorityPrivilege",
            "SeIncreaseQuotaPrivilege", "SeIncreaseWorkingSetPrivilege", "SeLoadDriverPrivilege",
            "SeLockMemoryPrivilege", "SeMachineAccountPrivilege", "SeManageVolumePrivilege",
            "SeProfileSingleProcessPrivilege", "SeRelabelPrivilege", "SeRemoteShutdownPrivilege",
            "SeRestorePrivilege", "SeSecurityPrivilege", "SeShutdownPrivilege", "SeSyncAgentPrivilege",
            "SeSystemEnvironmentPrivilege", "SeSystemProfilePrivilege", "SeSystemtimePrivilege",
            "SeTakeOwnershipPrivilege", "SeTcbPrivilege", "SeTimeZonePrivilege", "SeTrustedCredManAccessPrivilege",
            "SeUndockPrivilege", "SeUnsolicitedInputPrivilege"
        )]
        [string]
        $Privilege = 'SeTakeOwnershipPrivilege',

        $ProcessId = $pid,

        [switch] $Disable
    )

    $definition = @'
using System;
using System.Runtime.InteropServices;
public class Privileges {
    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
    ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);

    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);

    [DllImport("advapi32.dll", SetLastError = true)]
    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal struct TokPriv1Luid {
        public int Count;
        public long Luid;
        public int Attr;
    }

    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
    internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
    internal const int TOKEN_QUERY = 0x00000008;
    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;

    public static bool EnablePrivilege(long processHandle, string privilege, bool disable) {
        bool retVal;
        TokPriv1Luid tp;
        IntPtr hproc = new IntPtr(processHandle);
        IntPtr htok = IntPtr.Zero;
        retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
        tp.Count = 1;
        tp.Luid = 0;

        tp.Attr = disable
            ? SE_PRIVILEGE_DISABLED
            : SE_PRIVILEGE_ENABLED;

        retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
        retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
        return retVal;
    }
}
'@

    Add-Type $definition
    $processHandle = (Get-Process -id $ProcessId).Handle
    [Privileges]::EnablePrivilege($processHandle, $Privilege, $Disable.IsPresent)
}

<#
.DESCRIPTION
Part of a two-step process of taking ownership of items on the hard drive that are otherwise blocked.

.LINK
* howto
  - Url: <https://superuser.com/questions/1336012/access-to-the-path-is-denied-powershell-rename-item-script>
  - Retrieved: 2021-11-16
#>
function Set-Ownership {
    Param(
        [string]
        $Path
    )

    $acl = Get-Acl $Path
    $acl.SetOwner([System.Security.Principal.NTAccount]::new('Administrators'))
    $rule = [System.Security.AccessControl.FileSystemAccessRule]::new('Administrators', 'FullControl', 'None', 'None', 'Allow')
    $acl.AddAccessRule($rule)
    Set-Acl $Path $acl
}

<#
.DESCRIPTION
Tags: debloat

.LINK
* howto: delete windows 10 apps
  - Url: <https://thomas.vanhoutte.be/miniblog/delete-windows-10-apps/>
  - Retrieved: 2026-04-26

.LINK
* howto: debloat windows 10
  - Url: <https://github.com/W4RH4WK/Debloat-Windows-10>
  - Retrieved: 2026-04-26
#>
function Set-AppxPackage {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String[]]
        $Name,

        [ValidateSet('Add', 'Remove')]
        [String]
        $Action = 'Remove',

        [ValidateSet('Personal', 'Thin')]
        [String]
        $Preference = 'Personal'
    )

    Process {
        $packages = @()

        if ($Name) {
            $packages = $Name |
            ForEach-Object {
                Get-AppxPackage -AllUsers -Name $_ |
                    Select-Object Name, PackageFullName
            }
        }

        switch ($Action) {
            'Add' {
                $packages |
                    ForEach-Object { `
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
* question
  - Url: <https://superuser.com/questions/1246790/can-i-disable-windows-10-animations-with-a-batch-file>
  - Retrieved: 2022-02-22

.LINK
* user
  - Url: <https://superuser.com/users/380318/ben-n>
  - Retrieved: 2022-02-22
#>
function Set-ExplorerAnimation {
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

            Add-Type -TypeDefinition @"
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

