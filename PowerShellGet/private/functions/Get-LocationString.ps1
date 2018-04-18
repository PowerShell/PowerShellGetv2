function Get-LocationString
{
    [CmdletBinding(PositionalBinding=$false)]
    Param
    (
        [Parameter()]
        [Uri]
        $LocationUri
    )

    $LocationString = $null

    if($LocationUri)
    {
        if($LocationUri.Scheme -eq 'file')
        {
            $LocationString = $LocationUri.OriginalString
        }
        elseif($LocationUri.AbsoluteUri)
        {
            $LocationString = $LocationUri.AbsoluteUri
        }
        else
        {
            $LocationString = $LocationUri.ToString()
        }
    }

    return $LocationString
}