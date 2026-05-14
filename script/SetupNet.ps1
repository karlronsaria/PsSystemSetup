function Connect-NetProfile {
    $connection = Test-NetConnection | ForEach-Object PingSucceeded

    if ($connection.PingSucceeded) {
        return $connection
    }

    Import-Module "$PsScriptRoot/../module/wifiprofilemanagement/1.1.0.0/WiFiProfileManagement.psd1"

    $setting = "$PsScriptRoot/../res/setting.json"
    $net = $setting.NetProfile

    New-WiFiProfile `
        -ProfileName $net.ProfileName `
        -Authentication $net.Authentication `
        -Encryption $net.Encryption `
        -ConnectionMode 'auto' `
        -Password (
            Read-Host -Prompt "Password for $($net.ProfileName)" -AsSecureString |
            ConvertFrom-SecureString -AsPlainText `
        )

    Connect-WiFiProfile `
        -ProfileName $net.ProfileName
}

