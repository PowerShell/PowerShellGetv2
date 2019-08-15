function Uninstall-PSResource {
    [OutputType([void])]
    [cmdletbinding(SupportsShouldProcess = $true)]
    Param
    (
        # Specifies an array of resource names to uninstall.
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Name,

        # Accepts a PSRepositoryItemInfo object.
        # For example, output Get-InstalledModule to a variable and use that variable as the InputObject argument.
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'InputObject')]
        [ValidateNotNull()]
        [PSCustomObject[]]
        $InputObject,

        # Specifies the minimum version of the resource to uninstall (can't be used with the RequiredVersion or AllVersions parameter).
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNull()]
        [string]
        $MinimumVersion,

        # Specifies the exact version number of the reource to uninstall (can't be used with the MinimumVersion, MaximumVersion, or AllVersions parameter).
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        # Specifies the maximum, or newest, version of the resource to uninstall (can't be used with the RequiredVersion or AllVersions parameter).
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        # Specifies that you want to include all available versions of a module (can't be used with the MinimumVersion, MaximumVersion, or RequiredVersion parameter).
        [Parameter(ParameterSetName = 'NameParameterSet')]
        [switch]
        $AllVersions,

        # Uninstalls a resource without asking for user confirmation.
        [Parameter()]
        [Switch]
        $Force,

        # Allows a prerelease version to be uninstalled.
        [Parameter(ParameterSetName = 'NameParameterSet')]
        [switch]
        $Prerelease
    )

    begin { }
    process {
        foreach ($n in $Name) {
            if ($pscmdlet.ShouldProcess($n)) {

                if (Get-PSResource $n) {
                    # Uninstall the resource
                    Write-Verbose -message "Successfully uninstalled $n"
                }
            }
        }
    }
    end { }
}
