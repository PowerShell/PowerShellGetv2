function Publish-PSArtifactUtility
{
    [CmdletBinding(PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true, ParameterSetName='PublishModule')]
        [ValidateNotNullOrEmpty()]
        [PSModuleInfo]
        $PSModuleInfo,

        [Parameter(Mandatory=$true, ParameterSetName='PublishScript')]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]
        $PSScriptInfo,

        [Parameter(Mandatory=$true, ParameterSetName='PublishModule')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ManifestPath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Destination,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Repository,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NugetApiKey,

        [Parameter(Mandatory=$false)]
        [pscredential]
        $Credential,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NugetPackageRoot,

        [Parameter(ParameterSetName='PublishModule')]
        [Version]
        $FormatVersion,

        [Parameter(ParameterSetName='PublishModule')]
        [string]
        $ReleaseNotes,

        [Parameter(ParameterSetName='PublishModule')]
        [string[]]
        $Tags,

        [Parameter(ParameterSetName='PublishModule')]
        [Uri]
        $LicenseUri,

        [Parameter(ParameterSetName='PublishModule')]
        [Uri]
        $IconUri,

        [Parameter(ParameterSetName='PublishModule')]
        [Uri]
        $ProjectUri
    )

    Install-NuGetClientBinaries -CallerPSCmdlet $PSCmdlet -BootstrapNuGetExe

    $PSArtifactType = $script:PSArtifactTypeModule
    $Name = $null
    $Description = $null
    $Version = ""
    $Author = $null
    $CompanyName = $null
    $Copyright = $null
    $requireLicenseAcceptance = "false"

    if($PSModuleInfo)
    {
        $Name = $PSModuleInfo.Name
        $Description = $PSModuleInfo.Description
        $Version = $PSModuleInfo.Version
        $Author = $PSModuleInfo.Author
        $CompanyName = $PSModuleInfo.CompanyName
        $Copyright = $PSModuleInfo.Copyright

        if($PSModuleInfo.PrivateData -and
           ($PSModuleInfo.PrivateData.GetType().ToString() -eq "System.Collections.Hashtable") -and
           $PSModuleInfo.PrivateData["PSData"] -and
           ($PSModuleInfo.PrivateData["PSData"].GetType().ToString() -eq "System.Collections.Hashtable")
           )
        {
            if( -not $Tags -and $PSModuleInfo.PrivateData.PSData["Tags"])
            {
                $Tags = $PSModuleInfo.PrivateData.PSData.Tags
            }

            if( -not $ReleaseNotes -and $PSModuleInfo.PrivateData.PSData["ReleaseNotes"])
            {
                $ReleaseNotes = $PSModuleInfo.PrivateData.PSData.ReleaseNotes
            }

            if( -not $LicenseUri -and $PSModuleInfo.PrivateData.PSData["LicenseUri"])
            {
                $LicenseUri = $PSModuleInfo.PrivateData.PSData.LicenseUri
            }

            if( -not $IconUri -and $PSModuleInfo.PrivateData.PSData["IconUri"])
            {
                $IconUri = $PSModuleInfo.PrivateData.PSData.IconUri
            }

            if( -not $ProjectUri -and $PSModuleInfo.PrivateData.PSData["ProjectUri"])
            {
                $ProjectUri = $PSModuleInfo.PrivateData.PSData.ProjectUri
            }

            if ($PSModuleInfo.PrivateData.PSData["Prerelease"])
            {
                $psmoduleInfoPrereleaseString = $PSModuleInfo.PrivateData.PSData.Prerelease
                if ($psmoduleInfoPrereleaseString -and $psmoduleInfoPrereleaseString.StartsWith("-"))
                {
                    $Version = [string]$Version + $psmoduleInfoPrereleaseString
                }
                else
                {
                    $Version = [string]$Version + "-" + $psmoduleInfoPrereleaseString
                }
            }

            if($PSModuleInfo.PrivateData.PSData["RequireLicenseAcceptance"])
            {
                $requireLicenseAcceptance = $PSModuleInfo.PrivateData.PSData.requireLicenseAcceptance.ToString().ToLower()
                if($requireLicenseAcceptance -eq "true")
                {
                    if($FormatVersion -and ($FormatVersion.Major -lt $script:PSGetRequireLicenseAcceptanceFormatVersion.Major))
                    {
                        $message = $LocalizedData.requireLicenseAcceptanceNotSupported -f($FormatVersion)
                        ThrowError -ExceptionName "System.InvalidOperationException" `
                        -ExceptionMessage $message `
                        -ErrorId "requireLicenseAcceptanceNotSupported" `
                        -CallerPSCmdlet $PSCmdlet `
                        -ErrorCategory InvalidData
                    }

                    if(-not $LicenseUri)
                    {
                        $message = $LocalizedData.LicenseUriNotSpecified
                        ThrowError -ExceptionName "System.InvalidOperationException" `
                            -ExceptionMessage $message `
                            -ErrorId "LicenseUriNotSpecified" `
                            -CallerPSCmdlet $PSCmdlet `
                            -ErrorCategory InvalidData
                    }

                    $LicenseFilePath = Join-PathUtility -Path $NugetPackageRoot -ChildPath 'License.txt' -PathType File
                    if(-not $LicenseFilePath -or -not (Test-Path -Path $LicenseFilePath -PathType Leaf))
                    {
                        $message = $LocalizedData.LicenseTxtNotFound
                        ThrowError -ExceptionName "System.InvalidOperationException" `
                        -ExceptionMessage $message `
                        -ErrorId "LicenseTxtNotFound" `
                        -CallerPSCmdlet $PSCmdlet `
                        -ErrorCategory InvalidData
                    }

                    if((Get-Content -LiteralPath $LicenseFilePath) -eq $null)
                    {
                        $message = $LocalizedData.LicenseTxtEmpty
                        ThrowError -ExceptionName "System.InvalidOperationException" `
                        -ExceptionMessage $message `
                        -ErrorId "LicenseTxtEmpty" `
                        -CallerPSCmdlet $PSCmdlet `
                        -ErrorCategory InvalidData
                    }

                    #RequireLicenseAcceptance is true, License uri and license.txt exist. Bump Up the FormatVersion
                    if(-not $FormatVersion)
                    {
                        $FormatVersion = $script:CurrentPSGetFormatVersion
                    }
                }
                elseif($requireLicenseAcceptance -ne "false")
                {
                    $InvalidValueForRequireLicenseAcceptance = $LocalizedData.InvalidValueBoolean -f ($requireLicenseAcceptance, "requireLicenseAcceptance")
                    Write-Warning -Message $InvalidValueForRequireLicenseAcceptance
                }
            }
        }
    }
    else
    {
        $PSArtifactType = $script:PSArtifactTypeScript

        $Name = $PSScriptInfo.Name
        $Description = $PSScriptInfo.Description
        $Version = $PSScriptInfo.Version
        $Author = $PSScriptInfo.Author
        $CompanyName = $PSScriptInfo.CompanyName
        $Copyright = $PSScriptInfo.Copyright

        if($PSScriptInfo.'Tags')
        {
            $Tags = $PSScriptInfo.Tags
        }

        if($PSScriptInfo.'ReleaseNotes')
        {
            $ReleaseNotes = $PSScriptInfo.ReleaseNotes
        }

        if($PSScriptInfo.'LicenseUri')
        {
            $LicenseUri = $PSScriptInfo.LicenseUri
        }

        if($PSScriptInfo.'IconUri')
        {
            $IconUri = $PSScriptInfo.IconUri
        }

        if($PSScriptInfo.'ProjectUri')
        {
            $ProjectUri = $PSScriptInfo.ProjectUri
        }
    }


    # Add PSModule and PSGet format version tags
    if(-not $Tags)
    {
        $Tags = @()
    }

    if($FormatVersion)
    {
        $Tags += "$($script:PSGetFormatVersion)_$FormatVersion"
    }

    $DependentModuleDetails = @()

    if($PSScriptInfo)
    {
        $Tags += "PSScript"

        if($PSScriptInfo.DefinedCommands)
        {
            if($PSScriptInfo.DefinedFunctions)
            {
                $Tags += "$($script:Includes)_Function"
                $Tags += $PSScriptInfo.DefinedFunctions | Microsoft.PowerShell.Core\ForEach-Object { "$($script:Function)_$_" }
            }

            if($PSScriptInfo.DefinedWorkflows)
            {
                $Tags += "$($script:Includes)_Workflow"
                $Tags += $PSScriptInfo.DefinedWorkflows | Microsoft.PowerShell.Core\ForEach-Object { "$($script:Workflow)_$_" }
            }

            $Tags += $PSScriptInfo.DefinedCommands | Microsoft.PowerShell.Core\ForEach-Object { "$($script:Command)_$_" }
        }

        # Populate the dependencies elements from RequiredModules and RequiredScripts
        #
        $ValidateAndGetScriptDependencies_Params = @{
            Repository=$Repository
            DependentScriptInfo=$PSScriptInfo
            CallerPSCmdlet=$PSCmdlet
            Verbose=$VerbosePreference
            Debug=$DebugPreference
        }
        if ($PSBoundParameters.ContainsKey('Credential'))
        {
            $ValidateAndGetScriptDependencies_Params.Add('Credential',$Credential)
        }
        $DependentModuleDetails += ValidateAndGet-ScriptDependencies @ValidateAndGetScriptDependencies_Params
    }
    else
    {
        $Tags += "PSModule"

        $ModuleManifestHashTable = Get-ManifestHashTable -Path $ManifestPath

        if($PSModuleInfo.ExportedCommands.Count)
        {
            if($PSModuleInfo.ExportedCmdlets.Count)
            {
                $Tags += "$($script:Includes)_Cmdlet"
                $Tags += $PSModuleInfo.ExportedCmdlets.Keys | Microsoft.PowerShell.Core\ForEach-Object { "$($script:Cmdlet)_$_" }

                #if CmdletsToExport field in manifest file is "*", we suggest the user to include all those cmdlets for best practice
                if($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey('CmdletsToExport') -and ($ModuleManifestHashTable.CmdletsToExport -eq "*"))
                {
                    $WarningMessage = $LocalizedData.ShouldIncludeCmdletsToExport -f ($ManifestPath)
                    Write-Warning -Message $WarningMessage
                }
            }

            if($PSModuleInfo.ExportedFunctions.Count)
            {
                $Tags += "$($script:Includes)_Function"
                $Tags += $PSModuleInfo.ExportedFunctions.Keys | Microsoft.PowerShell.Core\ForEach-Object { "$($script:Function)_$_" }

                if($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey('FunctionsToExport') -and ($ModuleManifestHashTable.FunctionsToExport -eq "*"))
                {
                    $WarningMessage = $LocalizedData.ShouldIncludeFunctionsToExport -f ($ManifestPath)
                    Write-Warning -Message $WarningMessage
                }
            }

            $Tags += $PSModuleInfo.ExportedCommands.Keys | Microsoft.PowerShell.Core\ForEach-Object { "$($script:Command)_$_" }
        }

        $dscResourceNames = Get-ExportedDscResources -PSModuleInfo $PSModuleInfo
        if($dscResourceNames)
        {
            $Tags += "$($script:Includes)_DscResource"

            $Tags += $dscResourceNames | Microsoft.PowerShell.Core\ForEach-Object { "$($script:DscResource)_$_" }

            #If DscResourcesToExport is commented out or "*" is used, we will write-warning
            if($ModuleManifestHashTable -and
                ($ModuleManifestHashTable.ContainsKey("DscResourcesToExport") -and
                $ModuleManifestHashTable.DscResourcesToExport -eq "*") -or
                -not $ModuleManifestHashTable.ContainsKey("DscResourcesToExport"))
            {
                $WarningMessage = $LocalizedData.ShouldIncludeDscResourcesToExport -f ($ManifestPath)
                Write-Warning -Message $WarningMessage
            }
        }

        $RoleCapabilityNames = Get-AvailableRoleCapabilityName -PSModuleInfo $PSModuleInfo
        if($RoleCapabilityNames)
        {
            $Tags += "$($script:Includes)_RoleCapability"

            $Tags += $RoleCapabilityNames | Microsoft.PowerShell.Core\ForEach-Object { "$($script:RoleCapability)_$_" }
        }

        # Populate the module dependencies elements from RequiredModules and
        # NestedModules properties of the current PSModuleInfo
        $GetModuleDependencies_Params = @{
            PSModuleInfo=$PSModuleInfo
            Repository=$Repository
            CallerPSCmdlet=$PSCmdlet
            Verbose=$VerbosePreference
            Debug=$DebugPreference
        }
        if ($PSBoundParameters.ContainsKey('Credential'))
        {
            $GetModuleDependencies_Params.Add('Credential',$Credential)
        }
        $DependentModuleDetails = Get-ModuleDependencies @GetModuleDependencies_Params
    }

    $dependencies = @()
    ForEach($Dependency in $DependentModuleDetails)
    {
        $ModuleName = $Dependency.Name
        $VersionString = $null

        # Version format in NuSpec:
        # "[2.0]" --> (== 2.0) Required Version
        # "2.0" --> (>= 2.0) Minimum Version
        #
        # When only MaximumVersion is specified in the ModuleSpecification
        # (,1.0]  = x <= 1.0
        #
        # When both Minimum and Maximum versions are specified in the ModuleSpecification
        # [1.0,2.0] = 1.0 <= x <= 2.0

        if($Dependency.Keys -Contains "RequiredVersion")
        {
            $VersionString = "[$($Dependency.RequiredVersion)]"
        }
        elseif($Dependency.Keys -Contains 'MinimumVersion' -and $Dependency.Keys -Contains 'MaximumVersion')
        {
            $VersionString = "[$($Dependency.MinimumVersion),$($Dependency.MaximumVersion)]"
        }
        elseif($Dependency.Keys -Contains 'MaximumVersion')
        {
            $VersionString = "(,$($Dependency.MaximumVersion)]"
        }
        elseif($Dependency.Keys -Contains 'MinimumVersion')
        {
            $VersionString = "$($Dependency.MinimumVersion)"
        }

        if ([System.string]::IsNullOrWhiteSpace($VersionString))
        {
            $dependencies += "<dependency id='$($ModuleName)'/>"
        }
        else
        {
            $dependencies += "<dependency id='$($ModuleName)' version='$($VersionString)' />"
        }
    }

    # Populate the nuspec elements
    $nuspec = @"
