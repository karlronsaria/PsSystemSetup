function Get-SystemSetupProfile {
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
            
            "$PsScriptRoot/../res/profile.json" |
                Get-Item |
                Get-Content |
                ConvertFrom-Json |
                ForEach-Object profile |
                ForEach-Object Name |
                ForEach-Object {
                    $CompletionResults.Add($_)
                }
            
            return $CompletionResults
        })]
        [string[]]
        $Name,

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
            
            $volumes = Get-Volume |
                Where-Object DriveType -eq 'Removable'
                
            if (-not $volumes) {
                $CompletionResults.Add('no-removable-devices-found')
            }
            else {
                $volumes |
                    ForEach-Object DriveLetter |
                    ForEach-Object {
                        $CompletionResults.Add("$_")
                    }
            }
            
            return $CompletionResults
        })]
        [string[]]
        $Drive,

        [switch]
        $Eject,

        [switch]
        $Force,

        [switch]
        $WhatIf
    )
    
    $valid = $true
    
    if (-not $Name) {
        $valid = $false
        'You must select a setup profile'
    }
    
    if (-not $Drive) {
        $valid = $false
        'You must select a drive letter'
    }
    
    if ($Drive -eq 'no-removable-devices-found') {
        $valid = $false
        'No removable devices found'
    }
    
    if (-not $valid) {
        return
    }
    
    foreach ($subname in $Name) {
        $item = "$PsScriptRoot/../res/profile.json" |
            Get-Item |
            Get-Content |
            ConvertFrom-Json |
            ForEach-Object profile |
            Where-Object { $_.Name.ToLower() -eq $subname.ToLower() }
            
        foreach ($driveLetter in $Drive) {
            $parent = Join-Path "${driveletter}:" $item.Name
            
            if (-not (Test-Path $parent)) {
                $parent = mkdir $parent -Force:$Force
            }
            
            foreach ($subitem in @($item.Items)) {
                $location = $parent
                $parts = $subitem -split "\/|\\"
                $leaf = $parts | Select-Object -Last 1
                $parts = $parts | Select-Object -SkipLast 1
                
                foreach ($part in $parts) {
                    $location = Join-Path $location $part

                    if (-not (Test-Path $location)) {
                        $location = mkdir $location -Force:$Force
                    }
                }
                
                $source = Join-Path "$PsScriptRoot/.." $subitem
                $destination = Join-Path $location $leaf
                
                if ($WhatIf) {
                    [pscustomobject]@{
                        Source = $source
                        Destination = $destination
                    }
                    
                    continue
                }

                Copy-Item `
                    -Path $source `
                    -Destination $destination `
                    -Force:$Force
                    
                $parent
            }
        }
    }

    if ($Eject) {
        foreach ($driveLetter in $Drive) {
            if ($WhatIf) {
                "Ejecting drive letter $driveLetter"
                continue
            }

            Get-Volume -DriveLetter $driveLetter |
                ForEach-Object {
                    $_ | Get-Partition | Get-Disk
                } |
                Set-Disk -IsOffline $true
        }
    }
}
