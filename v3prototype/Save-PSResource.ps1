# Saving resources
function Save-PSResource {
    [OutputType([void])]
    [cmdletbinding(SupportsShouldProcess = $true)]
    Param
    (
        # Specifies the exact names of resources to save from a repository.
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name,

        # Specifies the type of the resource being saved.
        [Parameter(ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateSet('Module', 'Script', 'Library')]
        [string[]]
        $Type,

        # Used for pipeline input.
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'InputObjectAndPathParameterSet')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'InputObjectAndLiteralPathParameterSet')]
        [ValidateNotNull()]
        [PSCustomObject[]]
        $InputObject,

        # Specifies the minimum version of the resource to be saved (cannot use this parameter with the RequiredVersion parameter).
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateNotNull()]
        [string]
        $MinimumVersion,

        # Specifies the maximum version of the resource to include to be saved (cannot use this parameter with the RequiredVersion parameter).
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        # Specifies the required version of the resource to include to be saved (cannot use this parameter with the MinimumVersion or MaximumVersion parameters).
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        # Specifies the repository to search within (default is all repositories).
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Repository,

        # Specifies the location on the local computer to store a saved resource. Accepts wildcard characters.
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'InputObjectAndPathParameterSet')]
        [string]
        $Path,

        # Specifies a path to one or more locations.
        # The value of the LiteralPath parameter is used exactly as entered. No characters are interpreted as wildcards.
        # If the path includes escape characters, enclose them in single quotation marks.
        # PowerShell does not interpret any characters enclosed in single quotation marks as escape sequences.
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'InputObjectAndLiteralPathParameterSet')]
        [Alias('PSPath')]
        [string]
        $LiteralPath,

        # Specifies a proxy server for the request, rather than connecting directly to an internet resource.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        # Specifies a user account that has permission to use the proxy server specified by the Proxy parameter.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $ProxyCredential,

        # Specifies a user account that has permission to save a resource from a specific repository.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        # Saves a resource without asking for user confirmation.
        [Parameter()]
        [switch]
        $Force,

        # Allows you to save a resource marked as a prerelease.
        [Parameter(ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [switch]
        $Prerelease,

        # Automatically accept the license agreement if the resoruce requires it.
        [Parameter()]
        [switch]
        $AcceptLicense,

        # Will save the resource as a nupkg (if it was originally a nupkg) instead of expanding it into a folder.
        [Parameter()]
        [switch]
        $AsNupkg,

        # Will explicitly retain the runtimes directory hierarchy within the nupkg to the root of the destination.
        [Parameter()]
        [switch]
        $IncludeAllRuntimes
    )


    begin { }
    process {
        foreach ($n in $Name) {
            if ($pscmdlet.ShouldProcess($n)) {

                if (Find-PSResource $n) {

                    # Save the resource-- use install logic
                    write-verbose -message "Successfully saved $n"
                }
            }
        }
    }
    end { }
}
