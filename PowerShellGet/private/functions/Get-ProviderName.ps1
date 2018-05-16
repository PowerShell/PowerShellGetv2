function Get-ProviderName
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $PSCustomObject
    )

    $providerName = $script:NuGetProviderName

    if((Get-Member -InputObject $PSCustomObject -Name PackageManagementProvider))
    {
        $providerName = $PSCustomObject.PackageManagementProvider
    }

    return $providerName
}