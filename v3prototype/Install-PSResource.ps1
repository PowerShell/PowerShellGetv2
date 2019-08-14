# Replaces: Install-Module, Install-Script
# Parameter Sets: NameParameterSet, InputObject
# Install-PSResource will only work for modules unless -DestinationPath is specified which works for all resource types.
function Install-PSResource {
    [OutputType([void])]
    [cmdletbinding(SupportsShouldProcess = $true)]
    Param
    (
        # Specifies the exact names of resources to install from a repository.
        # A comma-separated list of module names is accepted. The resource name must match the resource name in the repository.
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name,

        # Used for pipeline input.
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'InputObject')]
        [ValidateNotNull()]
        [PSCustomObject[]]
        $InputObject,

        # The destination where the resource is to be installed. Works for all resource types.
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNull()]
        [string]
        $DestinationPath,

        # Specifies the minimum version of the resource to be installed (cannot use this parameter with the RequiredVersion parameter).
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNull()]
        [string]
        $MinimumVersion,

        # Specifies the maximum version of the resource to include to be installed (cannot use this parameter with the RequiredVersion parameter).
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        # Specifies the required version of the resource to include to be installed (cannot use this parameter with the MinimumVersion or MaximumVersion parameters).
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        # Allows installing prerelease versions
        [Parameter(ParameterSetName = 'NameParameterSet')]
        [switch]
        $Prerelease,

        # Specifies the repository to search within (default is all repositories).
        [Parameter(ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Repository,

        # If the resource requires dependencies that are not already installed, then a prompt will appear before anything is installed,
        # listing all the resources including module name, version, size, and repository to be installed
        # unless -IncludeDependencies is specified which will install without prompting.
        # Rejecting the prompt will result in nothing being installed.
        [Parameter()]
        [switch]
        $IncludeDependencies,

        # Accepts a path to a hashtable or json file.
        # Where the key is the module name and the value is either the required version specified using Nuget version range syntax or
        # a hash table where repository is set to the URL of the repository and version contains the Nuget version range syntax.
        # The json format will be the same as if this hashtable is passed to ConvertTo-Json.
        [Parameter(ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $RequiredResources,

        # Accepts a path to a psd1 or json file.
        # See above for json description.
        [Parameter(ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $RequiredResourcesFile,

        # Specifies the installation scope of the module. The acceptable values for this parameter are AllUsers and CurrentUser.  Default is CurrentUser.
        # The AllUsers scope installs modules in a location that is accessible to all users of the computer:
        # $env:ProgramFiles\PowerShell\Modules
        # The CurrentUser installs modules in a location that is accessible only to the current user of the computer:
        # $home\Documents\PowerShell\Modules
        # When no Scope is defined, the default is set based on the PowerShellGet version.
        # In PowerShellGet versions 2.0.0 and above, the default is CurrentUser, which does not require elevation for install.
        # In PowerShellGet 1.x versions, the default is AllUsers, which requires elevation for install.
        [Parameter()]
        [ValidateSet("CurrentUser", "AllUsers")]
        [string]
        $Scope,

        # Specifies a proxy server for the request, rather than connecting directly to the Internet resource.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        # Specifies a user account that has permission to use the proxy server that is specified by the Proxy parameter.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $ProxyCredential,

        # Specifies a user account that has rights to install a resource from a specific repository.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        # Overrides warning messages about installation conflicts about existing commands on a computer.
        # Overwrites existing commands that have the same name as commands being installed by a module. AllowClobber and Force can be used together in an Install-Module command.
        # Prevents installing modules that have the same cmdlets as a differently named module already
        [Parameter()]
        [switch]
        $NoClobber,

        # Suppresses being prompted if the publisher of the resource is different from the currently installed version.
        [Parameter()]
        [switch]
        $IgnoreDifferentPublisher,

        # Suppresses being prompted for untrusted sources.
        [Parameter()]
        [switch]
        $TrustRepository,

        # Overrides warning messages about resource installation conflicts.
        # If a resource with the same name already exists on the computer, Force allows for multiple versions to be installed.
        # If there is an existing resource with the same name and version, Force does NOT overwrite that version.
        [Parameter()]
        [switch]
        $Force,

        # Overwrites a previously installed resource with the same name and version.
        [Parameter()]
        [switch]
        $Reinstall,

        # Suppresses progress information.
        [Parameter()]
        [switch]
        $Quiet,

        # For modules that require a license, AcceptLicense automatically accepts the license agreement during installation.
        [Parameter()]
        [switch]
        $AcceptLicense,

        # Returns the resource as an object to the console.
        [Parameter()]
        [switch]
        $PassThru
    )

    begin { }
    process {
        foreach ($n in $Name) {
            if ($pscmdlet.ShouldProcess($n)) {

                if (Find-PSResource $n) {
                    # Install the resource
                    write-verbose -message "Successfully installed $n"
                }
            }
        }
    }
    end { }
}
