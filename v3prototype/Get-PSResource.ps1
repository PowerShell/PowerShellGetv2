function Get-PSResource {
    [OutputType([PsCustomObject])]
    [cmdletbinding(SupportsShouldProcess = $true)]
    Param
    (
        # Specifies the resources to get.
        [Parameter(ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Name,

        # Specifies the type of resource to get.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Module', 'Script', 'Nupkg')]
        [string[]]
        $Type,

        # Specifies the minimum version of the resource to return (cannot use this parameter with the RequiredVersion or AllVersions parameters).
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $MinimumVersion,

        # Specifies the required version of the resource to return (cannot use this parameter with the MinimumVersion, MaximumVersion, or AllVersions parameters).
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        # Specifies the maximum version of the resource to return (cannot use this parameter with the RequiredVersion or AllVersions parameters).
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        # Displays all versions of the resource that have been installed (cannot use this parameter with the MinimumVersion, MaximumVersion, or RequiredVersion parameters).
        [Parameter()]
        [switch]
        $AllVersions,

        # Allows returning prerelease versions.
        [Parameter()]
        [switch]
        $Prerelease
    )


    begin { }
    process {
        foreach ($n in $Name) {
            if ($pscmdlet.ShouldProcess($n)) {
                $PSResource = New-Object PSObject -Property @{
                    Name                       = $Name
                    Version                    = "placeholder-for-module-version"
                    Type                       = "placeholder-for-type"
                    Description                = "placeholder-for-description"
                    Author                     = "placeholder-for-author"
                    CompanyName                = "placeholder-for-company-name"
                    Copyright                  = "placeholder-for-copyright"
                    PublishedDate              = "placeholder-for-published-date"
                    InstalledDate              = "placeholder-for-installed-date"
                    UpdatedDate                = "placeholder-for-updated-date"
                    LicenseUri                 = "placeholder-for-license-uri"
                    ProjectUri                 = "placeholder-for-project-uri"
                    IconUri                    = "placeholder-for-icon-uri"
                    Tags                       = "placeholder-for-tags"
                    Includes                   = "placeholder-for-includes"
                    PowerShellGetFormatVersion = "placeholder-for-powershellget-format-version"
                    ReleaseNotes               = "placeholder-for-release-notes"
                    Dependencies               = "placeholder-for-dependencies"
                    URL                        = "placeholder-for-url"
                    Repository                 = "placeholder-for-repository"  #???
                    AdditonalMetadata          = "placehodler-for-additional-metadata"
                }

                return $PSResource
            }
        }
    }
    end { }

}
