#Requires -RunAsAdministrator

function Install-PythonPackage {
    Param(
        [string]
        $UserName,

        $FileStorePath = "$PsScriptRoot/../res/python"
    )

    $command = Get-Command python -ErrorAction SilentlyContinue

    if (-not $command) {
        return "Python is not installed. Please install python before you continue."
    }

    python --version
    $path = Get-Item $FileStorePath -ErrorAction SilentlyContinue

    if (-not $path) {
        return "No python packages to install"
    }

    $fullName = $path.FullName
    Copy-Item "$fullName/.idlerc" "C:/Users/$UserName" -Recurse -Force
    pip install -r "$fullName/requirements.txt"
}

