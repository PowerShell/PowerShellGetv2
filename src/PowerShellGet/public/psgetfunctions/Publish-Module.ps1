function Publish-Module {
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
        PositionalBinding = $false,
        HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=398575',
        DefaultParameterSetName = "ModuleNameParameterSet")]
    Param
    (
        [Parameter(Mandatory = $true,
            ParameterSetName = "ModuleNameParameterSet",
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(Mandatory = $true,
            ParameterSetName = "ModulePathParameterSet",
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(ParameterSetName = "ModuleNameParameterSet")]
        [ValidateNotNullOrEmpty()]
        [string]
        $RequiredVersion,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $NuGetApiKey,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Repository = $Script:PSGalleryModuleSource,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        [Parameter()]
        [ValidateSet("2.0")]
        [Version]
        $FormatVersion,

        [Parameter()]
        [string[]]
        $ReleaseNotes,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Tags,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $LicenseUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $IconUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $ProjectUri,

        [Parameter(ParameterSetName = "ModuleNameParameterSet")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Exclude,

        [Parameter()]
        [switch]
        $Force,

        [Parameter(ParameterSetName = "ModuleNameParameterSet")]
        [switch]
        $AllowPrerelease,

        [Parameter()]
        [switch]
        $SkipAutomaticTags
    )

    Begin {
        # Change security protocol to TLS 1.2
        $script:securityProtocol = [Net.ServicePointManager]::SecurityProtocol
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        if ($LicenseUri -and -not (Test-WebUri -uri $LicenseUri)) {
            $message = $LocalizedData.InvalidWebUri -f ($LicenseUri, "LicenseUri")
            ThrowError -ExceptionName "System.ArgumentException" `
                -ExceptionMessage $message `
                -ErrorId "InvalidWebUri" `
                -CallerPSCmdlet $PSCmdlet `
                -ErrorCategory InvalidArgument `
                -ExceptionObject $LicenseUri
        }

        if ($IconUri -and -not (Test-WebUri -uri $IconUri)) {
            $message = $LocalizedData.InvalidWebUri -f ($IconUri, "IconUri")
            ThrowError -ExceptionName "System.ArgumentException" `
                -ExceptionMessage $message `
                -ErrorId "InvalidWebUri" `
                -CallerPSCmdlet $PSCmdlet `
                -ErrorCategory InvalidArgument `
                -ExceptionObject $IconUri
        }

        if ($ProjectUri -and -not (Test-WebUri -uri $ProjectUri)) {
            $message = $LocalizedData.InvalidWebUri -f ($ProjectUri, "ProjectUri")
            ThrowError -ExceptionName "System.ArgumentException" `
                -ExceptionMessage $message `
                -ErrorId "InvalidWebUri" `
                -CallerPSCmdlet $PSCmdlet `
                -ErrorCategory InvalidArgument `
                -ExceptionObject $ProjectUri
        }

        Install-NuGetClientBinaries -CallerPSCmdlet $PSCmdlet -BootstrapNuGetExe -Force:$Force
    }

    Process {
        if ($Repository -eq $Script:PSGalleryModuleSource) {
            $moduleSource = Get-PSRepository -Name $Repository -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (-not $moduleSource) {
                $message = $LocalizedData.PSGalleryNotFound -f ($Repository)
                ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId 'PSGalleryNotFound' `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidArgument `
                    -ExceptionObject $Repository
                return
            }
        }
        else {
            $ev = $null
            $moduleSource = Get-PSRepository -Name $Repository -ErrorVariable ev
            if ($ev) { return }
        }

        $DestinationLocation = $moduleSource.PublishLocation

        if (-not $DestinationLocation -or
            (-not (Microsoft.PowerShell.Management\Test-Path $DestinationLocation) -and
                -not (Test-WebUri -uri $DestinationLocation))) {
            $message = $LocalizedData.PSGalleryPublishLocationIsMissing -f ($Repository, $Repository)
            ThrowError -ExceptionName "System.ArgumentException" `
                -ExceptionMessage $message `
                -ErrorId "PSGalleryPublishLocationIsMissing" `
                -CallerPSCmdlet $PSCmdlet `
                -ErrorCategory InvalidArgument `
                -ExceptionObject $Repository
        }

        $message = $LocalizedData.PublishLocation -f ($DestinationLocation)
        Write-Verbose -Message $message

        if (-not $NuGetApiKey.Trim()) {
            if (Microsoft.PowerShell.Management\Test-Path -Path $DestinationLocation) {
                $NuGetApiKey = "$(Get-Random)"
            }
            else {
                $message = $LocalizedData.NuGetApiKeyIsRequiredForNuGetBasedGalleryService -f ($Repository, $DestinationLocation)
                ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId "NuGetApiKeyIsRequiredForNuGetBasedGalleryService" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidArgument
            }
        }

        $providerName = Get-ProviderName -PSCustomObject $moduleSource
        if ($providerName -ne $script:NuGetProviderName) {
            $message = $LocalizedData.PublishModuleSupportsOnlyNuGetBasedPublishLocations -f ($moduleSource.PublishLocation, $Repository, $Repository)
            ThrowError -ExceptionName "System.ArgumentException" `
                -ExceptionMessage $message `
                -ErrorId "PublishModuleSupportsOnlyNuGetBasedPublishLocations" `
                -CallerPSCmdlet $PSCmdlet `
                -ErrorCategory InvalidArgument `
                -ExceptionObject $Repository
        }

        $moduleName = $null

        if ($Name) {
            if ($RequiredVersion) {
                $ValidationResult = Validate-VersionParameters -CallerPSCmdlet $PSCmdlet `
                    -Name $Name `
                    -RequiredVersion $RequiredVersion `
                    -AllowPrerelease:$AllowPrerelease
                if (-not $ValidationResult) {
                    # Validate-VersionParameters throws the error.
                    # returning to avoid further execution when different values are specified for -ErrorAction parameter
                    return
                }

                $reqResult = ValidateAndGet-VersionPrereleaseStrings -Version $RequiredVersion -CallerPSCmdlet $PSCmdlet
                if (-not $reqResult) {
                    # ValidateAndGet-VersionPrereleaseStrings throws the error.
                    # returning to avoid further execution when different values are specified for -ErrorAction parameter
                    return
                }
                $reqVersion = $reqResult["Version"]
                $reqPrerelease = $reqResult["Prerelease"]
            }
            else {
                $reqVersion = $null
                $reqPrerelease = $null
            }

            # Find the module to be published locally, search by name and RequiredVersion
            $module = Microsoft.PowerShell.Core\Get-Module -ListAvailable -Name $Name -Verbose:$false |
            Microsoft.PowerShell.Core\Where-Object {
                $modInfoPrerelease = $null
                if ($_.PrivateData -and
                    $_.PrivateData.GetType().ToString() -eq "System.Collections.Hashtable" -and
                    $_.PrivateData["PSData"] -and
                    $_.PrivateData.PSData.GetType().ToString() -eq "System.Collections.Hashtable" -and
                    $_.PrivateData.PSData["Prerelease"]) {
                    $modInfoPrerelease = $_.PrivateData.PSData.Prerelease
                }
                (-not $RequiredVersion) -or ( ($reqVersion -eq $_.Version) -and ($reqPrerelease -match $modInfoPrerelease) )
            }

            if (-not $module) {
                if ($RequiredVersion) {
                    $message = $LocalizedData.ModuleWithRequiredVersionNotAvailableLocally -f ($Name, $RequiredVersion)
                }
                else {
                    $message = $LocalizedData.ModuleNotAvailableLocally -f ($Name)
                }

                ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId "ModuleNotAvailableLocallyToPublish" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidArgument `
                    -ExceptionObject $Name

            }
            elseif ($module.GetType().ToString() -ne "System.Management.Automation.PSModuleInfo") {
                $message = $LocalizedData.AmbiguousModuleName -f ($Name)
                ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId "AmbiguousModuleNameToPublish" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidArgument `
                    -ExceptionObject $Name
            }

            $moduleName = $module.Name
            $Path = $module.ModuleBase
        }
        else {
            $resolvedPath = Resolve-PathHelper -Path $Path -CallerPSCmdlet $PSCmdlet | Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

            if (-not $resolvedPath -or
                -not (Microsoft.PowerShell.Management\Test-Path -Path $resolvedPath -PathType Container)) {
                ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage ($LocalizedData.PathIsNotADirectory -f ($Path)) `
                    -ErrorId "PathIsNotADirectory" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidArgument `
                    -ExceptionObject $Path
                return
            }

            $moduleName = Microsoft.PowerShell.Management\Split-Path -Path $resolvedPath -Leaf
            $modulePathWithVersion = $false

            # if the Leaf of the $resolvedPath is a version, use its parent folder name as the module name
            [Version]$ModuleVersion = $null
            if ([System.Version]::TryParse($moduleName, ([ref]$ModuleVersion))) {
                $moduleName = Microsoft.PowerShell.Management\Split-Path -Path (Microsoft.PowerShell.Management\Split-Path $resolvedPath -Parent) -Leaf
                $modulePathWithVersion = $true
            }

            $manifestPath = Join-PathUtility -Path $resolvedPath -ChildPath "$moduleName.psd1" -PathType File
            $module = $null

            if (Microsoft.PowerShell.Management\Test-Path -Path $manifestPath -PathType Leaf) {
                $ev = $null
                $module = Microsoft.PowerShell.Core\Test-ModuleManifest -Path $manifestPath `
                    -ErrorVariable ev `
                    -Verbose:$VerbosePreference
                if ($ev) {
                    # Above Test-ModuleManifest cmdlet should write an errors to the Errors stream and Console.
                    return
                }
            }
            elseif (-not $modulePathWithVersion -and ($PSVersionTable.PSVersion -ge '5.0.0')) {
                $module = Microsoft.PowerShell.Core\Get-Module -Name $resolvedPath -ListAvailable -ErrorAction SilentlyContinue -Verbose:$false
            }

            if (-not $module) {
                $message = $LocalizedData.InvalidModulePathToPublish -f ($Path)

                ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId 'InvalidModulePathToPublish' `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidArgument `
                    -ExceptionObject $Path
            }
            elseif ($module.GetType().ToString() -ne "System.Management.Automation.PSModuleInfo") {
                $message = $LocalizedData.AmbiguousModulePath -f ($Path)
                ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId 'AmbiguousModulePathToPublish' `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidArgument `
                    -ExceptionObject $Path
            }

            if ($module -and (-not $module.Path.EndsWith('.psd1', [System.StringComparison]::OrdinalIgnoreCase))) {
                $message = $LocalizedData.InvalidModuleToPublish -f ($module.Name)
                ThrowError -ExceptionName "System.InvalidOperationException" `
                    -ExceptionMessage $message `
                    -ErrorId "InvalidModuleToPublish" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidOperation `
                    -ExceptionObject $module.Name
            }

            $moduleName = $module.Name
            $Path = $module.ModuleBase
        }

        $message = $LocalizedData.PublishModuleLocation -f ($moduleName, $Path)
        Write-Verbose -Message $message

        #If users are providing tags using -Tags while running PS 5.0, will show warning messages
        if ($Tags) {
            $message = $LocalizedData.TagsShouldBeIncludedInManifestFile -f ($moduleName, $Path)
            Write-Warning $message
        }

        if ($ReleaseNotes) {
            $message = $LocalizedData.ReleaseNotesShouldBeIncludedInManifestFile -f ($moduleName, $Path)
            Write-Warning $message
        }

        if ($LicenseUri) {
            $message = $LocalizedData.LicenseUriShouldBeIncludedInManifestFile -f ($moduleName, $Path)
            Write-Warning $message
        }

        if ($IconUri) {
            $message = $LocalizedData.IconUriShouldBeIncludedInManifestFile -f ($moduleName, $Path)
            Write-Warning $message
        }

        if ($ProjectUri) {
            $message = $LocalizedData.ProjectUriShouldBeIncludedInManifestFile -f ($moduleName, $Path)
            Write-Warning $message
        }


        # Copy the source module to temp location to publish
        $tempModulePath = Microsoft.PowerShell.Management\Join-Path -Path $script:TempPath `
            -ChildPath "$(Microsoft.PowerShell.Utility\Get-Random)\$moduleName"


        if ($FormatVersion -eq "1.0") {
            $tempModulePathForFormatVersion = Microsoft.PowerShell.Management\Join-Path $tempModulePath "Content\Deployment\$script:ModuleReferences\$moduleName"
        }
        else {
            $tempModulePathForFormatVersion = $tempModulePath
        }

        $null = Microsoft.PowerShell.Management\New-Item -Path $tempModulePathForFormatVersion -ItemType Directory -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false

        # Copy-Item -Recurse -Force includes hidden items like .git directories, which we don't want
        # This finds all the items without force (leaving out hidden files and dirs) then copies them
        Microsoft.PowerShell.Management\Get-ChildItem $Path -recurse |
        Microsoft.PowerShell.Management\Copy-Item -Force -Confirm:$false -WhatIf:$false -Destination {
            if ($_.PSIsContainer) {
                Join-Path $tempModulePathForFormatVersion $_.Parent.FullName.substring($path.length)
            }
            else {
                join-path $tempModulePathForFormatVersion $_.FullName.Substring($path.Length)
            }
        }

        try {
            $manifestPath = Join-PathUtility -Path $tempModulePathForFormatVersion -ChildPath "$moduleName.psd1" -PathType File

            if (-not (Microsoft.PowerShell.Management\Test-Path $manifestPath)) {
                $message = $LocalizedData.InvalidModuleToPublish -f ($moduleName)
                ThrowError -ExceptionName "System.InvalidOperationException" `
                    -ExceptionMessage $message `
                    -ErrorId "InvalidModuleToPublish" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidOperation `
                    -ExceptionObject $moduleName
            }

            $ev = $null
            $moduleInfo = Microsoft.PowerShell.Core\Test-ModuleManifest -Path $manifestPath `
                -ErrorVariable ev `
                -Verbose:$VerbosePreference
            if ($ev) {
                # Above Test-ModuleManifest cmdlet should write an errors to the Errors stream and Console.
                return
            }

            if (-not $moduleInfo -or
                -not $moduleInfo.Author -or
                -not $moduleInfo.Description) {
                $message = $LocalizedData.MissingRequiredManifestKeys -f ($moduleName)
                ThrowError -ExceptionName "System.InvalidOperationException" `
                    -ExceptionMessage $message `
                    -ErrorId "MissingRequiredModuleManifestKeys" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidOperation `
                    -ExceptionObject $moduleName
            }

            # Validate Prerelease string
            $moduleInfoPrerelease = $null
            if ($moduleInfo.PrivateData -and
                $moduleInfo.PrivateData.GetType().ToString() -eq "System.Collections.Hashtable" -and
                $moduleInfo.PrivateData["PSData"] -and
                $moduleInfo.PrivateData.PSData.GetType().ToString() -eq "System.Collections.Hashtable" -and
                $moduleInfo.PrivateData.PSData["Prerelease"]) {
                $moduleInfoPrerelease = $moduleInfo.PrivateData.PSData.Prerelease
            }

            $result = ValidateAndGet-VersionPrereleaseStrings -Version $moduleInfo.Version -Prerelease $moduleInfoPrerelease -CallerPSCmdlet $PSCmdlet
            if (-not $result) {
                # ValidateAndGet-VersionPrereleaseStrings throws the error.
                # returning to avoid further execution when different values are specified for -ErrorAction parameter
                return
            }
            $moduleInfoVersion = $result["Version"]
            $moduleInfoPrerelease = $result["Prerelease"]
            $moduleInfoFullVersion = $result["FullVersion"]

            $FindParameters = @{
                Name            = $moduleName
                Repository      = $Repository
                Tag             = 'PSScript'
                AllowPrerelease = $true
                Verbose         = $VerbosePreference
                ErrorAction     = 'SilentlyContinue'
                WarningAction   = 'SilentlyContinue'
                Debug           = $DebugPreference
            }

            if ($Credential) {
                $FindParameters[$script:Credential] = $Credential
            }

            # Check if the specified module name is already used for a script on the specified repository
            # Use Find-Script to check if that name is already used as scriptname
            $scriptPSGetItemInfo = Find-Script @FindParameters |
            Microsoft.PowerShell.Core\Where-Object { $_.Name -eq $moduleName } |
            Microsoft.PowerShell.Utility\Select-Object -Last 1 -ErrorAction Ignore
            if ($scriptPSGetItemInfo) {
                $message = $LocalizedData.SpecifiedNameIsAlearyUsed -f ($moduleName, $Repository, 'Find-Script')
                ThrowError -ExceptionName "System.InvalidOperationException" `
                    -ExceptionMessage $message `
                    -ErrorId "SpecifiedNameIsAlearyUsed" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidOperation `
                    -ExceptionObject $moduleName
            }

            $null = $FindParameters.Remove('Tag')
            $currentPSGetItemInfo = Find-Module @FindParameters |
            Microsoft.PowerShell.Core\Where-Object { $_.Name -eq $moduleInfo.Name } |
            Microsoft.PowerShell.Utility\Select-Object -Last 1 -ErrorAction Ignore

            if ($currentPSGetItemInfo) {
                $result = ValidateAndGet-VersionPrereleaseStrings -Version $currentPSGetItemInfo.Version -CallerPSCmdlet $PSCmdlet
                if (-not $result) {
                    # ValidateAndGet-VersionPrereleaseStrings throws the error.
                    # returning to avoid further execution when different values are specified for -ErrorAction parameter
                    return
                }
                $currentPSGetItemVersion = $result["Version"]
                $currentPSGetItemPrereleaseString = $result["Prerelease"]
                $currentPSGetItemFullVersion = $result["FullVersion"]

                if ($currentPSGetItemVersion -eq $moduleInfoVersion) {
                    # Compare Prerelease strings
                    if (-not $currentPSGetItemPrereleaseString -and -not $moduleInfoPrerelease) {
                        $message = $LocalizedData.ModuleVersionIsAlreadyAvailableInTheGallery -f ($moduleInfo.Name, $moduleInfoFullVersion, $currentPSGetItemFullVersion, $currentPSGetItemInfo.RepositorySourceLocation)
                        ThrowError -ExceptionName 'System.InvalidOperationException' `
                            -ExceptionMessage $message `
                            -ErrorId 'ModuleVersionIsAlreadyAvailableInTheGallery' `
                            -CallerPSCmdlet $PSCmdlet `
                            -ErrorCategory InvalidOperation
                    }
                    elseif (-not $Force -and (-not $currentPSGetItemPrereleaseString -and $moduleInfoPrerelease)) {
                        # User is trying to publish a new Prerelease version AFTER publishing the stable version.
                        $message = $LocalizedData.ModuleVersionShouldBeGreaterThanGalleryVersion -f ($moduleInfo.Name, $moduleInfoFullVersion, $currentPSGetItemFullVersion, $currentPSGetItemInfo.RepositorySourceLocation)
                        ThrowError -ExceptionName "System.InvalidOperationException" `
                            -ExceptionMessage $message `
                            -ErrorId "ModuleVersionShouldBeGreaterThanGalleryVersion" `
                            -CallerPSCmdlet $PSCmdlet `
                            -ErrorCategory InvalidOperation
                    }

                    # elseif ($currentPSGetItemPrereleaseString -and -not $moduleInfoPrerelease) --> allow publish
                    # User is attempting to publish a stable version after publishing a Prerelease version (allowed).

                    elseif ($currentPSGetItemPrereleaseString -and $moduleInfoPrerelease) {
                        if ($currentPSGetItemPrereleaseString -eq $moduleInfoPrerelease) {
                            $message = $LocalizedData.ModuleVersionIsAlreadyAvailableInTheGallery -f ($moduleInfo.Name, $moduleInfoFullVersion, $currentPSGetItemFullVersion, $currentPSGetItemInfo.RepositorySourceLocation)
                            ThrowError -ExceptionName 'System.InvalidOperationException' `
                                -ExceptionMessage $message `
                                -ErrorId 'ModuleVersionIsAlreadyAvailableInTheGallery' `
                                -CallerPSCmdlet $PSCmdlet `
                                -ErrorCategory InvalidOperation
                        }

                        elseif (-not $Force -and ($currentPSGetItemPrereleaseString -gt $moduleInfoPrerelease)) {
                            $message = $LocalizedData.ModuleVersionShouldBeGreaterThanGalleryVersion -f ($moduleInfo.Name, $moduleInfoFullVersion, $currentPSGetItemFullVersion, $currentPSGetItemInfo.RepositorySourceLocation)
                            ThrowError -ExceptionName "System.InvalidOperationException" `
                                -ExceptionMessage $message `
                                -ErrorId "ModuleVersionShouldBeGreaterThanGalleryVersion" `
                                -CallerPSCmdlet $PSCmdlet `
                                -ErrorCategory InvalidOperation
                        }

                        # elseif ($currentPSGetItemPrereleaseString -lt $moduleInfoPrerelease) --> allow publish
                    }
                }
                elseif (-not $Force -and (Compare-PrereleaseVersions -FirstItemVersion $moduleInfoVersion `
                            -FirstItemPrerelease $moduleInfoPrerelease `
                            -SecondItemVersion $currentPSGetItemVersion `
                            -SecondItemPrerelease $currentPSGetItemPrereleaseString)) {
                    $message = $LocalizedData.ModuleVersionShouldBeGreaterThanGalleryVersion -f ($moduleInfo.Name, $moduleInfoVersion, $currentPSGetItemFullVersion, $currentPSGetItemInfo.RepositorySourceLocation)
                    ThrowError -ExceptionName "System.InvalidOperationException" `
                        -ExceptionMessage $message `
                        -ErrorId "ModuleVersionShouldBeGreaterThanGalleryVersion" `
                        -CallerPSCmdlet $PSCmdlet `
                        -ErrorCategory InvalidOperation
                }

                # else ($currentPSGetItemVersion -lt $moduleInfoVersion) --> allow publish
            }

            $shouldProcessMessage = $LocalizedData.PublishModulewhatIfMessage -f ($moduleInfo.Version, $moduleInfo.Name)
            if ($Force -or $PSCmdlet.ShouldProcess($shouldProcessMessage, "Publish-Module")) {
                $PublishPSArtifactUtility_Params = @{
                    PSModuleInfo      = $moduleInfo
                    ManifestPath      = $manifestPath
                    NugetApiKey       = $NuGetApiKey
                    Destination       = $DestinationLocation
                    Repository        = $Repository
                    NugetPackageRoot  = $tempModulePath
                    FormatVersion     = $FormatVersion
                    ReleaseNotes      = $($ReleaseNotes -join "`r`n")
                    Tags              = $Tags
                    SkipAutomaticTags = $SkipAutomaticTags
                    LicenseUri        = $LicenseUri
                    IconUri           = $IconUri
                    ProjectUri        = $ProjectUri
                    Verbose           = $VerbosePreference
                    WarningAction     = $WarningPreference
                    ErrorAction       = $ErrorActionPreference
                    Debug             = $DebugPreference
                }
                if ($PSBoundParameters.Containskey('Credential')) {
                    $PublishPSArtifactUtility_Params.Add('Credential', $Credential)
                }
                if ($Exclude) {
                    $PublishPSArtifactUtility_Params.Add('Exclude', $Exclude)
                }
                Publish-PSArtifactUtility @PublishPSArtifactUtility_Params
            }
        }
        finally {
            Microsoft.PowerShell.Management\Remove-Item $tempModulePath -Force -Recurse -ErrorAction Ignore -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
        }
    }

    End {
        # Change back to user specified security protocol
        [Net.ServicePointManager]::SecurityProtocol = $script:securityProtocol
    }
}
