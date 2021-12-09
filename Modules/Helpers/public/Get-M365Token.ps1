function Get-M365Token {
    param(
        [cmdletbinding()]
        [Parameter(ParameterSetName="Client")]
        [string]$Domain,
        [Parameter(ParameterSetName="Mail")]
        [switch]$Mail
    )
    
    $body = @{
        grant_type = "client_credentials"
        scope = "https://graph.microsoft.com/.default"
    }
    
    switch ($PSCmdlet.ParameterSetName) {
        "Client" {
            $body.Add("client_Id", "$Env:MsGraphClientId")
            $body.Add("client_secret", "$Env:MsGraphClientSecret")
            $uri = "https://login.microsoftonline.com/$Domain/oauth2/v2.0/token"
        }
        "Mail" {
            $body.Add("client_Id", "$Env:MsGraphMailClientId")
            $body.Add("client_secret", "$Env:MsGraphMailClientSecret")
            $uri = "https://login.microsoftonline.com/$Env:MsGraphMailClientTenantId/oauth2/v2.0/token"
        }
    }
    
    $params = @{
        Uri = $uri
        ContentType = "application/x-www-form-urlencoded"
        Body = $body
        ResponseHeadersVariable = "resHeaders"
        StatusCodeVariable = "resStatus"
        Method = "Post"
    }
    
    $retryCount = 0
    $retryWait = 0
    do {
        Start-Sleep -Milliseconds $retryWait
        $token = Invoke-RestMethod @params
        if ($resStatus -ne 200) {
            $retryWait = Get-Random -Minimum 100 -Maximum 2000
            $retryCount += 1
        }
    } until ($resStatus -eq 200 -or $retryCount -gt 5)
    
    $token
}