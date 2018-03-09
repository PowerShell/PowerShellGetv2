function Get-InstalledModuleDetails
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $RequiredVersion,

        [Parameter()]
        [string]
        $MinimumVersion,

        [Parameter()]
        [string]
        $MaximumVersion
    )

    Set-InstalledModulesVariable

    # Keys in $script:PSGetInstalledModules are "<ModuleName><ModuleVersion>",
    # first filter the installed modules using "$Name*" wildcard search
    # then apply $Name wildcard search to get the module name which meets the specified name with wildcards.
    #
    $wildcardPattern = New-Object System.Management.Automation.WildcardPattern "$Name*",$script:wildcardOptions
    $nameWildcardPattern = New-Object System.Management.Automation.WildcardPattern $Name,$script:wildcardOptions

    $script:PSGetInstalledModules.GetEnumerator() | Microsoft.PowerShell.Core\ForEach-Object {
                                                        if($wildcardPattern.IsMatch($_.Key))
                                                        {
                                                            $InstalledModuleDetails = $_.Value

                                                            if(-not $Name -or $nameWildcardPattern.IsMatch($InstalledModuleDetails.PSGetItemInfo.Name))
                                                            {

                                                                if (Test-ItemPrereleaseVersionRequirements -Version $InstalledModuleDetails.PSGetItemInfo.Version `
                                                                                                           -RequiredVersion $RequiredVersion `
                                                                                                           -MinimumVersion $MinimumVersion `
                                                                                                           -MaximumVersion $MaximumVersion)
                                                                {
                                                                    $InstalledModuleDetails
                                                                }
                                                            }
                                                        }
                                                    }
}