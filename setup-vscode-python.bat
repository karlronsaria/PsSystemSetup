set "cmd=. %~dp0./script/SetupVsCodeWithPython.ps1"
set "cmd=%cmd%; Install-Chocolatey"
set "cmd=%cmd%; Install-VsCodePythonPackage"

powershell -NoProfile -Command "%cmd%"

