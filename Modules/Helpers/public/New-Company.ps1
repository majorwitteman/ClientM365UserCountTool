function New-Company {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int] $RecId,
        [Parameter(Mandatory = $true)]
        [string] $Identifier,
        [parameter(Mandatory = $true)]
        [string] $Name,
        [Parameter(Mandatory = $true)]
        [int] $ActiveUserCount,
        [Parameter(Mandatory = $true)]
        [string] $RunId
    )

    [Company]@{
        id = (New-Guid).Guid
        recId         = $RecId;
        identifier = $Identifier;
        activeUserCount  = $ActiveUserCount;
        runId      = $RunId;
        name = $Name;
    }
}

class Company {
    [string] $id
    [int] $recId
    [string] $identifier
    [string] $name
    [int] $activeUserCount
    [string] $runId
}