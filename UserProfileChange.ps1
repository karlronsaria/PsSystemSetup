#Requires -RunAsAdministrator

function Get-WmiProperty {
    Param(
        [String]
        $From = "useraccount",

        [String]
        $Select = "fullname",

        [String]
        $Where
    )

    # link: https://www.xorrior.com/wmic-the-enterprise/
    # retrieved: 2021_11_16

    $command = if ($Where) {
        "wmic $From where `"$Where`" get $Select"
    } else {
        "wmic $From get $Select"
    }

    Write-Verbose "Query: $command"
    $result = iex -Command $command

    $result = $result | ? {
        -not [String]::IsNullOrWhiteSpace($_) -and $_ -notmatch "^\s*$Select\s*$"
    }

    $result = $result | % { $_.Trim() }
    return $result
}

function Set-UserProfileName {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [String]
        $Name,

        [String]
        $Value,

        [Switch]
        $Force
    )

    <# Example
        $Name = "Karl Ronsaria"
        $Value = "karlr"
    #>

    $ConfirmPreference = if ($PsBoundParameters.ContainsKey('Confirm')) {
        $PsBoundParameters['Confirm']
    } else {
        # $PsCmdlet.SessionState.PsVariable.GetValue('ConfirmPreference')
        $false
    }

    $WhatIfPreference = if ($PSBoundParameters.ContainsKey('WhatIf')) {
        $PsBoundParameters['WhatIf']
    } else {
        # $PsCmdlet.SessionState.PsVariable.GetValue('WhatIfPreference')
        $false
    }

    $propertyPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

    $sid = Get-WmiProperty `
        -From "useraccount" `
        -Select "sid" `
        -Where "fullname = '$Name'"

    Write-Verbose "SID: $sid"

    $oldUserDirPath = (Get-ItemProperty `
        -Path "$propertyPath\$sid" `
        -Name "ProfileImagePath" `
    ).ProfileImagePath

    $newUserDirPath = "C:\Users\$Value"

    Rename-Item `
        -Path "$oldUserDirPath" `
        -NewName "$newUserDirPath" `
        -Force:$Force `
        -WhatIf:$WhatIfPreference `
        -Confirm:$ConfirmPreference

    Set-ItemProperty `
        -Path "$propertyPath\$sid" `
        -Name "ProfileImagePath" `
        -Value "$newUserDirPath" `
        -Force:$Force `
        -WhatIf:$WhatIfPreference `
        -Confirm:$ConfirmPreference
}

<#
    .DESCRIPTION
        External
    .LINK
        Link: https://superuser.com/questions/1336012/access-to-the-path-is-denied-powershell-rename-item-script
    Retrieved: 2021_11_16
#>
function Set-SePrivilege {
    Param(
        ## The privilege to adjust. This set is taken from
        ## http://msdn.microsoft.com/en-us/library/bb530716(VS.85).aspx
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
            "SeUndockPrivilege", "SeUnsolicitedInputPrivilege")]
        [String]
        $Privilege,

        $ProcessId = $pid,

        [Switch] $Disable
    )

    $definition = @'
using System;
using System.Runtime.InteropServices;
public class AdjPriv
{

[DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);

[DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);

[DllImport("advapi32.dll", SetLastError = true)]
internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);

[StructLayout(LayoutKind.Sequential, Pack = 1)]
internal struct TokPriv1Luid
{
public int Count;
public long Luid;
public int Attr;
}

internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
internal const int TOKEN_QUERY = 0x00000008;
internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;

public static bool EnablePrivilege(long processHandle, string privilege, bool disable)
{
bool retVal;
TokPriv1Luid tp;
IntPtr hproc = new IntPtr(processHandle);
IntPtr htok = IntPtr.Zero;
retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
tp.Count = 1;
tp.Luid = 0;
if(disable)
{
tp.Attr = SE_PRIVILEGE_DISABLED;
}
else
{
tp.Attr = SE_PRIVILEGE_ENABLED;
}
retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
return retVal;
}
}
'@

    $processHandle = (Get-Process -id $ProcessId).Handle
    try { Add-Type $definition } catch {}
    [AdjPriv]::EnablePrivilege($processHandle, $Privilege, $Disable)
}

<#
    .DESCRIPTION
        External
    .LINK
        Link: https://superuser.com/questions/1336012/access-to-the-path-is-denied-powershell-rename-item-script
    Retrieved: 2021_11_16
#>
function Invoke-ClaimAdminOwnership {
    Param(
        [String]
        $Path
    )

    $acl = Get-Acl $Path
    $acl.SetOwner([System.Security.Principal.NTAccount]::new('Administrators'))
    $rule = [System.Security.AccessControl.FileSystemAccessRule]::new('Administrators', 'FullControl', 'None', 'None', 'Allow')
    $acl.AddAccessRule($rule)
    Set-Acl $Path $acl
}

