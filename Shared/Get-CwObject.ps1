param()

$string = "$($Env:CwCompany)+$($Env:CwPublicKey):$($Env:CwPrivateKey)"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($string)
$base64 = [System.Convert]::ToBase64String($bytes)

$properties = @{
    ClientId = $Env:CwClientId
    Auth = "Basic $base64"
    Uri = $Env:CwApiUri
    Accept = "application/vnd.connectwise.com+json; version=$Env:CwApiVersion"
}

[pscustomobject]$properties