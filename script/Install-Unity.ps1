$version = '2022.3.10f1'

$modules = @(
    'windows-mono'
    'android'
)

choco install -y unity-hub
choco pin add -n=unity

$hub = "${env:ProgramFiles}\Unity Hub\Unity Hub.exe"

$args = ''

if ($version) {
    $args += " --version $version"
}

foreach ($module in $modules) {
    $args += " --module $module"
}

if ($modules) {
    $args += " --childModules"
}

& $hub -- --headless install $args

