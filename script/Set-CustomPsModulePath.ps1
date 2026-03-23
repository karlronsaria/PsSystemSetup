Param(
    [string]
    $NewPath = "${env:SystemDrive}\shortcut\pwsh\Modules",

    [System.EnvironmentVariableTarget]
    $Target = [System.EnvironmentVariableTarget]::Machine
)

$variableName = 'PSModulePath'
$currentModulePath = [Environment]::GetEnvironmentVariable($variableName, $Target)

if ($currentModulePath.Split(';') -notcontains $customModulePath) {
    [Environment]::SetEnvironmentVariable(
        $variableName,
        "$customModulePath;$currentModulePath",
        $Target
    )
}

