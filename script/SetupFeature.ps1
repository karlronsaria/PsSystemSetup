function Set-FeatureNetworkDiscovery {
    Param(
        # [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetSecurity.Enabled]
        [ValidateSet('True', 'False')]
        [string]
        $Enabled,

        [ValidateSet('Any', 'Domain', 'Private')]
        [string[]]
        $FirewallProfile = @('Any')
    )

    # link
    # - <https://thegeekpage.com/how-to-enable-and-disable-network-discovery-in-windows-10/>
    # - retrieved: 2021-11-18
    Get-NetFirewallRule -DisplayGroup 'Network Discovery' |
        Set-NetFirewallRule -Profile $FirewallProfile -Enabled $Enabled
}

function Set-FeatureFileAndPrinterSharing {
    Param(
        # [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetSecurity.Enabled]
        [ValidateSet('True', 'False')]
        [string]
        $Enabled,

        [ValidateSet('Any', 'Domain', 'Private')]
        [string[]]
        $FirewallProfile = @('Any')
    )

    # link
    # - url: <https://www.c-sharpcorner.com/article/how-to-enable-or-disable-file-and-printer-sharing-in-windows-102/>
    # - retrieved: 2021-11-18
    Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing' `
        | Set-NetFirewallRule -Profile $FirewallProfile -Enabled $Enabled
}

<#
.DESCRIPTION
Tags: remotedesktop rdp terminalservice tsconnect

.LINK
* howto
  - Url: <https://vmarena.com/how-to-enable-remote-desktop-rdp-remotely-using-powershell/>
  - Retrieved: 2021-11-18
#>
function Set-FeatureRemoteDesktop {
    Param(
        # [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetSecurity.Enabled]
        [ValidateSet('True', 'False')]
        [string]
        $Enabled,

        [ValidateSet('Any', 'Domain', 'Private')]
        [string[]]
        $FirewallProfile = @('Any')
    )

    $deny = if ($Value -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetSecurity.Enabled]::True) { 0 } else { 1 }
    Write-Verbose "Remote Desktop connections to this device: $RemoteDesktop"
    $path = 'HKLM:\System\CurrentControlSet\Control\Terminal Server'
    Set-ItemProperty -Path $path -Name fDenyTSConnections -Value $deny

    Get-NetFirewallRule -DisplayGroup 'Remote Desktop' |
        Set-NetFirewallRule -Profile $FirewallProfile -Enabled $Enabled
}
