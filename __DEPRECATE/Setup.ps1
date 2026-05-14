<#
.SYNOPSIS
Optimize PowerShell startup by reducing JIT compile time with "ngen.exe"

.DESCRIPTION
Optimize PowerShell startup by reducing JIT compile time with "ngen.exe".

Script requires administrative permissions.

###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  OptimizePowerShellStartup.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Optimize PowerShell startup by reduce JIT compile time with ngen.exe
# Repository   :  https://github.com/BornToBeRoot/PowerShell
###############################################################################################################

.LINK
* main repo
  - Url: <https://github.com/BornToBeRoot/PowerShell/blob/master/Documentation/Script/OptimizePowerShellStartup.README.md>
  - Retrieved: 2025-02-05
#>

function Start-OptimizePowerShellStartup {
    Process {
        $is_admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
            IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

        # Restart script/console as admin with parameters
        if (-not $is_admin) {
            Start-Process `
                PowerShell.exe `
                -Verb RunAs `
                -ArgumentList "& '$($MyInvocation.MyCommand.Definition)'"

            return
        }

        # Set ngen path
        $ngen_path = Join-Path -Path $env:windir -ChildPath "Microsoft.NET"

        $child_path = if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
            'Framework64'
        }
        else {
            'Framework'
        }

        $ngen_path = Join-Path -Path $ngen_path -ChildPath "$child_path\ngen.exe"

        # Find latest ngen.exe
        $ngen_application_path = Get-ChildItem -Path $ngen_path -Filter "ngen.exe" -Recurse |
            Where-Object { $_.Length -gt 0 } |
            Select-Object -Last 1
            ForEach-Object Fullname

        # Get assemblies and call ngen.exe
        [System.AppDomain]::CurrentDomain.GetAssemblies() |
            ForEach-Object { & $ngen_application_path install $_.Location /nologo /verbose }
    }
}

