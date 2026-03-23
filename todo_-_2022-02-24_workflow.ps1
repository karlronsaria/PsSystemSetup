. $PsScriptRoot\script\SystemPrepare.ps1

$result = Get-Item $PsScriptRoot\res\myform.json `
    | Get-Content `
    | ConvertFrom-Json `
    | Get-ObjectForm `
    | ConvertTo-Hashtable

$result.Remove('ConfirmChanges')
$result.Remove('NewHostname')
Start-SystemPrepare @result

