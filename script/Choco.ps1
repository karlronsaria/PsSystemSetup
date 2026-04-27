#Requires -RunAsAdministrator

function Install-Chocolatey {
    $command = Get-Command choco -ErrorAction SilentlyContinue

    if ($command) {
        choco --version
        return
    }

    Set-ExecutionPolicy RemoteSigned -Scope Process -Force

    [System.Net.ServicePointManager]::SecurityProtocol =
        [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    # link
    # - retrieved: 2026-04-19
    (New-Object System.Net.WebClient).
        DownloadString('https://community.chocolatey.org/install.ps1') |
        Invoke-Expression

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
        [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Install-ChocoPackage {
    Param(
        $FilePath
    )

    Install-Chocolatey
    $file = Get-Item $FilePath -ErrorAction SilentlyContinue

    if (-not $file) {
        return "No choco packages to install"
    }

    choco install $file.FullName -y
    $xml = [xml]$file

    foreach ($item in $xml.packages.package) {
        if ($item.pin -eq 'true') {
            choco pin add -n=$($item.id) --version=$($item.version)
        }
    }
}

