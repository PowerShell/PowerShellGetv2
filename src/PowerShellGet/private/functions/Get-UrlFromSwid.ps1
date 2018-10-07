function Get-UrlFromSwid
{
    param
    (
        [Parameter(Mandatory=$true)]
        $SoftwareIdentity,

        [Parameter(Mandatory=$true)]
        $UrlName
    )

    foreach($link in $SoftwareIdentity.Links)
    {
        if( $link.Relationship -eq $UrlName)
        {
            return $link.HRef
        }
    }

    return $null
}