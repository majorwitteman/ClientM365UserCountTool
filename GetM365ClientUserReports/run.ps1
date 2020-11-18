# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $QueueItem"
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"

try {
    $token = .\Shared\Get-M365Token.ps1 -Domain $QueueItem.website.Trim()
}
catch {
    $token = .\Shared\Get-M365Token.ps1 -Domain ($QueueItem.invoiceToEmailAddress.Trim() -split '@')[1]
}

$reportUri = "https://graph.microsoft.com/v1.0/reports/getOffice365ActiveUserDetail(period='D30')"

$params = @{
    Uri = $reportUri
    Method = "Get"
    Headers = @{
        Authorization = "Bearer $($token.access_token)"
    }
    ResponseHeadersVariable = "resHeaders"
    StatusCodeVariable = "resStatus"
}

$report = Invoke-RestMethod @params | ConvertFrom-Csv
$userList = $report | Select-Object -Property @{n="DisplayName";e={$_."Display Name"}},
                                              @{n="samAccountName";e={($_."User Principal Name" -split '@')[0]}},
                                              @{n="lastLogonDate";e={Get-Date -Date (.\Shared\Get-UserLatestActivityDate.ps1 -User $_) -Format "M/d/yyyy hh:mm:ss tt"}}

$userListReport = [pscustomobject]@{
    recId = $QueueItem.id
    company = $QueueItem.identifier
    userList = $userList
}

Push-OutputBinding -Name "userlist" -Value $userListReport