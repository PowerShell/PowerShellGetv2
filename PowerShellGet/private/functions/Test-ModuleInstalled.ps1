function Test-ModuleInstalled
{
    [CmdletBinding(PositionalBinding=$false)]
    [OutputType("PSModuleInfo")]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $RequiredVersion
    )

    # Check if module is already installed
    $availableModule = Microsoft.PowerShell.Core\Get-Module -ListAvailable -Name $Name -Verbose:$false |
                           Microsoft.PowerShell.Core\Where-Object {
                               -not (Test-ModuleSxSVersionSupport) `
                               -or (-not $RequiredVersion) `
                               -or ($RequiredVersion.Trim() -eq $_.Version.ToString()) `
                               -or (Test-ItemPrereleaseVersionRequirements -Version $_.Version -RequiredVersion $RequiredVersion)
                            } | Microsoft.PowerShell.Utility\Select-Object -Unique -First 1 -ErrorAction Ignore

    return $availableModule
}