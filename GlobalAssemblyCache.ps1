#Requires -Version 3 -RunAsAdministrator

<#
    .LINK
        Link: https://www.andrewcbancroft.com/2015/12/16/using-powershell-to-install-a-dll-into-the-gac/
        Retrieved: 2021_11_23
#>
function Update-GlobalAssemblyCache {
    [Alias('Update-Gac')]
    [CmdletBinding()]
    Param()

    $items = [AppDomain]::CurrentDomain.GetAssemblies() `
        | Where { -not [String]::IsNullOrWhiteSpace($_.Location) } `
        | Sort { Split-Path $_.Location -Leaf }

    $assembly = "System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a"
    Write-Verbose "Updating Global Assembly Cache..."
    [System.Reflection.Assembly]::Load($assembly)
    $publish = New-Object System.EnterpriseServices.Internal.Publish

    foreach ($item in $items) {
        Write-Output $item
        $publish.GacInstall($item)
    }
}

