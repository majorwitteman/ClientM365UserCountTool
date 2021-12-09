function Send-GraphMail {
    param (
        [cmdletbinding()]
        [string]$To = $Env:MailTo,
        [string]$From = $Env:MailFrom,
        [string]$Subject,
        [string]$Body,
        [string]$Attachment
    )
    
    $uri = "https://graph.microsoft.com/v1.0/users/$Env:MailFrom/sendMail"
    
    $attachName = Split-Path -Path $Attachment -Leaf
    $attachBytes = Get-AttachmentBytes -Path $Attachment
    
    $body = @{
        "message" = @{
            "subject" = $Subject
            "body" = @{
                "contentType" = "HTML"
                "content" = $Body
            }
            "toRecipients" = @(
                @{
                    "emailAddress" = @{
                        "address" = $To
                    }
                }
            )
            "attachments" = @(
                @{
                    "@odata.type" = "#microsoft.graph.fileAttachment"
                    "name" = "$attachName"
                    "contentType" = "text/plain"
                    "contentBytes" = $attachBytes
                }
            )
        }
        "saveToSentItems" = $false
    } | ConvertTo-Json -Depth 5
    
    $token = Get-M365Token -Mail
    
    $params = @{
        Headers = @{
            "Authorization" = "Bearer $($token.access_token)"
        }
        ContentType = "application/json"
        Method = "Post"
        Body = $Body
        Uri = $uri
        StatusCodeVariable = "statusCode"
    }
    
    $retryCount = 0
    $retryWait = 0
    do {
        Start-Sleep -Milliseconds $retryWait
        try {
            Invoke-RestMethod @params
        }
        catch { }
        if ($statusCode -ne 202) {
            $retryWait = Get-Random -Minimum 100 -Maximum 2000
            $retryCount += 1
        }
    } until ($statusCode -eq 202 -or $retryCount -gt 10)
}