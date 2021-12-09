function Get-ContactDomain {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [int]
        $ContactId
    )
    $cw = Get-CwObject
    $params = @{
        ResponseHeadersVariable = "resHeaders"
        StatusCodeVariable      = "resStatus"
        Uri                     = "$($cw.Uri)/company/contacts/$ContactId"
        ContentType             = "application/json"
        Headers                 = @{
            Authorization = $cw.Auth
            Accept        = $cw.Accept
            ClientId      = $cw.ClientId
        }
    }
    Write-Verbose "Looking up contact: $contactId"
    $contact = Invoke-RestMethod @params
    ($contact.communicationItems.Where( { $_.type.id -eq "1" }).domain -split '@')[1]
}