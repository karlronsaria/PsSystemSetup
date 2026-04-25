<#
.DESCRIPTION
Tags: vscode, python
#>

function Install-Chocolatey {
    $version = choco --version

    if ($version) {
        return $version
    }

    Set-ExecutionPolicy Bypass -Scope Process -Force

    [System.Net.ServicePointManager]::SecurityProtocol =
        [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    # link
    # - retrieved: 2026-04-19
    (New-Object System.Net.WebClient).
        DownloadString('https://community.chocolatey.org/install.ps1') |
        Invoke-Expression
}

function Install-ChocoPackage {
    $package = "$PsScriptRoot/../res/choco-package.json" |
        Get-ChildItem |
        Get-Content |
        ConvertFrom-Json
        
    choco pin -y $(package.Pin -join ' ')
    choco install -y $($package.Install -join ' ')
}

function Install-ChocoPython {
    # # (karlr 2026-02-18): Python pushed a release that is not compatible with
    # # pygame and breaks pygame projects.
    # choco install -y python vscode
    choco pin remove -n python
    choco install -y python --version=3.12.10 --pre --force --allow-downgrade
    choco pin add -n python
    choco install -y vscode

    $env:Path =
        [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ';' +
        [System.Environment]::GetEnvironmentVariable("Path", "User")

    python -m pip install --upgrade pip pipx
    pipx install black flake8
}

function Install-VsCodePythonPackage {
    Install-ChocoPython
    code --install-extension ms-python.python
    code --install-extension ms-python.vscode-pylance
    code --install-extension ms-python.debugpy
}

function New-VsCodePythonProject {
    Param(
        [string]
        $ProjectLocation
    )

    if (-not $ProjectLocation) {
        Write-Error "No, you're not doing that. You need to give me a project location."
        return
    }

    $env:Path =
        [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
        [System.Environment]::GetEnvironmentVariable("Path","User")

    New-Item -ItemType Directory -Force -Path $ProjectLocation | Out-Null
    Push-Location $ProjectLocation

    python -m venv .venv
    .\.venv\Scripts\Activate

    @'
print("Hello, world!")
'@ | Out-File -Encoding UTF8 main.py

    $settingsPath = ".\.vscode"
    New-Item -ItemType Directory -Force -Path $settingsPath | Out-Null

    @"
{
    "python.defaultInterpreterPath": "$ProjectLocation/.venv/Scripts/python.exe",
    "python.terminal.activateEnvironment": true,
    "editor.formatOnSave": true
}
"@ | Out-File -Encoding UTF8 "$settingsPath\settings.json"

    Pop-Location
}