<?xml version="1.0"?>
<package >
    <metadata>
        <id>$(Get-EscapedString -ElementValue "$Name")</id>
        <version>$($Version)</version>
        <authors>$(Get-EscapedString -ElementValue "$Author")</authors>
        <owners>$(Get-EscapedString -ElementValue "$CompanyName")</owners>
        <description>$(Get-EscapedString -ElementValue "$Description")</description>
        <releaseNotes>$(Get-EscapedString -ElementValue "$ReleaseNotes")</releaseNotes>
        <requireLicenseAcceptance>$($requireLicenseAcceptance.ToString())</requireLicenseAcceptance>
        <copyright>$(Get-EscapedString -ElementValue "$Copyright")</copyright>
        <tags>$(if($Tags){ Get-EscapedString -ElementValue ($Tags -join ' ')})</tags>
        $(if($LicenseUri){
         "<licenseUrl>$(Get-EscapedString -ElementValue "$LicenseUri")</licenseUrl>"
        })
        $(if($ProjectUri){
        "<projectUrl>$(Get-EscapedString -ElementValue "$ProjectUri")</projectUrl>"
        })
        $(if($IconUri){
        "<iconUrl>$(Get-EscapedString -ElementValue "$IconUri")</iconUrl>"
        })
        <dependencies>
            $dependencies
        </dependencies>
    </metadata>
