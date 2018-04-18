function Download-Package
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FastPackageReference,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Location
    )

    Write-Debug ($LocalizedData.ProviderApiDebugMessage -f ('Download-Package'))

    Install-PackageUtility -FastPackageReference $FastPackageReference -Request $Request -Location $Location
}