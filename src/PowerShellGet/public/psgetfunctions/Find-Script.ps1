function Find-Script {
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(HelpUri = 'https://go.microsoft.com/fwlink/?LinkId=619785')]
    [outputtype("PSCustomObject[]")]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $MinimumVersion,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        [Parameter()]
        [switch]
        $AllVersions,

        [Parameter()]
        [switch]
        $IncludeDependencies,

        [Parameter()]
        [ValidateNotNull()]
        [string]
        $Filter,

        [Parameter()]
        [ValidateNotNull()]
        [string[]]
        $Tag,

        [Parameter()]
        [ValidateNotNull()]
        [ValidateSet('Function', 'Workflow')]
        [string[]]
        $Includes,

        [Parameter()]
        [ValidateNotNull()]
        [string[]]
        $Command,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $ProxyCredential,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Repository,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        [Parameter()]
        [switch]
        $AllowPrerelease
    )

    Begin {
        # Change security protocol to TLS 1.2
        $script:securityProtocol = [Net.ServicePointManager]::SecurityProtocol
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        Install-NuGetClientBinaries -CallerPSCmdlet $PSCmdlet -Proxy $Proxy -ProxyCredential $ProxyCredential
    }

    Process {
        $ValidationResult = Validate-VersionParameters -CallerPSCmdlet $PSCmdlet `
            -Name $Name `
            -MinimumVersion $MinimumVersion `
            -MaximumVersion $MaximumVersion `
            -RequiredVersion $RequiredVersion `
            -AllVersions:$AllVersions `
            -AllowPrerelease:$AllowPrerelease

        if (-not $ValidationResult) {
            # Validate-VersionParameters throws the error.
            # returning to avoid further execution when different values are specified for -ErrorAction parameter
            return
        }

        $PSBoundParameters['Provider'] = $script:PSModuleProviderName
        $PSBoundParameters[$script:PSArtifactType] = $script:PSArtifactTypeScript
        if ($AllowPrerelease) {
            $PSBoundParameters[$script:AllowPrereleaseVersions] = $true
        }
        $null = $PSBoundParameters.Remove("AllowPrerelease")

        if ($PSBoundParameters.ContainsKey("Repository")) {
            $PSBoundParameters["Source"] = $Repository
            $null = $PSBoundParameters.Remove("Repository")

            $ev = $null
            $repositories = Get-PSRepository -Name $Repository -ErrorVariable ev -verbose:$false
            if ($ev) { return }

            $RepositoriesWithoutScriptSourceLocation = $false
            foreach ($repo in $repositories) {
                if (-not $repo.ScriptSourceLocation) {
                    $message = $LocalizedData.ScriptSourceLocationIsMissing -f ($repo.Name)
                    Write-Error -Message $message `
                        -ErrorId 'ScriptSourceLocationIsMissing' `
                        -Category InvalidArgument `
                        -TargetObject $repo.Name `
                        -Exception 'System.ArgumentException'

                    $RepositoriesWithoutScriptSourceLocation = $true
                }
            }

            if ($RepositoriesWithoutScriptSourceLocation) {
                return
            }
        }

        $PSBoundParameters["MessageResolver"] = $script:PackageManagementMessageResolverScriptBlockForScriptCmdlets

        $scriptsFoundInPSGallery = @()

        # No Telemetry must be performed if PSGallery is not in the supplied list of Repositories
        $isRepositoryNullOrPSGallerySpecified = $false
        if ($Repository -and ($Repository -Contains $Script:PSGalleryModuleSource)) {
            $isRepositoryNullOrPSGallerySpecified = $true
        }
        elseif (-not $Repository) {
            $psgalleryRepo = Get-PSRepository -Name $Script:PSGalleryModuleSource `
                -ErrorAction SilentlyContinue `
                -WarningAction SilentlyContinue
            # And check for IsDefault?
            if ($psgalleryRepo) {
                $isRepositoryNullOrPSGallerySpecified = $true
            }
        }

        PackageManagement\Find-Package @PSBoundParameters | Microsoft.PowerShell.Core\ForEach-Object {
            $psgetItemInfo = New-PSGetItemInfo -SoftwareIdentity $_ -Type $script:PSArtifactTypeScript

            if ($psgetItemInfo.Type -eq $script:PSArtifactTypeScript) {
                if ($AllVersions -and -not $AllowPrerelease) {
                    # If AllVersions is specified but not AllowPrerelease, we should only return stable release versions.
                    # PackageManagement returns ALL versions (including prerelease) when AllVersions is specified, regardless of the value of AllowPrerelease.
                    # Filtering results returned from PackageManagement based on flags.
                    if ($psgetItemInfo.AdditionalMetadata -and $psgetItemInfo.AdditionalMetadata.IsPrerelease -eq $false) {
                        $psgetItemInfo
                    }
                }
                else {
                    $psgetItemInfo
                }
            }
            elseif ($PSBoundParameters['Name'] -and -not (Test-WildcardPattern -Name ($Name | Microsoft.PowerShell.Core\Where-Object { $psgetItemInfo.Name -like $_ }))) {
                $message = $LocalizedData.MatchInvalidType -f ($psgetItemInfo.Name, $psgetItemInfo.Type, $script:PSArtifactTypeScript)
                Write-Error -Message $message `
                    -ErrorId 'MatchInvalidType' `
                    -Category InvalidArgument `
                    -TargetObject $Name
            }

            if ($psgetItemInfo -and
                $isRepositoryNullOrPSGallerySpecified -and
                $script:TelemetryEnabled -and
                ($psgetItemInfo.Repository -eq $Script:PSGalleryModuleSource)) {
                $scriptsFoundInPSGallery += $psgetItemInfo.Name
            }
        }

        # Perform Telemetry if Repository is not supplied or Repository contains PSGallery
        # We are only interested in finding artifacts not in PSGallery
        if ($isRepositoryNullOrPSGallerySpecified) {
            Log-ArtifactNotFoundInPSGallery -SearchedName $Name -FoundName $scriptsFoundInPSGallery -operationName PSGET_FIND_SCRIPT
        }
    }

    End {
        # Change back to user specified security protocol
        [Net.ServicePointManager]::SecurityProtocol = $script:securityProtocol
    }
}
