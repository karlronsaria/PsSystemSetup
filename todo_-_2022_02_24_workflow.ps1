. $PsScriptRoot\SystemPrepare.ps1

$result = cat $PsScriptRoot\res\myform.json `
    | ConvertFrom-Json `
    | Get-ObjectForm `
    | ConvertTo-Hashtable

$result.Remove('ConfirmChanges')
$result.Remove('NewHostname')
Start-SystemPrepare @result

