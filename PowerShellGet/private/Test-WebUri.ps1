function Test-WebUri
{
    [CmdletBinding()]
    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $uri
    )

    return ($uri.AbsoluteURI -ne $null) -and ($uri.Scheme -match '[http|https]')
}