function Install-Chocolatey {
    $version = choco --version

    if ($version) {
        return $version
    }

    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol =
        [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    (New-Object System.Net.WebClient).
        DownloadString('https://community.chocolatey.org/install.ps1') |
        Invoke-Expression
}

function Install-VsCodePythonPackage {
    choco install -y python vscode

    $env:Path =
        [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ';' +
        [System.Environment]::GetEnvironmentVariable("Path", "User")

    python -m pip install --upgrade pip pipx
    pipx install black flake8

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

