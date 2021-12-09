function New-Document {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$FoundCompanyCount
    )
    [Document]@{
        id                = (New-Guid).Guid
        foundCompanyCount = $FoundCompanyCount
        runDate           = (Get-Date).ToUniversalTime().ToString("u")
    }
}

class Document {
    [string] $id
    [int] $foundCompanyCount
    [datetime] $runDate
    [int] $errorCount
    [int] $successCount
    [System.Collections.ArrayList] $companies
}