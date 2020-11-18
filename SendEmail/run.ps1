# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $QueueItem"
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"

$filePath = "$env:TEMP\$($QueueItem.recId)-$($QueueItem.company)-userlist.csv"

$QueueItem.userList.foreach( { [pscustomobject]$_ | Select-Object -Property samAccountName, displayName, lastLogonDate }) | Export-Csv -Path $filePath

$credential = [pscredential]::new($Env:AuthSmtpUserName, (ConvertTo-SecureString -String $Env:AuthSmtpPassword -AsPlainText -Force))

$mailParams = @{
    To         = $Env:MailTo
    From       = $Env:MailFrom
    Subject    = "User list from $($QueueItem.company)"
    Body       = "See attachment"
    Attachment = $filePath
}

try {
    .\Shared\Send-GraphMail.ps1 @mailParams -ErrorAction Stop
}
catch {
    throw "Failed to send email: $($_.ErrorDetails.Message)"
}

Remove-Item -Path $filePath
