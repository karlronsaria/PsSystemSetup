# Ensure running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent() `
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run as Administrator."
    exit 1
}

Write-Host "=== Installing base tools ==="

choco install -y vscode git cmake mingw

Write-Host "=== Adding MinGW to PATH permanently ==="

$mingwPath = "C:\ProgramData\chocolatey\lib\mingw\tools\install\mingw64\bin"

if (Test-Path $mingwPath) {
    [Environment]::SetEnvironmentVariable(
        "Path",
        [Environment]::GetEnvironmentVariable("Path","Machine") + ";$mingwPath",
        "Machine"
    )
    Write-Host "MinGW added to system PATH."
} else {
    Write-Host "MinGW path not found. Verify installation."
}

Write-Host "=== Installing VS Code C++ extension ==="
code --install-extension ms-vscode.cpptools

Write-Host "=== Verifying GCC Installation ==="
g++ --version

Write-Host "=== Testing Compilation ==="

$testCode = @"
#include <iostream>
int main() {
    std::cout << "MinGW working!" << std::endl;
    return 0;
}
"@

$testFile = "$env:TEMP\test.cpp"
$exeFile = "$env:TEMP\test.exe"

$testCode | Out-File -Encoding ascii $testFile

g++ $testFile -o $exeFile

if (Test-Path $exeFile) {
    Write-Host "Compilation successful:"
    & $exeFile
} else {
    Write-Host "Compilation failed."
}

Write-Host "=== Bootstrap Complete ==="
