function Get-AttachmentBytes {
    param (
        [string]$Path
    )
    
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    
    $base64 = [System.Convert]::ToBase64String($bytes)
    
    $base64
}