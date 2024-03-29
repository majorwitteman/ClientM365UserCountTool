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

$userUri = 'https://graph.microsoft.com/v1.0/users?$filter=(accountEnabled eq true)&$select=userPrincipalName,displayName,userType'

$params = @{
    Uri                     = $userUri
    Method                  = "Get"
    Headers                 = @{
        Authorization = "Bearer $($token.access_token)"
    }
    ResponseHeadersVariable = "resHeaders"
    StatusCodeVariable      = "resStatus"
}

$retryCount = 0
$retryWait = 0
$morePages = $true
$userListResponse = do {
    Start-Sleep -Milliseconds $retryWait
    $userResponse = Invoke-RestMethod @params
    if ($resStatus -ne 200) {
        $retryWait = Get-Random -Minimum 100 -Maximum 2000
        $retryCount += 1
        continue
    }
    if ($userResponse."@odata.nextLink") {
        $params.Uri = $userResponse."@odata.nextLink"
    }
    else {
        $morePages = $false
    }
    $userResponse.value.where{$_.userType -ne "Guest"}
} until ($retryCount -gt 5 -or $morePages -eq $false)

Write-Verbose "Report for $($QueueItem.id) - $($QueueItem.identifier) request status code: $resStatus"

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