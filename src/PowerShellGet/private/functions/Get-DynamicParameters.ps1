function Get-DynamicParameters
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Location,

        [Parameter(Mandatory=$true)]
        [REF]
        $PackageManagementProvider
    )

    $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    $dynamicOptions = $null

    $loc = Get-LocationString -LocationUri $Location

    if(-not $loc)
    {
        return $paramDictionary
    }

    # Ping and resolve the specified location
    $loc = Resolve-Location -Location $loc `
                            -LocationParameterName 'Location' `
                            -ErrorAction SilentlyContinue `
                            -WarningAction SilentlyContinue
    if(-not $loc)
    {
        return $paramDictionary
    }

    $providers = PackageManagement\Get-PackageProvider | Where-Object { $_.Features.ContainsKey($script:SupportsPSModulesFeatureName) }

    if ($PackageManagementProvider.Value)
    {
        # Skip the PowerShellGet provider
        if($PackageManagementProvider.Value -ne $script:PSModuleProviderName)
        {
            $SelectedProvider = $providers | Where-Object {$_.ProviderName -eq $PackageManagementProvider.Value}

            if($SelectedProvider)
            {
                $res = Get-PackageSource -Location $loc -Provider $PackageManagementProvider.Value -ErrorAction SilentlyContinue

                if($res)
                {
                    $dynamicOptions = $SelectedProvider.DynamicOptions
                }
            }
        }
    }
    else
    {
        $PackageManagementProvider.Value = Get-PackageManagementProviderName -Location $Location
        if($PackageManagementProvider.Value)
        {
            $provider = $providers | Where-Object {$_.ProviderName -eq $PackageManagementProvider.Value}
            $dynamicOptions = $provider.DynamicOptions
        }
    }

    foreach ($option in $dynamicOptions)
    {
        # Skip the Destination parameter
        if( $option.IsRequired -and
            ($option.Name -eq "Destination") )
        {
            continue
        }

        $paramAttribute = New-Object System.Management.Automation.ParameterAttribute
        $paramAttribute.Mandatory = $option.IsRequired

        $message = $LocalizedData.DynamicParameterHelpMessage -f ($option.Name, $PackageManagementProvider.Value, $loc, $option.Name)
        $paramAttribute.HelpMessage = $message

        $attributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        $attributeCollection.Add($paramAttribute)

        $ageParam = New-Object System.Management.Automation.RuntimeDefinedParameter($option.Name,
                                                                                    $script:DynamicOptionTypeMap[$option.Type.value__],
                                                                                    $attributeCollection)
        $paramDictionary.Add($option.Name, $ageParam)
    }

    return $paramDictionary
}