# Input bindings are passed in via param block.
param([byte[]]$InputBlob, $TriggerMetadata)

$report = [System.Text.Encoding]::UTF8.GetString($InputBlob) | ConvertFrom-Json

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $($report.recId) - $($report.company)"
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"

$filePath = "$env:TEMP\$($report.recId)-$($report.company)-userlist.csv"

$report.userList.foreach( { [pscustomobject]$_ | Select-Object -Property samAccountName, displayName, activeDate, source }) | Export-Csv -Path $filePath

$mailParams = @{
    To         = $Env:MailTo
    From       = $Env:MailFrom
    Subject    = "User list from $($report.recId) $($report.company)"
    Body       = "See attachment"
    Attachment = $filePath
}

try {
    Write-Verbose "Sending email: $($mailParams.Subject)"
    Send-GraphMail @mailParams -ErrorAction Stop
}
catch {
    throw "Failed to send email: $($_.Exception)"
}

Remove-Item -Path $filePath
