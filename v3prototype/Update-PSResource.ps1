# Updating resources
function Update-PSResource {
    [OutputType([void])]
    [cmdletbinding(SupportsShouldProcess = $true)]
    Param
    (
        # Specifies the names of one or more modules to update.
        [Parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Name,

        # Specifies the required version of the resource to include to be updated (cannot use this parameter with the MaximumVersion or UpdateTo parameters).
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        # Specifies the required version of the resource to include to be updated (cannot use this parameter with the RequiredVersion or UpdateTo parameters).
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        # Allows updating to latest path version, minor version, or major version (cannot use this parameter with the MaximumVersion or RequiredVersion parameters).
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("PatchVersion", "MinorVersion", "MajorVersion")]
        [string]
        $UpdateTo,

        # Specifies a user account that has permission to save a resource from a specific repository.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        # Saves a resource without asking for user confirmation.
        [Parameter()]
        [ValidateSet("CurrentUser", "AllUsers")]
        [string]
        $Scope,

        # Specifies a proxy server for the request, rather than connecting directly to an internet resource.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        # Specifies a user account that has permission to use the proxy server specified by the Proxy parameter.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $ProxyCredential,

        # Updates a resource without asking for user confirmation.
        [Parameter()]
        [Switch]
        $Force,

        # Allows an update to a prerelease version.
        [Parameter()]
        [Switch]
        $Prerelease,

        # Automatically accept the license agreement if the resoruce requires it.
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

                if (Get-InstalledResource $n) {
                    # Use install logic to update resource
                    write-verbose -message "Successfully updated $n"
                }
            }
        }
    }
    end { }

}
