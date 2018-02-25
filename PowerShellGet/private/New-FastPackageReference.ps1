function New-FastPackageReference
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $ProviderName,

        [Parameter(Mandatory=$true)]
        [string]
        $PackageName,

        [Parameter(Mandatory=$true)]
        [string]
        $Version,

        [Parameter(Mandatory=$true)]
        [string]
        $Source,

        [Parameter(Mandatory=$true)]
        [string]
        $ArtifactType
    )

    return "$ProviderName|$PackageName|$Version|$Source|$ArtifactType"
}