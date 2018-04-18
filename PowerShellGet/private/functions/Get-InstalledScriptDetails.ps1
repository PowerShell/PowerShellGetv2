function Get-InstalledScriptDetails
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

    Set-InstalledScriptsVariable

    # Keys in $script:PSGetInstalledScripts are "<ScriptName><ScriptVersion>",
    # first filter the installed scripts using "$Name*" wildcard search
    # then apply $Name wildcard search to get the script name which meets the specified name with wildcards.
    #
    $wildcardPattern = New-Object System.Management.Automation.WildcardPattern "$Name*",$script:wildcardOptions
    $nameWildcardPattern = New-Object System.Management.Automation.WildcardPattern $Name,$script:wildcardOptions

    $script:PSGetInstalledScripts.GetEnumerator() | Microsoft.PowerShell.Core\ForEach-Object {
                                                        if($wildcardPattern.IsMatch($_.Key))
                                                        {
                                                            $InstalledScriptDetails = $_.Value

                                                            if(-not $Name -or $nameWildcardPattern.IsMatch($InstalledScriptDetails.PSGetItemInfo.Name))
                                                            {
                                                                if (Test-ItemPrereleaseVersionRequirements -Version $InstalledScriptDetails.PSGetItemInfo.Version `
                                                                                                           -RequiredVersion $RequiredVersion `
                                                                                                           -MinimumVersion $MinimumVersion `
                                                                                                           -MaximumVersion $MaximumVersion)
                                                                {
                                                                    $InstalledScriptDetails
                                                                }
                                                            }
                                                        }
                                                    }
}