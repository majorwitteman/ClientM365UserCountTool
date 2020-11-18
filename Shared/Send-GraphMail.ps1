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
$attachBytes = .\Shared\Get-AttachmentBytes.ps1 -Path $Attachment

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

$token = .\Shared\Get-M365Token.ps1 -Mail

$params = @{
    Headers = @{
        "Authorization" = "Bearer $($token.access_token)"
    }
    ContentType = "application/json"
    Method = "Post"
    Body = $Body
    Uri = $uri
}

Invoke-RestMethod @params
