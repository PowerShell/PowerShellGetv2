function Get-PackageManagementProviderName
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Location
    )

    $PackageManagementProviderName = $null
    $loc = Get-LocationString -LocationUri $Location

    $providers = PackageManagement\Get-PackageProvider | Where-Object { $_.Features.ContainsKey($script:SupportsPSModulesFeatureName) }

    foreach($provider in $providers)
    {
        # Skip the PowerShellGet provider
        if($provider.ProviderName -eq $script:PSModuleProviderName)
        {
            continue
        }

        $packageSource = Get-PackageSource -Location $loc -Provider $provider.ProviderName  -ErrorAction SilentlyContinue

        if($packageSource)
        {
            $PackageManagementProviderName = $provider.ProviderName
            break
        }
    }

    return $PackageManagementProviderName
}