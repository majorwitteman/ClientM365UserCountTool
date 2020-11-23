# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

#$PWD
$cw = .\Shared\Get-CwObject.ps1

$params = @{
    ResponseHeadersVariable = "resHeaders"
    StatusCodeVariable = "resStatus"
    FollowRelLink = $true
    Uri = "$($cw.Uri)/company/companies?childConditions=types/id=$($Env:CwCompanyTypeId)&fields=id,identifier,name,website,invoiceToEmailAddress"
    ContentType = "application/json"
    Headers = @{
        Authorization = $cw.Auth
        Accept = $cw.Accept
        ClientId = $cw.ClientId
    }
}

$retryCount = 0
$retryWait = 0
do {
    Start-Sleep -Milliseconds $retryWait
    $companies = Invoke-RestMethod @params
    if ($resStatus -ne 200) {
        $retryWait = Get-Random -Minimum 100 -Maximum 2000
        $retryCount += 1
    }
} until ($resStatus -eq 200 -or $retryCount -gt 5)

$companies.foreach({ Push-OutputBinding -Name "company" -Value $_ })