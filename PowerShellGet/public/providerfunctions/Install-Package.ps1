function Install-Package
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FastPackageReference
    )

    Write-Debug ($LocalizedData.ProviderApiDebugMessage -f ('Install-Package'))

    Install-PackageUtility -FastPackageReference $FastPackageReference -Request $Request
}