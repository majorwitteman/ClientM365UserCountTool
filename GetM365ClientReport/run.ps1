# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $($QueueItem.id) - $($QueueItem.identifier)"
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"

$domain = $QueueItem.defaultdomainname

try {
    $token = Get-M365Token -Domain $domain
}
catch {
    Write-Error -Message "Could not get token using domain: $domain. Exception: $($_.Exception)" -ErrorAction Stop
}

$reportUri = "https://graph.microsoft.com/v1.0/reports/getEmailAppUsageAppsUserCounts(period='D30')"

$params = @{
    Uri                     = $reportUri
    Method                  = "Get"
    Headers                 = @{
        Authorization = "Bearer $($token.access_token)"
    }
    ResponseHeadersVariable = "resHeaders"
    StatusCodeVariable      = "resStatus"
}

try {
    $report = Invoke-RestMethod @params | ConvertFrom-Csv
}
catch {
    Write-Error "Report request failed for $($QueueItem.name) - $($domain). Error $($_.Exception)" -ErrorAction Stop
}

Write-Verbose "Report for $($QueueItem.name) - $($QueueItem.domain) request status code: $resStatus"

$output = [pscustomobject]@{
    company = $QueueItem.name
    defaultdomain = $domain
    pop3 = $report."pop3 app"
    imap4 = $report."imap4 app"
    smtp = $report."smtp app"
} | ConvertTo-Csv | ForEach-Object { "$_`r`n" }

Push-OutputBinding -Name outBlob -Value ([System.Text.Encoding]::ASCII.GetBytes($output))