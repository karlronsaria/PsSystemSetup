
. "$PsScriptRoot/../script/SetupRegistry.ps1"
. "$PsScriptRoot/../demand/Package.ps1"
. "$PsScriptRoot/../script/SetupNet.ps1"
. "$PsScriptRoot/../demand/Web.ps1"
. "$PsScriptRoot/../script/SetupFeature.ps1"
. "$PsScriptRoot/../demand/Workaround.ps1"

$name = 'CodeNinjas'

$password = ConvertTo-SecureString `
    -String 'cn123456' `
    -AsPlainText `
    -Force

$user = Get-LocalUser -Name $name -ErrorAction SilentlyContinue

if ($null -eq $user) {
    New-LocalUser `
        -Name $name `
        -FullName $name `
        -Password $password `
        -AccountNeverExpires:$true `
        -PasswordNeverExpires:$true
}
else {
    Set-LocalUser `
        -Name $name `
        -FullName $name `
        -Password $password `
        -AccountNeverExpires:$true `
        -PasswordNeverExpires:$true
}

Add-LocalGroupMember `
    -Group 'Users' `
    -Member $name

$name = 'Admin'
$user = Get-LocalUser -Name $name -ErrorAction SilentlyContinue

if ($null -eq $user) {
    New-LocalUser `
        -Name $name `
        -FullName $name `
        -Password (
            Read-Host -Prompt "Password for $name" -AsSecureString
        ) `
        -AccountNeverExpires:$true `
        -PasswordNeverExpires:$true
}
else {
    Set-LocalUser `
        -Name $name `
        -FullName $name `
        -Password (
            Read-Host -Prompt "Password for $name" -AsSecureString
        ) `
        -AccountNeverExpires:$true `
        -PasswordNeverExpires:$true
}

Add-LocalGroupMember `
    -Group 'Administrators' `
    -Member $name

Install-Registry

Write-Verbose "Uninstalling OneDrive"
Uninstall-OneDrive

Write-Verbose "Disabling Network Discovery"
Set-FeatureNetworkDiscovery -Value False

Write-Verbose "Disabling File-sharing"
Set-FeatureFileAndPrinterSharing -Value False

Write-Verbose "Disabling Explorer animations"
Set-ExplorerAnimationPreference -Value False

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

& "$PsScriptRoot/../res/install/MCreator.2024.1.Windows.64bit.exe"

