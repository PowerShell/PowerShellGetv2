function Get-First
{
    param
    (
        [Parameter(Mandatory=$true)]
        $IEnumerator
    )

    foreach($item in $IEnumerator)
    {
        return $item
    }

    return $null
}