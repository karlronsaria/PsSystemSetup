function Install-Registry {
    "$PsScriptRoot/../reg/*.reg" |
        Get-ChildItem |
        ForEach-Object { reg import $_.FullName }
}

