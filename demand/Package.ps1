<#
.DESCRIPTION
Tags: package, moniker, manager
#>

function Get-PackageMoniker {
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            $activity = "Getting package list..."

            Write-Progress `
                -Activity $activity `
                -PercentComplete 0

            $path = [PsCustomObject]@{
                Choco = "C:/shortcut/dos/backup/choco/packages.config"
                Winget = "C:/shortcut/dos/backup/winget/package.json"
            }

            $cargo = cargo install --list |
                Select-String "^\S+(?= )" |
                ForEach-Object Matches |
                ForEach-Object Value

            $choco = [xml]($path.Choco | Get-Item | Get-Content | Out-String) |
                ForEach-Object ChildNodes |
                ForEach-Object package |
                ForEach-Object id |
                Where-Object { $_ }

            $winget = $path.Winget |
                Get-Item |
                Get-Content |
                ConvertFrom-Json |
                ForEach-Object Sources |
                ForEach-Object Packages |
                ForEach-Object PackageIdentifier |
                Where-Object { $_ } |
                ForEach-Object {
                    # # (karlr 2026-01-23)
                    # ($_.Split('.') | select -Skip 1) -Join '.'
                    $temp = @($_.Split('.'))

                    switch (@($temp).Count) {
                        1 { @($temp)[0] }
                        default { @($temp | Select-Object -Skip 1) -Join '.' }
                    }
                } |
                Where-Object { $_ } | # (karlr 2026-01-23)
                Select-Object -Unique

            # $npm = npm list -g --depth=0 --json |
            #     ConvertFrom-Json |
            #     foreach dependencies |
            #     foreach PsObject |
            #     foreach Properties |
            #     where MemberType -eq 'NoteProperty' |
            #     foreach Name |
            #     foreach {
            #         $temp = @($_.Split('/'))

            #         switch (@($temp).Count) {
            #             1 { @($temp)[0] }
            #             default { @($temp | select -Skip 1) -Join '/' }
            #         }
            #     }

            $list = @($cargo) + @($choco) + @($winget) # + @($npm)

            $suggest = $list |
                Where-Object { $_ -like "$C*" }

            Write-Progress `
                -Activity $activity `
                -Completed

            return $(
                if (@($suggest | Where-Object { $_ }).Count -gt 0) {
                    $suggest
                }
                else {
                    $list
                }
            ) | ForEach-Object {
                if ($_ -match "\s|\+|\@|\/") {
                    "`"$_`""
                }
                else {
                    $_
                }
            }
        })]
        [Parameter(Position = 0)]
        [string[]]
        $Name
    )

    function Write-PackageProgress {
        Param(
            [string] $Activity,
            [string] $Status,
            [int] $Count,
            [int] $Mod = 100
        )

        Write-Progress `
            -Activity $Activity `
            -Status $Status `
            -PercentComplete $Count

        $Count = $Count + 1

        if ($Count -eq $Mod) {
            $Count = 0
        }

        return $Count
    }

    $activity = "Getting package list..."
    $count = 0

    Write-Progress `
        -Activity $activity `
        -PercentComplete 0

    $path = [PsCustomObject]@{
        Choco = "C:/shortcut/dos/backup/choco/packages.config"
        Winget = "C:/shortcut/dos/backup/winget/package.json"
    }

    $cargo = cargo install --list |
        Select-String "^\S+(?= )" |
        ForEach-Object Matches |
        ForEach-Object Value |
        ForEach-Object {
            Write-PackageProgress `
                -Activity $activity `
                -Status "Cargo: $_" `
                -Count $count

            [PSCustomObject]@{
                Moniker = $_
                Manager = 'cargo'
            }
        }

    $choco = [xml]($path.Choco | Get-Item | Get-Content | Out-String) |
        ForEach-Object ChildNodes |
        ForEach-Object package |
        ForEach-Object id |
        Where-Object { $_ } |
        ForEach-Object {
            Write-PackageProgress `
                -Activity $activity `
                -Status "Choco: $_" `
                -Count $count

            [PsCustomObject]@{
                Moniker = $_
                Manager = 'choco'
            }
        }

    $winget = $path.Winget |
        Get-Item |
        Get-Content |
        ConvertFrom-Json |
        ForEach-Object Sources |
        ForEach-Object Packages |
        ForEach-Object PackageIdentifier |
        Where-Object { $_ } |
        ForEach-Object {
            # # (karlr 2026-01-23)
            # ($_.Split('.') | select -Skip 1) -Join '.'
            $temp = @($_.Split('.'))

            switch (@($temp).Count) {
                1 { @($temp)[0] }
                default { @($temp | Select-Object -Skip 1) -Join '.' }
            }
        } |
        Where-Object { $_ } | # (karlr 2026-01-23)
        Select-Object -Unique |
        ForEach-Object {
            Write-PackageProgress `
                -Activity $activity `
                -Status "Winget: $_" `
                -Count $count

            [PsCustomObject]@{
                Moniker = $_
                Manager = 'winget'
            }
        }

    # $npm = npm list -g --depth=0 --json |
    #     ConvertFrom-Json |
    #     foreach dependencies |
    #     foreach PsObject |
    #     foreach Properties |
    #     where MemberType -eq 'NoteProperty' |
    #     foreach Name |
    #     foreach {
    #         $temp = @($_.Split('/'))

    #         switch (@($temp).Count) {
    #             1 { @($temp)[0] }
    #             default { @($temp | select -Skip 1) -Join '/' }
    #         }
    #     } |
    #     foreach {
    #         Write-PackageProgress `
    #             -Activity $activity `
    #             -Status "npm: $_" `
    #             -Count $count

    #         [PSCustomObject]@{
    #             Moniker = $_
    #             Manager = 'npm'
    #         }
    #     }

    $list = @($cargo) + @($choco) + @($winget) # + @($npm)

    Write-Progress `
        -Activity $activity `
        -Completed

    return $(
        @($Name | Where-Object { $_ }) |
        foreach {
            if ($_) {
                $list | Where-Object Moniker -like "$_*"
            }
            else {
                $list
            }
        }
    )
}

function Install-PowerShell {
    Write-Progress `
        -Id 1 `
        -Activity "Running winget" `
        -PercentComplete 50

    $table = winget search Microsoft.PowerShell |
        Where-Object { $_ -notmatch "^(\W|\s)*$" }

    Write-Progress `
        -Id 1 `
        -Activity "Running winget" `
        -PercentComplete 100 `
        -Complete

    foreach ($row in $table) {
        $captures = [Regex]::Matches($_, "\S+")

        $name = $captures[0].Value
        $id = $captures[1].Value
        $version = $captures[2].Value
        $source = $captures[3].Value

        if ($id -ne 'Microsoft.PowerShell') {
            continue
        }
    }

    $myVersion = $PsVersionTable.PsVersion
    $upgradeAvailable = $false

    $table | foreach {
        $captures = [Regex]::Matches($_, "\S+")

        $name = $captures[0].Value
        $id = $captures[1].Value
        $version = $captures[2].Value
        $source = $captures[3].Value
        $parts = $version.Split('.')

        $upgradeAvailable = $upgradeAvailable -or (
            $id -eq 'Microsoft.PowerShell' -and (
                [Int]$parts[0] -gt $myVersion.Major -or
                [Int]$parts[1] -gt $myVersion.Minor -or
                [Int]$parts[2] -gt $myVersion.Patch
            )
        )
    }

    if ($upgradeAvailable) {
        winget upgrade --id Microsoft.PowerShell --source winget
    }
}

function Show-ChocoInstalledPackage {
    Param(
        [switch]
        $GetPath
    )

    $path = "C:/ProgramData/chocolatey/logs/chocolatey.log"

    if ($GetPath) {
        return $path
    }

    $path |
        Get-Item |
        Get-Content |
        Select-String -Pattern "Successfully installed"
}

<#
.DESCRIPTION
Tags: windows, installed, programs
#>
function Get-LocalPackage {
    [OutputType([PsCustomObject[]])]
    Param(
        [String]
        $DisplayName,

        [String]
        $DisplayVersion,

        [String]
        $Publisher,

        [DateTime]
        $InstallByDate,

        [Switch]
        $Full
    )

    $pattern =
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

    if (-not $Full) {
        $packages = Get-ItemProperty $pattern |
            Select-Object `
                DisplayName,
                DisplayVersion,
                Publisher,
                InstallDate
    }

    if ($DisplayName) {
        $packages = $packages | Where-Object {
            $_.DisplayName -like $DisplayName
        }
    }

    if ($DisplayVersion) {
        $packages = $packages | Where-Object {
            $_.DisplayVersion -like $DisplayVersion
        }
    }

    if ($Publisher) {
        $packages = $packages | Where-Object {
            $_.Publisher -like $Publisher
        }
    }

    $packages = $packages |
        Where-Object { $_.DisplayName } |
        ForEach-Object {
            [PsCustomObject]@{
                DisplayName = $_.DisplayName
                DisplayVersion = $_.DisplayVersion
                Publisher = $_.Publisher
                InstallDate = if ($_.InstallDate) {
                    [DateTime]::ParseExact(
                        $_.InstallDate,
                        "yyyyMMdd",
                        $null
                    )
                }
                else {
                    $null
                }
            }
        }

    if ($InstallByDate) {
        $packages = $packages | Where-Object {
            $null -ne $_.InstallDate -and `
            $_.InstallDate -le $InstallByDate
        }
    }

    return $packages
}

<#
.LINK
* install chocolatey
  - Url: <https://chocolatey.org/docs/installation>
  - Retrieved: 2019-11-08

.LINK
* howto: check for admin privilege
  - Url: <https://serverfault.com/questions/95431/in-a-powershell-script-how-can-i-check-if-im-running-with-administrator-privil>
  - Retrieved: 2023-01-04
#>
function Install-Chocolatey {
    #Requires -RunAsAdministrator

    # link
    # - Url: <https://serverfault.com/questions/95431/in-a-powershell-script-how-can-i-check-if-im-running-with-administrator-privil>
    # - Retrieved: 2023-01-04
    function Test-RoleIsAdministrator {
        switch -Regex ($PsVersionTable.Platform) {
            'Win.*' {
                $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
                $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
                $principal = New-Object Security.Principal.WindowsPrincipal($identity)
                return $principal.IsInRole($adminRole)
            }

            'Unix' {
                return $(Invoke-Expression "id -u") -eq 0
            }
        }
    }

    if (-not (Test-RoleIsAdministrator)) {
        Write-Output "Administrator privileges are required to perform this operation."
    }

    $command = Get-Command choco -ErrorAction SilentlyContinue

    if ($command) {
        return $(choco --version)
    }

    Set-ExecutionPolicy RemoteSigned -Scope Process -Force

    [System.Net.ServicePointManager]::SecurityProtocol =
        [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    # link
    # - retrieved: 2026-04-19
    (New-Object System.Net.WebClient).
        DownloadString('https://community.chocolatey.org/install.ps1') |
        Invoke-Expression

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
        [System.Environment]::GetEnvironmentVariable("Path", "User")
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

    $xml = [xml]$file

    foreach ($item in $xml.packages.package) {
        if ($item.pin -eq 'true') {
            choco pin remove -n=$($item.id)
            choco install -y $($item.id) --version=$($item.version) --pre --force --allow-downgrade
            choco pin add -n=$($item.id) --version=$($item.version)
        }
    }

    choco install $file.FullName -y
}

function Install-WebItem {
    [CmdletBinding(DefaultParameterSetName = 'RunNormally')]
    Param(
        [string]
        $Uri,

        [Parameter(ParameterSetName = 'ScriptBlock')]
        [scriptblock]
        $ScriptBlock
    )

    $fileItem = $null

    Save-WebItem -Uri $Uri |
        ForEach-Object {
            switch ($_) {
                { $_ -is [string] } {
                    Write-Output $_
                    break
                }

                { $_ -is [System.IO.FileInfo] } {
                    $fileItem = $_

                    switch ($PsCmdlet.ParameterSetName) {
                        'RunNormally' {
                            & $_.FullName
                        }

                        'ScriptBlock' {
                            $_ | ForEach-Object $ScriptBlock
                        }
                    }

                    break
                }

                { $_ -is [System.IO.DirectoryInfo] } {
                    Write-Output $_
                    break
                }
            }
        }

    if (-not $fileItem) {
        "Failed to install '$Uri'"
    }
}

function Get-ReverseDomainName {
    Param(
        [string]
        $Uri
    )

    $pattern =
        "^(?<protocol>[^:]+):\/\/(?<application>.*)\.(?<minor>[^\.\/]+)\.(?<major>[^\.\/]+)\/.*\/(?<leaf>[^\/]+)$"

    $match = [regex]::Match($uri, $pattern)

    if (-not $match.Success) {
        return ''
    }

    $groups = $match.Groups
    return "$($groups['major'].Value).$($groups['minor'].Value).$($groups['application'].Value)/$($groups['leaf'].Value)"
}

function Save-WebItem {
    Param(
        [string]
        $Uri
    )

    $name = Get-ReverseDomainName -Uri $Uri
    $folder = Split-Path $name
    $path = "$PsScriptRoot/../res/install"
    $folderPath = Join-Path $path $folder

    if (-not (Test-Path $folderPath)) {
        New-Item $folderPath
    }

    $leaf = Split-Path $Uri -Leaf
    $item = Join-Path $folderPath $leaf
    $runOnSave = { Get-Item $_ -ErrorAction SilentlyContinue }

    if ((Test-Path $item)) {
        return $item | ForEach-Object $runOnSave
    }

    "Downloading $leaf using curl."
    "Please wait."

    if ((Get-Command curl -ErrorAction SilentlyContinue)) {
        curl -L $Uri --output $item
        return $item | ForEach-Object $runOnSave
    }

    $myHttpClientType = @"
namespace My {
    public class HttpClient {
        public static async System.Threading.Tasks.Task<bool> Save(string Source, string Destination) {
            bool success = false;

            try {
                using var client = new System.Net.Http.HttpClient();
                using var response = await client.GetAsync(Source);
                response.EnsureSuccessStatusCode();
                using var stream = response.Content.ReadAsStreamAsync().Result;
                using var file = System.IO.File.Create(Destination);
                stream.CopyTo(file);
                success = System.IO.File.Exists(Destination);
            }
            catch (System.Exception e) {
                System.Console.WriteLine("\nException Caught!");
                System.Console.WriteLine("Message: {0} ", e.Message);
                success = false;
            }

            return success;
        }
    }
}
"@

    Add-Type -TypeDefinition $myHttpClientType

    "Downloading $leaf using HttpClient."
    "Please wait."

    if (([My.HttpClient]::Save($Uri, $item).GetAwaiter().GetResult())) {
        Start-Sleep -Milliseconds 200
        return $item | ForEach-Object $runOnSave
    }

    "Downloading $leaf using WebClient."
    "Please wait."

    (New-Object System.Net.WebClient).DownloadFile($Uri, $item)

    if ((Test-Path $item)) {
        return $item | ForEach-Object $runOnSave
    }

    "Downloading $leaf using BITS."
    "Please wait."

    Start-BitsTransfer `
        -Source $Uri `
        -Destination $item

    if ((Test-Path $item)) {
        return $item | ForEach-Object $runOnSave
    }

    "Downloading $leaf using Invoke-WebRequest."
    "Please wait."

    Invoke-WebRequest `
        -Uri $Uri `
        -OutFile $item

    if ((Test-Path $item)) {
        return $item | ForEach-Object $runOnSave
    }

    return $null
}

function Find-UninstallCommand {
    Param(
        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )

            $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()

            $keys = @(
                'HKLM:/Software/Microsoft/Windows/CurrentVersion/Uninstall/*',
                'HKLM:/Software/Wow6432Node/Microsoft/Windows/CurrentVersion/Uninstall/*'
            )

            Get-ItemProperty -Path $keys |
                ForEach-Object DisplayName |
                Where-Object { $_ } |
                Where-Object { $_ -like "$WordToComplete*" } |
                ForEach-Object { if ($_ -match "\s|\&") { "`"$_`"" } else { $_ } } |
                ForEach-Object { $CompletionResults.Add($_) }

            return $CompletionResults
        })]
        [string]
        $WildcardPattern,

        [switch]
        $Quiet,

        [switch]
        $NoRestart,

        [switch]
        $GetKeyPath
    )

    $keys = @(
        'HKLM:/Software/Microsoft/Windows/CurrentVersion/Uninstall/*',
        'HKLM:/Software/Wow6432Node/Microsoft/Windows/CurrentVersion/Uninstall/*'
    )

    if ($GetKeyPath) {
        if (-not $WildcardPattern) {
            return Get-ItemProperty -Path $keys
        }

        return Get-ItemProperty -Path $keys |
            Where-Object DisplayName -like $WildcardPattern
    }

    Get-ItemProperty -Path $keys |
        Where-Object DisplayName -like $WildcardPattern |
        ForEach-Object UninstallString |
        ForEach-Object { "$_$(if ($Quiet) { " /quiet" })$(if ($NoRestart) { " /norestart" })" }
}

