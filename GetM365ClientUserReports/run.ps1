# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $($QueueItem.id) - $($QueueItem.identifier)"
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"
$b = Get-OutputBinding
Write-Output $b

if ($QueueItem.invoiceToEmailAddress) {
    $domain = ($QueueItem.invoiceToEmailAddress.Trim() -split '@')[1]
    Write-Output "Using invoiceToEmailAddress: $domain"
}
else {
    $contactId = $QueueItem.defaultContact.id
    $cw = .\Shared\Get-CwObject.ps1
    $params = @{
        ResponseHeadersVariable = "resHeaders"
        StatusCodeVariable      = "resStatus"
        Uri                     = "$($cw.Uri)/company/contacts/$contactId"
        ContentType             = "application/json"
        Headers                 = @{
            Authorization = $cw.Auth
            Accept        = $cw.Accept
            ClientId      = $cw.ClientId
        }
    }
    Write-Output "Looking up contact: $contactId"
    $contact = Invoke-RestMethod @params
    $domain = ($contact.communicationItems.Where( { $_.type.id -eq "1" }).domain -split '@')[1]
    Write-Output "Using default contact $domain"
}

try {
    $token = .\Shared\Get-M365Token.ps1 -Domain $domain
}
catch {
    Write-Error -Message "Could not get token using domain: $domain" -ErrorAction Stop
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

Write-Output "Report for $($QueueItem.id) - $($QueueItem.identifier) request status code: $resStatus"
$userList = $report | Select-Object -Property @{n = "DisplayName"; e = { $_."Display Name" } },
@{n = "samAccountName"; e = { $_."User Principal Name" } },
@{n = "lastLogonDate"; e = { Get-Date -Date (.\Shared\Get-UserLatestActivityDate.ps1 -User $_) -Format "M/d/yyyy hh:mm:ss tt" } }

$userListReport = [pscustomobject]@{
    recId    = $QueueItem.id
    company  = $QueueItem.identifier
    userList = $userList
}

Push-OutputBinding -Name outBlob -Value $userListReport