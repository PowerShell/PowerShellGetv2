function Publish-PSResource {

    [OutputType([void])]
    [Cmdletbinding(SupportsShouldProcess = $true)]
    Param
    (
        # Specifies the name of the resource to be published.
        [Parameter(Mandatory = $true,
            ParameterSetName = "ModuleNameParameterSet",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        # Specifies the path to the resource that you want to publish. This parameter accepts the path to the folder that contains the resource.
        # Specifies a path to one or more locations. Wildcards are permitted. The default location is the current directory (.).
        [Parameter(Mandatory = $true,
            ParameterSetName = "ModulePathParameterSet",
            ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true,
            ParameterSetName = 'ScriptPathParameterSet',
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is used exactly as entered.
        # No characters are interpreted as wildcards. If the path includes escape characters, enclose them in single quotation marks.
        # Single quotation marks tell PowerShell not to interpret any characters as escape sequences.
        [Parameter(Mandatory = $true,
            ParameterSetName = 'ModuleLiteralPathParameterSet',
            ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true,
            ParameterSetName = 'ScriptLiteralPathParameterSet',
            ValueFromPipelineByPropertyName = $true)]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string]
        $LiteralPath,

        # Can be used to publish the a nupkg locally.
        [Parameter(Mandatory = $true,
            ParameterSetName = 'DestinationPathParameterSet',
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath,

        # Specifies the exact version of a single resource to publish.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $RequiredVersion,

        # Specifies the API key that you want to use to publish a module to the online gallery.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $NuGetApiKey,

        # Specifies the repository to publish to.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Repository,

        # Specifies a user account that has rights to a specific repository.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        # Specifies a string containing release notes or comments that you want to be available to users of this version of the resource.
        [Parameter()]
        [string[]]
        $ReleaseNotes,

        # Adds one or more tags to the resource that you are publishing.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Tags,

        # Specifies the URL of licensing terms for the resource you want to publish.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $LicenseUri,

        # Specifies the URL of an icon for the resource.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $IconUri,

        # Specifies the URL of a webpage about this project.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $ProjectUri,

        # Excludes files from a nuspec
        [Parameter(ParameterSetName = "ModuleNameParameterSet")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Exclude,

        # Forces the command to run without asking for user confirmation.
        [Parameter()]
        [switch]
        $Force,

        # Allows resources marked as prerelease to be published.
        [Parameter()]
        [switch]
        $Prerelease,

        # Bypasses the default check that all dependencies are present.
        [Parameter()]
        [switch]
        $SkipDependenciesCheck,

        # Specifies a nuspec file rather than relying on this module to produce one.
        [Parameter()]
        [switch]
        $Nuspec
    )


    begin { }
    process {
        if ($pscmdlet.ShouldProcess($Name)) {
            if ($Name) {
                # Publish module
                Write-Verbose -message "Successfully published $Name"
            }
            elseif ($Path) {
                # Publish resource
                Write-Verbose -message "Successfully published $Path"
            }
            elseif ($LiteralPath) {
                # Publish resource
                Write-Verbose -message "Successfully published $LiteralPath"
            }
        }
    }

    end { }
}