</package>
"@

# When packaging we must build something.
# So, we are building an empty assembly called NotUsed, and discarding it.
$CsprojContent = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <AssemblyName>NotUsed</AssemblyName>
    <Description>Temp project used for creating nupkg file.</Description>
    <NuspecFile>$Name.nuspec</NuspecFile>
    <NuspecBasePath>$NugetPackageRoot</NuspecBasePath>
    <TargetFramework>netcoreapp2.0</TargetFramework>
  </PropertyGroup>
</Project>
"@
    $NupkgPath = Microsoft.PowerShell.Management\Join-Path -Path $NugetPackageRoot -ChildPath "$Name.$Version.nupkg"

    $csprojBasePath = $null
    if($script:DotnetCommandPath) {
        $csprojBasePath = Microsoft.PowerShell.Management\Join-Path -Path $script:TempPath -ChildPath ([System.Guid]::NewGuid())
        $null = Microsoft.PowerShell.Management\New-Item -Path $csprojBasePath -ItemType Directory -Force -WhatIf:$false -Confirm:$false
        $NuspecPath = Microsoft.PowerShell.Management\Join-Path -Path $csprojBasePath -ChildPath "$Name.nuspec"
        $CsprojFilePath = Microsoft.PowerShell.Management\Join-Path -Path $csprojBasePath -ChildPath "$Name.csproj"
    }
    else {
        $NuspecPath = Microsoft.PowerShell.Management\Join-Path -Path $NugetPackageRoot -ChildPath "$Name.nuspec"
    }

    $tempErrorFile = $null
    $tempOutputFile = $null

    try
    {
        # Remove existing nuspec and nupkg files
        if($NupkgPath -and (Test-Path -Path $NupkgPath -PathType Leaf))
        {
            Microsoft.PowerShell.Management\Remove-Item $NupkgPath  -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
        }

        if($NuspecPath -and (Test-Path -Path $NuspecPath -PathType Leaf))
        {
            Microsoft.PowerShell.Management\Remove-Item $NuspecPath -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
        }

        Microsoft.PowerShell.Management\Set-Content -Value $nuspec -Path $NuspecPath -Force -Confirm:$false -WhatIf:$false

        # Create .nupkg file
        if($script:DotnetCommandPath) {
            Microsoft.PowerShell.Management\Set-Content -Value $CsprojContent -Path $CsprojFilePath -Force -Confirm:$false -WhatIf:$false

            $arguments = @('pack')
            $arguments += $csprojBasePath
            $arguments += @('--output',$NugetPackageRoot)
            $arguments += "/p:StagingPath=$NugetPackageRoot"
            $output = & $script:DotnetCommandPath $arguments
            Write-Debug -Message "dotnet pack output:  $output"
        }
        elseif($script:NuGetExePath) {
            $output = & $script:NuGetExePath pack $NuspecPath -OutputDirectory $NugetPackageRoot
        }

        if(-not (Test-Path -Path $NupkgPath -PathType Leaf)) {
            $SemanticVersionString = Get-NormalizedVersionString -Version $Version
            $NupkgPath = Join-PathUtility -Path $NugetPackageRoot -ChildPath "$Name.$($SemanticVersionString).nupkg" -PathType File
        }

        if($LASTEXITCODE -or -not $NupkgPath -or -not (Test-Path -Path $NupkgPath -PathType Leaf))
        {
            if($PSArtifactType -eq $script:PSArtifactTypeModule)
            {
                $message = $LocalizedData.FailedToCreateCompressedModule -f ($output)
                $errorId = "FailedToCreateCompressedModule"
            }
            else
            {
                $message = $LocalizedData.FailedToCreateCompressedScript -f ($output)
                $errorId = "FailedToCreateCompressedScript"
            }

            Write-Error -Message $message -ErrorId $errorId -Category InvalidOperation
            return
        }

        # Publish the .nupkg to gallery
        $tempErrorFile = Microsoft.PowerShell.Management\Join-Path -Path $nugetPackageRoot -ChildPath "TempPublishError.txt"
        $tempOutputFile = Microsoft.PowerShell.Management\Join-Path -Path $nugetPackageRoot -ChildPath "TempPublishOutput.txt"

        $errorMsg = $null
        $StartProcess_params = @{
            RedirectStandardError = $tempErrorFile
            RedirectStandardOutput = $tempOutputFile
            NoNewWindow = $true
            Wait = $true
        }

        if($script:DotnetCommandPath) {
            $StartProcess_params['FilePath'] = $script:DotnetCommandPath

            $ArgumentList = @('nuget')
            $ArgumentList += 'push'
            $ArgumentList += "`"$NupkgPath`""
            $ArgumentList += @('--source', "`"$($Destination.TrimEnd('\'))`"")
            $ArgumentList += @('--api-key', "`"$NugetApiKey`"")
        }
        elseif($script:NuGetExePath) {
            $StartProcess_params['FilePath'] = $script:NuGetExePath

            $ArgumentList = @('push')
            $ArgumentList += "`"$NupkgPath`""
            $ArgumentList += @('-source', "`"$($Destination.TrimEnd('\'))`"")
            $ArgumentList += @('-apikey', "`"$NugetApiKey`"")
            $ArgumentList += '-NonInteractive'
        }
        $StartProcess_params['ArgumentList'] = $ArgumentList

        if($script:IsCoreCLR -and -not $script:IsNanoServer) {
            $StartProcess_params['WhatIf'] = $false
            $StartProcess_params['Confirm'] = $false
        }

        Microsoft.PowerShell.Management\Start-Process @StartProcess_params

        if(Test-Path -Path $tempErrorFile -PathType Leaf) {
            $errorMsg = Microsoft.PowerShell.Management\Get-Content -Path $tempErrorFile -Raw
        }

        if($errorMsg)
        {
            if(($NugetApiKey -eq 'VSTS') -and
               ($errorMsg -match 'Cannot prompt for input in non-interactive mode.') )
            {
                $errorMsg = $LocalizedData.RegisterVSTSFeedAsNuGetPackageSource -f ($Destination, $script:VSTSAuthenticatedFeedsDocUrl)
            }

            if($PSArtifactType -eq $script:PSArtifactTypeModule)
            {
                $message = $LocalizedData.FailedToPublish -f ($Name,$errorMsg)
                $errorId = "FailedToPublishTheModule"
            }
            else
            {
                $message = $LocalizedData.FailedToPublishScript -f ($Name,$errorMsg)
                $errorId = "FailedToPublishTheScript"
            }

            Write-Error -Message $message -ErrorId $errorId -Category InvalidOperation
        }
        else
        {
            if($PSArtifactType -eq $script:PSArtifactTypeModule)
            {
                $message = $LocalizedData.PublishedSuccessfully -f ($Name, $Destination, $Name)
            }
            else
            {
                $message = $LocalizedData.PublishedScriptSuccessfully -f ($Name, $Destination, $Name)
            }

            Write-Verbose -Message $message
        }
    }
    finally
    {
        if($NupkgPath -and (Test-Path -Path $NupkgPath -PathType Leaf))
        {
            Microsoft.PowerShell.Management\Remove-Item $NupkgPath  -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
        }

        if($NuspecPath -and (Test-Path -Path $NuspecPath -PathType Leaf))
        {
            Microsoft.PowerShell.Management\Remove-Item $NuspecPath -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
        }

        if($tempErrorFile -and (Test-Path -Path $tempErrorFile -PathType Leaf))
        {
            Microsoft.PowerShell.Management\Remove-Item $tempErrorFile -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
        }

        if($tempOutputFile -and (Test-Path -Path $tempOutputFile -PathType Leaf))
        {
            Microsoft.PowerShell.Management\Remove-Item $tempOutputFile -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
        }

        if($csprojBasePath -and (Test-Path -Path $csprojBasePath -PathType Container))
        {
            Microsoft.PowerShell.Management\Remove-Item -Path $csprojBasePath -Recurse -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
        }
    }
}