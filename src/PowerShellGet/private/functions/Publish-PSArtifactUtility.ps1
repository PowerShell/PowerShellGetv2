function Publish-PSArtifactUtility {
    [CmdletBinding(PositionalBinding = $false)]
    Param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'PublishModule')]
        [ValidateNotNullOrEmpty()]
        [PSModuleInfo]
        $PSModuleInfo,

        [Parameter(Mandatory = $true, ParameterSetName = 'PublishScript')]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]
        $PSScriptInfo,

        [Parameter(Mandatory = $true, ParameterSetName = 'PublishModule')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ManifestPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Destination,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Repository,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NugetApiKey,

        [Parameter(Mandatory = $false)]
        [pscredential]
        $Credential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NugetPackageRoot,

        [Parameter(ParameterSetName = 'PublishModule')]
        [Version]
        $FormatVersion,

        [Parameter(ParameterSetName = 'PublishModule')]
        [string]
        $ReleaseNotes,

        [Parameter(ParameterSetName = 'PublishModule')]
        [string[]]
        $Tags,

        [Parameter(ParameterSetName = 'PublishModule')]
        [switch]
        $SkipAutomaticTags,

        [Parameter(ParameterSetName = 'PublishModule')]
        [Uri]
        $LicenseUri,

        [Parameter(ParameterSetName = 'PublishModule')]
        [Uri]
        $IconUri,

        [Parameter(ParameterSetName = 'PublishModule')]
        [Uri]
        $ProjectUri,

        [Parameter(ParameterSetName = 'PublishModule')]
        [string[]]
        $Exclude
    )

    Write-Verbose "Calling Publish-PSArtifactUtility"
    Install-NuGetClientBinaries -CallerPSCmdlet $PSCmdlet -BootstrapNuGetExe

    $PSArtifactType = $script:PSArtifactTypeModule
    $Name = $null
    $Description = $null
    $Version = ""
    $Author = $null
    $CompanyName = $null
    $Copyright = $null
    $requireLicenseAcceptance = "false"

    if ($PSModuleInfo) {
        $Name = $PSModuleInfo.Name
        $Description = $PSModuleInfo.Description
        $Version = $PSModuleInfo.Version
        $Author = $PSModuleInfo.Author
        $CompanyName = $PSModuleInfo.CompanyName
        $Copyright = $PSModuleInfo.Copyright

        if ($PSModuleInfo.PrivateData -and
            ($PSModuleInfo.PrivateData.GetType().ToString() -eq "System.Collections.Hashtable") -and
            $PSModuleInfo.PrivateData["PSData"] -and
            ($PSModuleInfo.PrivateData["PSData"].GetType().ToString() -eq "System.Collections.Hashtable")
        ) {
            if ( -not $Tags -and $PSModuleInfo.PrivateData.PSData["Tags"]) {
                $Tags = $PSModuleInfo.PrivateData.PSData.Tags
            }

            if ( -not $ReleaseNotes -and $PSModuleInfo.PrivateData.PSData["ReleaseNotes"]) {
                $ReleaseNotes = $PSModuleInfo.PrivateData.PSData.ReleaseNotes
            }

            if ( -not $LicenseUri -and $PSModuleInfo.PrivateData.PSData["LicenseUri"]) {
                $LicenseUri = $PSModuleInfo.PrivateData.PSData.LicenseUri
            }

            if ( -not $IconUri -and $PSModuleInfo.PrivateData.PSData["IconUri"]) {
                $IconUri = $PSModuleInfo.PrivateData.PSData.IconUri
            }

            if ( -not $ProjectUri -and $PSModuleInfo.PrivateData.PSData["ProjectUri"]) {
                $ProjectUri = $PSModuleInfo.PrivateData.PSData.ProjectUri
            }

            if ($PSModuleInfo.PrivateData.PSData["Prerelease"]) {
                $psmoduleInfoPrereleaseString = $PSModuleInfo.PrivateData.PSData.Prerelease
                if ($psmoduleInfoPrereleaseString -and $psmoduleInfoPrereleaseString.StartsWith("-")) {
                    $Version = [string]$Version + $psmoduleInfoPrereleaseString
                }
                else {
                    $Version = [string]$Version + "-" + $psmoduleInfoPrereleaseString
                }
            }

            if ($PSModuleInfo.PrivateData.PSData["RequireLicenseAcceptance"]) {
                $requireLicenseAcceptance = $PSModuleInfo.PrivateData.PSData.requireLicenseAcceptance.ToString().ToLower()
                if ($requireLicenseAcceptance -eq "true") {
                    if ($FormatVersion -and ($FormatVersion.Major -lt $script:PSGetRequireLicenseAcceptanceFormatVersion.Major)) {
                        $message = $LocalizedData.requireLicenseAcceptanceNotSupported -f ($FormatVersion)
                        ThrowError -ExceptionName "System.InvalidOperationException" `
                            -ExceptionMessage $message `
                            -ErrorId "requireLicenseAcceptanceNotSupported" `
                            -CallerPSCmdlet $PSCmdlet `
                            -ErrorCategory InvalidData
                    }

                    if (-not $LicenseUri) {
                        $message = $LocalizedData.LicenseUriNotSpecified
                        ThrowError -ExceptionName "System.InvalidOperationException" `
                            -ExceptionMessage $message `
                            -ErrorId "LicenseUriNotSpecified" `
                            -CallerPSCmdlet $PSCmdlet `
                            -ErrorCategory InvalidData
                    }

                    $LicenseFilePath = Join-PathUtility -Path $NugetPackageRoot -ChildPath 'License.txt' -PathType File
                    if (-not $LicenseFilePath -or -not (Test-Path -Path $LicenseFilePath -PathType Leaf)) {
                        $message = $LocalizedData.LicenseTxtNotFound
                        ThrowError -ExceptionName "System.InvalidOperationException" `
                            -ExceptionMessage $message `
                            -ErrorId "LicenseTxtNotFound" `
                            -CallerPSCmdlet $PSCmdlet `
                            -ErrorCategory InvalidData
                    }

                    if ((Get-Content -LiteralPath $LicenseFilePath) -eq $null) {
                        $message = $LocalizedData.LicenseTxtEmpty
                        ThrowError -ExceptionName "System.InvalidOperationException" `
                            -ExceptionMessage $message `
                            -ErrorId "LicenseTxtEmpty" `
                            -CallerPSCmdlet $PSCmdlet `
                            -ErrorCategory InvalidData
                    }

                    #RequireLicenseAcceptance is true, License uri and license.txt exist. Bump Up the FormatVersion
                    if (-not $FormatVersion) {
                        $FormatVersion = $script:CurrentPSGetFormatVersion
                    }
                }
                elseif ($requireLicenseAcceptance -ne "false") {
                    $InvalidValueForRequireLicenseAcceptance = $LocalizedData.InvalidValueBoolean -f ($requireLicenseAcceptance, "requireLicenseAcceptance")
                    Write-Warning -Message $InvalidValueForRequireLicenseAcceptance
                }
            }
        }
    }
    else {
        $PSArtifactType = $script:PSArtifactTypeScript

        $Name = $PSScriptInfo.Name
        $Description = $PSScriptInfo.Description
        $Version = $PSScriptInfo.Version
        $Author = $PSScriptInfo.Author
        $CompanyName = $PSScriptInfo.CompanyName
        $Copyright = $PSScriptInfo.Copyright

        if ($PSScriptInfo.'Tags') {
            $Tags = $PSScriptInfo.Tags
        }

        if ($PSScriptInfo.'ReleaseNotes') {
            $ReleaseNotes = $PSScriptInfo.ReleaseNotes
        }

        if ($PSScriptInfo.'LicenseUri') {
            $LicenseUri = $PSScriptInfo.LicenseUri
        }

        if ($PSScriptInfo.'IconUri') {
            $IconUri = $PSScriptInfo.IconUri
        }

        if ($PSScriptInfo.'ProjectUri') {
            $ProjectUri = $PSScriptInfo.ProjectUri
        }
    }

    $nuspecFiles = ""
    if ($Exclude) {
        $nuspecFileExcludePattern = $Exclude -Join ";"
        $nuspecFiles = @{ src = "**/*.*"; exclude = $nuspecFileExcludePattern }
    }

    # Add PSModule and PSGet format version tags
    if (-not $Tags) {
        $Tags = @()
    }

    if ($FormatVersion) {
        $Tags += "$($script:PSGetFormatVersion)_$FormatVersion"
    }

    $DependentModuleDetails = @()

    if ($PSScriptInfo) {
        $Tags += "PSScript"

        if ($PSScriptInfo.DefinedCommands -and -not $SkipAutomaticTags) {
            if ($PSScriptInfo.DefinedFunctions) {
                $Tags += "$($script:Includes)_Function"
                $Tags += $PSScriptInfo.DefinedFunctions | Microsoft.PowerShell.Core\ForEach-Object { "$($script:Function)_$_" }
            }

            if ($PSScriptInfo.DefinedWorkflows) {
                $Tags += "$($script:Includes)_Workflow"
                $Tags += $PSScriptInfo.DefinedWorkflows | Microsoft.PowerShell.Core\ForEach-Object { "$($script:Workflow)_$_" }
            }

            $Tags += $PSScriptInfo.DefinedCommands | Microsoft.PowerShell.Core\ForEach-Object { "$($script:Command)_$_" }
        }

        # Populate the dependencies elements from RequiredModules and RequiredScripts
        #
        $ValidateAndGetScriptDependencies_Params = @{
            Repository          = $Repository
            DependentScriptInfo = $PSScriptInfo
            CallerPSCmdlet      = $PSCmdlet
            Verbose             = $VerbosePreference
            Debug               = $DebugPreference
        }
        if ($PSBoundParameters.ContainsKey('Credential')) {
            $ValidateAndGetScriptDependencies_Params.Add('Credential', $Credential)
        }
        $DependentModuleDetails += ValidateAndGet-ScriptDependencies @ValidateAndGetScriptDependencies_Params
    }
    else {
        $Tags += "PSModule"

        $ModuleManifestHashTable = Get-ManifestHashTable -Path $ManifestPath

        if (-not $SkipAutomaticTags) {
            if ($PSModuleInfo.ExportedCommands.Count) {
                if ($PSModuleInfo.ExportedCmdlets.Count) {
                    $Tags += "$($script:Includes)_Cmdlet"
                    $Tags += $PSModuleInfo.ExportedCmdlets.Keys | Microsoft.PowerShell.Core\ForEach-Object { "$($script:Cmdlet)_$_" }

                    #if CmdletsToExport field in manifest file is "*", we suggest the user to include all those cmdlets for best practice
                    if ($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey('CmdletsToExport') -and ($ModuleManifestHashTable.CmdletsToExport -eq "*")) {
                        $WarningMessage = $LocalizedData.ShouldIncludeCmdletsToExport -f ($ManifestPath)
                        Write-Warning -Message $WarningMessage
                    }
                }

                if ($PSModuleInfo.ExportedFunctions.Count) {
                    $Tags += "$($script:Includes)_Function"
                    $Tags += $PSModuleInfo.ExportedFunctions.Keys | Microsoft.PowerShell.Core\ForEach-Object { "$($script:Function)_$_" }

                    if ($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey('FunctionsToExport') -and ($ModuleManifestHashTable.FunctionsToExport -eq "*")) {
                        $WarningMessage = $LocalizedData.ShouldIncludeFunctionsToExport -f ($ManifestPath)
                        Write-Warning -Message $WarningMessage
                    }
                }

                $Tags += $PSModuleInfo.ExportedCommands.Keys | Microsoft.PowerShell.Core\ForEach-Object { "$($script:Command)_$_" }
            }

            $dscResourceNames = Get-ExportedDscResources -PSModuleInfo $PSModuleInfo
            if ($dscResourceNames) {
                $Tags += "$($script:Includes)_DscResource"

                $Tags += $dscResourceNames | Microsoft.PowerShell.Core\ForEach-Object { "$($script:DscResource)_$_" }

                #If DscResourcesToExport is commented out or "*" is used, we will write-warning
                if ($ModuleManifestHashTable -and
                    ($ModuleManifestHashTable.ContainsKey("DscResourcesToExport") -and
                        $ModuleManifestHashTable.DscResourcesToExport -eq "*") -or
                    -not $ModuleManifestHashTable.ContainsKey("DscResourcesToExport")) {
                    $WarningMessage = $LocalizedData.ShouldIncludeDscResourcesToExport -f ($ManifestPath)
                    Write-Warning -Message $WarningMessage
                }
            }

            $RoleCapabilityNames = Get-AvailableRoleCapabilityName -PSModuleInfo $PSModuleInfo
            if ($RoleCapabilityNames) {
                $Tags += "$($script:Includes)_RoleCapability"

                $Tags += $RoleCapabilityNames | Microsoft.PowerShell.Core\ForEach-Object { "$($script:RoleCapability)_$_" }
            }
        }

        # Populate the module dependencies elements from RequiredModules and
        # NestedModules properties of the current PSModuleInfo
        $GetModuleDependencies_Params = @{
            PSModuleInfo   = $PSModuleInfo
            Repository     = $Repository
            CallerPSCmdlet = $PSCmdlet
            Verbose        = $VerbosePreference
            Debug          = $DebugPreference
        }
        if ($PSBoundParameters.ContainsKey('Credential')) {
            $GetModuleDependencies_Params.Add('Credential', $Credential)
        }
        $DependentModuleDetails = Get-ModuleDependencies @GetModuleDependencies_Params
    }

    $dependencies = @()
    ForEach ($Dependency in $DependentModuleDetails) {
        $ModuleName = $Dependency.Name
        $VersionString = ""

        # Version format in NuSpec:
        # "[2.0]" --> (== 2.0) Required Version
        # "2.0" --> (>= 2.0) Minimum Version
        #
        # When only MaximumVersion is specified in the ModuleSpecification
        # (,1.0]  = x <= 1.0
        #
        # When both Minimum and Maximum versions are specified in the ModuleSpecification
        # [1.0,2.0] = 1.0 <= x <= 2.0

        if ($Dependency.Keys -Contains "RequiredVersion") {
            $VersionString = "[$($Dependency.RequiredVersion)]"
        }
        elseif ($Dependency.Keys -Contains 'MinimumVersion' -and $Dependency.Keys -Contains 'MaximumVersion') {
            $VersionString = "[$($Dependency.MinimumVersion),$($Dependency.MaximumVersion)]"
        }
        elseif ($Dependency.Keys -Contains 'MaximumVersion') {
            $VersionString = "(,$($Dependency.MaximumVersion)]"
        }
        elseif ($Dependency.Keys -Contains 'MinimumVersion') {
            $VersionString = "$($Dependency.MinimumVersion)"
        }

        $props = @{
            id      = $ModuleName
            version = $VersionString
        }

        $dependencyObject = New-Object -TypeName PSCustomObject -Property $props
        $dependencies += $dependencyObject
    }

    $params = @{
        OutputPath               = $NugetPackageRoot
        Id                       = $Name
        Version                  = $Version
        Authors                  = $Author
        Owners                   = $CompanyName
        Description              = $Description
        ReleaseNotes             = $ReleaseNotes
        RequireLicenseAcceptance = ($requireLicenseAcceptance -eq $true)
        Copyright                = $Copyright
        Tags                     = $Tags
        LicenseUrl               = $LicenseUri
        ProjectUrl               = $ProjectUri
        IconUrl                  = $IconUri
        Dependencies             = $dependencies
    }

    if ($nuspecFiles) {
        $params.Add('Files', $nuspecFiles)
    }

    try {
        $NuspecFullName = New-NuspecFile @params
    }
    catch {
        Write-Error -Message "Failed to create nuspec file $_.Exception" -ErrorAction Stop
    }

    try {
        if ($DotnetCommandPath) {
            $NupkgFullName = New-NugetPackage -NuspecPath $NuspecFullName -NugetPackageRoot $NugetPackageRoot -UseDotnetCli -Verbose:$VerbosePreference
        }
        elseif ($NuGetExePath) {
            $NupkgFullName = New-NugetPackage -NuspecPath $NuspecFullName -NugetPackageRoot $NugetPackageRoot -NugetExePath $NuGetExePath -Verbose:$VerbosePreference
        }

        Write-Verbose -Message "Successfully created nuget package at $NupkgFullName"
    }
    catch {
        if ($PSArtifactType -eq $script:PSArtifactTypeModule) {
            $message = $LocalizedData.FailedToCreateCompressedModule -f ($_.Exception.message)
            $errorId = "FailedToCreateCompressedModule"
        }
        else {
            $message = $LocalizedData.FailedToCreateCompressedScript -f ($_.Exception.message)
            $errorId = "FailedToCreateCompressedScript"
        }

        Write-Error -Message $message -ErrorId $errorId -Category InvalidOperation -ErrorAction Stop
    }

    try {
        if ($DotnetCommandPath) {
            Publish-NugetPackage -NupkgPath $NupkgFullName -Destination $Destination -NugetApiKey $NugetApiKey -UseDotnetCli -Verbose:$VerbosePreference
        }
        elseif ($NuGetExePath) {
            Publish-NugetPackage -NupkgPath $NupkgFullName -Destination $Destination -NugetApiKey $NugetApiKey -NugetExePath $NuGetExePath -Verbose:$VerbosePreference
        }

        if ($PSArtifactType -eq "Module") {
            $message = $LocalizedData.PublishedSuccessfully -f ($Name, $Destination, $Name)
        }
        if ($PSArtifactType -eq "Script") {
            $message = $LocalizedData.PublishedScriptSuccessfully -f ($Name, $Destination, $Name)
        }

        Write-Verbose -Message $message
    }
    catch {
        if ( $NugetApiKey -eq "VSTS" -and ($_.Exception.Message -match "Cannot prompt for input in non-interactive mode.")) {
            $message = $LocalizedData.RegisterVSTSFeedAsNuGetPackageSource -f ($Destination, $script:VSTSAuthenticatedFeedsDocUrl)
        }
        else {
            $message = $_.Exception.message
        }

        if ($PSArtifactType -eq "Module") {
            $errorMessage = $LocalizedData.FailedToPublish -f ($Name, $message)
            $errorId = "FailedToPublishTheModule"
        }

        if ($PSArtifactType -eq "Script") {
            $errorMessage = $LocalizedData.FailedToPublishScript -f ($Name, $message)
            $errorId = "FailedToPublishTheScript"
        }

        Write-Error -Message $errorMessage -ErrorId $errorId -Category InvalidOperation -ErrorAction Stop
    }
}
