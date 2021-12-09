# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $($QueueItem.id) - $($QueueItem.identifier)"
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"

if ($QueueItem.invoiceToEmailAddress) {
    $domain = ($QueueItem.invoiceToEmailAddress.Trim() -split '@')[1]
    switch ($domain) {
        "vizuriusa.com" { $domain = "propellatx.com" }
        "wiley.com" { $domain = "jjeditorial.com" }
    }
    Write-Verbose "Using invoiceToEmailAddress: $domain"
    
}
else {
    $domain = Get-ContactDomain -ContactId $QueueItem.defaultContact.id
    Write-Verbose "Using default contact $domain"
}

try {
    $token = Get-M365Token -Domain $domain
}
catch {
    Write-Error -Message "Could not get token using domain: $domain. Exception: $($_.Exception)" -ErrorAction Stop
}

$reportUri = "https://graph.microsoft.com/v1.0/reports/getOffice365ActiveUserDetail(period='D30')"

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
    Write-Error "Report request failed for $($QueueItem.id) - $($QueueItem.identifier). Error $($_.Exception)" -ErrorAction Stop
}

Write-Verbose "Report for $($QueueItem.id) - $($QueueItem.identifier) request status code: $resStatus"
$userList = $report | Select-Object -Property @{n = "DisplayName"; e = { $_."Display Name" } },
@{n = "samAccountName"; e = { $_."User Principal Name" } },
@{n = "lastLogonDate"; e = { Get-Date -Date (Get-UserLatestActivityDate -User $_) -Format "M/d/yyyy hh:mm:ss tt" } }

$userList = $userListResponse |
Select-Object -Property @{n = "samAccountName"; e = { $_.userPrincipalName } },
displayName,
@{n = "activeDate"; e = { (Get-Date).ToString(("M/d/yyyy hh:mm:ss tt")) } },
@{n = "Source"; e = { "M365" } }

$userListReport = [pscustomobject]@{
    recId    = $QueueItem.id
    company  = $QueueItem.identifier
    userList = $userList
}

Push-OutputBinding -Name outBlob -Value $userListReport