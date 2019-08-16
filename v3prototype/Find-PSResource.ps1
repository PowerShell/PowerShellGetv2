# Replaces: Find-Command, Find-DscResource, Find-Module, Find-RoleCapability, Find-Script
# Parameter Sets:  ResourceParameterSet, PackageParameterSet, ScriptParameterSet

# Find-Command returns an object with properties:  Name, Version, ModuleName, Repository
# Find-DSCResource returns an object with properties: Name, Version, ModuleName, Repository
# Find-RoleCapability returns an object with properties: Name, Version, ModuleName, Repository

# Find-Module returns an object with properties: Version, Name, Repository, Description
# Find-Script returns an object with properties: Version, Name, Repository, Description

function Find-PSResource {
    [OutputType([PSCustomObject[]])]
    [Cmdletbinding(SupportsShouldProcess = $true)]
    Param
    (
        # Specifies the name of the resource to be searched for.
        # Resources that use this param: Command, DSCResource, RoleCapability, Package, Script.
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name,

        # Specifies the type of the resource being searched.
        # Resources that use this param: Command, DSCResource, RoleCapability, Package, Script.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Module', 'Script', 'DscResource', 'RoleCapability', 'Command')]
        [string[]]
        $Type,

        # Specifies the module name that contains the resource.
        # Resources that use this param: Command, DSCResource, RoleCapability.
        [Parameter(ParameterSetName = "ResourceParameterSet")]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleName,

        # Specifies the minimum version of the resource to include in results (cannot use this parameter with the RequiredVersion or AllVersions parameters).
        # Resources that use this param: Command, DSCResource, RoleCapability, Package, Script.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $MinimumVersion,

        # Specifies the maximum version of the resource to include in results (cannot use this parameter with the RequiredVersion or AllVersions parameters).
        # Resources that use this param: Command, DSCResource, RoleCapability, Package, Script.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        # Specifies the required version of the resource to include in results (cannot use this parameter with the MinimumVersion, MaximumVersion, or AllVersions parameters).
        # Resources that use this param: Command, DSCResource, RoleCapability, Package, Script.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        # Displays each of a resource's available versions (cannot use this parameter with the MinimumVersion, MaximumVersion, or RequiredVersion parameters).
        # Resources that use this param: Command, DSCResource, RoleCapability, Package, Script.
        [Parameter()]
        [switch]
        $AllVersions,

        # Includes resources marked as a prerelease.
        # Resources that use this param: Command, DSCResource, RoleCapability, Package, Script.
        [Parameter()]
        [switch]
        $Prerelease,

        # Specifies tags that categorize modules in a repository.
        # Resources that use this param: Command, DSCResource, RoleCapability, Package, Script.
        [Parameter()]
        [ValidateNotNull()]
        [string[]]
        $Tag,

        # Finds resources based on ModuleName, Description, and Tag properties.
        # Resources that use this param: Command, DSCResource, RoleCapability, Package, Script.
        [Parameter()]
        [ValidateNotNull()]
        [string]
        $Filter,

        # Specifies a proxy server for the request, rather than a direct connection to the internet resource.
        # Resources that use this param: Command, DSCResource, RoleCapability, Package, Script.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        # Specifies a user account that has permission to use the proxy server that is specified by the Proxy parameter.
        # Resources that use this param: Command, DSCResource, RoleCapability, Package, Script.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $ProxyCredential,

        # Specifies the repository to search within (default is all repositories).
        # Resources that use this param: Command, DSCResource, RoleCapability, Package, Script.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Repository,

        # Specifies a user account that has rights to find a resource from a specific repository.
        # Resources that use this param: Package, Script.
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = "PackageParameterSet")]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = "ScriptParameterSet")]
        [PSCredential]
        $Credential,

        # Specifies to include all modules that are dependent upon the module specified in the Name parameter.
        # Resources that use this param: Package, Script.
        [Parameter(ParameterSetName = "PackageParameterSet")]
        [Parameter(ParameterSetName = "ScriptParameterSet")]
        [switch]
        $IncludeDependencies,

        # Returns only those modules that include specific kinds of PowerShell functionality. For example, you might only want to find modules that include DSCResource.
        # The acceptable values for this parameter are as follows:
        # Module: DscResource, Cmdlet, Function, RoleCapability;
        # Scripts: Function, Workflow;
        # Resources that use this param: Package, Script.
        [Parameter(ParameterSetName = "PackageParameterSet")]
        [Parameter(ParameterSetName = "ScriptParameterSet")]
        [ValidateNotNull()]
        [ValidateSet('DscResource', 'Cmdlet', 'Function', 'RoleCapability', 'Workflow')]
        [string[]]
        $Includes,

        # Specifies the name of the DSC resources contained within a module (per PowerShell conventions, performs an OR search when you provide multiple arguments).
        # Resources that use this param: Package.
        [Parameter(ParameterSetName = "PackageParameterSet")]
        [ValidateNotNull()]
        [string[]]
        $DscResource,

        # Specifies the name of the role capabilities contained within a module (per PowerShell conventions, performs an OR search when you provide multiple arguments).
        # Resources that use this param: Package.
        [Parameter(ParameterSetName = "PackageParameterSet")]
        [ValidateNotNull()]
        [string[]]
        $RoleCapability,

        # Specifies commands to find in modules (command can be a function or workflow).
        # Resources that use this param: Package, Script.
        [Parameter(ParameterSetName = "PackageParameterSet")]
        [Parameter(ParameterSetName = "ScriptParameterSet")]
        [ValidateNotNull()]
        [string[]]
        $Command

    )

    begin {
        # For each repository, if local cache does not exist then Update-PSResourceCache
    }
    process {

        # Returning the array of resources
        $foundResources

        foreach ($n in $name) {

            if ($pscmdlet.ShouldProcess($n)) {

                $PSResource = [PSCustomObject] @{
                    Name        = $Name
                    Version     = "placeholder-for-module-version"
                    Type        = $Type
                    Description = "placeholder-for-description"
                }

                $foundResources += $PSResource
            }
        }

        return $foundResources
    }
    end { }
}
