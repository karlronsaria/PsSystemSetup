#Requires -RunAsAdministrator

. "$PsScriptRoot/Feature.ps1"
. "$PsScriptRoot/Clean.ps1"

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
    Set-ExplorerAnimation -Value $($ExplorerAnimations -eq 'Allow')

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
* pscustomobjects cannot be splatted
  - Url: <https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-pscustomobject?view=powershell-7.2>
  - Retrieved: 2021-11-21
#>
function ConvertTo-Hashtable {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [PsCustomObject]
        $InputObject
    )

    # (karlr 2021-11-21): I really feel like I shouldn't have to do this.

    Process {
        $table = @{}

        $InputObject.PsObject.Properties |
            Where-Object { $_.MemberType -eq 'NoteProperty' } |
            ForEach-Object { $table[$_.Name] = $_.Value }

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

