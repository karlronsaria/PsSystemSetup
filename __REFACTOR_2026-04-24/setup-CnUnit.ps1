. "$PsScriptRoot/../demand/Registry.ps1"
. "$PsScriptRoot/../demand/Package.ps1"
. "$PsScriptRoot/../script/Net.ps1"
. "$PsScriptRoot/../script/Web.ps1"
. "$PsScriptRoot/../script/Feature.ps1"
. "$PsScriptRoot/../script/Clean.ps1"

$name = 'CodeNinjas'
$password = 'cn123456'

New-LocalUser `
    -Name $name `
    -FullName $name `
    -Password $password `
    -AccountNeverExpires `
    -PasswordNeverExpires

Add-LocalGroupMember `
    -Group 'Users' `
    -Member $name

$name = 'Admin'

New-LocalUser `
    -Name $name `
    -FullName $name `
    -Password (
        Read-Host -Prompt "Password for $name" -AsSecureString |
        ConvertFrom-SecureString -AsPlainText `
    ) `
    -AccountNeverExpires `
    -PasswordNeverExpires

Add-LocalGroupMember `
    -Group 'Administrators' `
    -Member $name

Install-Registry

Write-Verbose "Uninstalling OneDrive"
Uninstall-OneDrive

Write-Verbose "Disabling Network Discovery"
Set-FeatureNetworkDiscovery -Value $false

Write-Verbose "Disabling File-sharing"
Set-FeatureFileAndPrinterSharing -Value $false

Write-Verbose "Disabling Explorer animations"
Set-ExplorerAnimationPreference -Value $false

Write-Verbose "Removing Appx packages"
Set-AppxPackage -Action Remove -Preference Thin

"$PsScriptRoot/../dos/*.bat" |
    Get-ChildItem |
    ForEach-Object { & "$_.FullName" }

Connect-NetProfile
Start-WebZoicwareRemoveWindowsAi
Add-WebGroupPolicyEditor

# link
# - retrieved: 2026-05-03
Install-WebItem `
    -Uri "https://assets.education.lego.com/_/downloads/SPIKE_APP_3_Win10__3.6.0_Global.msi"

# link
# - retrieved: 2026-05-03
Install-WebItem `
    -Uri "https://setup.rbxcdn.com/RobloxStudioLauncherBeta.exe" `
    -ScriptBlock { & $_.FullName -install }

Find-UninstallCommand `
    -WildCardPattern "*LEGO*Spike*Legacy*" |
    ForEach-Object { $_ | Invoke-Expression }

