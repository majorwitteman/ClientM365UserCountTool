param ([pscustomobject]$User)

$properties = $User | Get-Member -MemberType NoteProperty -Name "*Last Activity*"

$latestDate = [datetime]::MinValue

$properties.Name.ForEach({
    $dateString = $User.$_
    if(-not ([string]::IsNullOrWhiteSpace($dateString))) { 
        $date = get-date ($dateString)
        if ($date -gt $latestDate) {
            $latestDate = $date
        }
    }
})

$latestDate