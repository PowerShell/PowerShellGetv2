function Install-PackageUtility
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FastPackageReference,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Location,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $request
    )

    Set-ModuleSourcesVariable

    Write-Debug ($LocalizedData.ProviderApiDebugMessage -f ('Install-PackageUtility'))

    Write-Debug ($LocalizedData.FastPackageReference -f $fastPackageReference)

    $Force = $false
    $SkipPublisherCheck = $false
    $AllowClobber = $false
    $Debug = $false
    $MinimumVersion = ""
    $RequiredVersion = ""
    $IsSavePackage = $false
    $Scope = $null
    $NoPathUpdate = $false
    $AcceptLicense = $false

    # take the fastPackageReference and get the package object again.
    $parts = $fastPackageReference -Split '[|]'

    if( $parts.Length -eq 5 )
    {
        $providerName = $parts[0]
        $packageName = $parts[1]
        $version = $parts[2]
        $sourceLocation= $parts[3]
        $artifactType = $parts[4]

        $result = ValidateAndGet-VersionPrereleaseStrings -Version $version -CallerPSCmdlet $PSCmdlet
        if (-not $result)
        {
            # ValidateAndGet-VersionPrereleaseStrings throws the error.
            # returning to avoid further execution when different values are specified for -ErrorAction parameter
            return
        }
        $galleryItemVersion = $result["Version"]
        $galleryItemPrerelease = $result["Prerelease"]
        $galleryItemFullVersion = $result["FullVersion"]

        # The default destination location for Modules and Scripts is ProgramFiles path
        $scriptDestination = $script:ProgramFilesScriptsPath
        $moduleDestination = $script:programFilesModulesPath
        $Scope = 'AllUsers'

        if($artifactType -eq $script:PSArtifactTypeScript)
        {
            $AdminPrivilegeErrorMessage = $LocalizedData.InstallScriptAdminPrivilegeRequiredForAllUsersScope -f @($script:ProgramFilesScriptsPath, $script:MyDocumentsScriptsPath)
            $AdminPrivilegeErrorId = 'InstallScriptAdminPrivilegeRequiredForAllUsersScope'
        }
        else
        {
            $AdminPrivilegeErrorMessage = $LocalizedData.InstallModuleAdminPrivilegeRequiredForAllUsersScope -f @($script:programFilesModulesPath, $script:MyDocumentsModulesPath)
            $AdminPrivilegeErrorId = 'InstallModuleAdminPrivilegeRequiredForAllUsersScope'
        }

        $installUpdate = $false

        $options = $request.Options

        if($options)
        {
            foreach( $o in $options.Keys )
            {
                Write-Debug ("OPTION: {0} => {1}" -f ($o, $request.Options[$o]) )
            }

            if($options.ContainsKey('Scope'))
            {
                $Scope = $options['Scope']
                Write-Verbose ($LocalizedData.SpecifiedInstallationScope -f $Scope)

                if($Scope -eq "CurrentUser")
                {
                    $scriptDestination = $script:MyDocumentsScriptsPath
                    $moduleDestination = $script:MyDocumentsModulesPath
                }
                elseif($Scope -eq "AllUsers")
                {
                    $scriptDestination = $script:ProgramFilesScriptsPath
                    $moduleDestination = $script:programFilesModulesPath

                    if(-not (Test-RunningAsElevated))
                    {
                        # Throw an error when Install-Module/Script is used as a non-admin user and '-Scope AllUsers'
                        ThrowError -ExceptionName "System.ArgumentException" `
                                    -ExceptionMessage $AdminPrivilegeErrorMessage `
                                    -ErrorId $AdminPrivilegeErrorId `
                                    -CallerPSCmdlet $PSCmdlet `
                                    -ErrorCategory InvalidArgument
                    }
                }
            }
            elseif($Location)
            {
                $IsSavePackage = $true
                $Scope = $null

                $moduleDestination = $Location
                $scriptDestination = $Location
            }
            elseif(-not $script:IsCoreCLR -and (Test-RunningAsElevated))
            {
                # If Windows and elevated default scope will be all users
                $scriptDestination = $script:ProgramFilesScriptsPath
                $moduleDestination = $script:ProgramFilesModulesPath
            }
            else
            {
                # If non-Windows or non-elevated default scope will be current user
                $scriptDestination = $script:MyDocumentsScriptsPath
                $moduleDestination = $script:MyDocumentsModulesPath
            }

            if($options.ContainsKey('SkipPublisherCheck'))
            {
                $SkipPublisherCheck = $options['SkipPublisherCheck']

                if($SkipPublisherCheck.GetType().ToString() -eq 'System.String')
                {
                    if($SkipPublisherCheck -eq 'true')
                    {
                        $SkipPublisherCheck = $true
                    }
                    else
                    {
                        $SkipPublisherCheck = $false
                    }
                }
            }

            if($options.ContainsKey('AllowClobber'))
            {
                $AllowClobber = $options['AllowClobber']

                if($AllowClobber.GetType().ToString() -eq 'System.String')
                {
                    if($AllowClobber -eq 'false')
                    {
                        $AllowClobber = $false
                    }
                    elseif($AllowClobber -eq 'true')
                    {
                        $AllowClobber = $true
                    }
                }
            }

            if($options.ContainsKey('Force'))
            {
                $Force = $options['Force']

                if($Force.GetType().ToString() -eq 'System.String')
                {
                    if($Force -eq 'false')
                    {
                        $Force = $false
                    }
                    elseif($Force -eq 'true')
                    {
                        $Force = $true
                    }
                }
            }

            if($options.ContainsKey('AcceptLicense'))
            {
                $AcceptLicense = $options['AcceptLicense']

                if($AcceptLicense.GetType().ToString() -eq 'System.String')
                {
                    if($AcceptLicense -eq 'false')
                    {
                        $AcceptLicense = $false
                    }
                    elseif($AcceptLicense -eq 'true')
                    {
                        $AcceptLicense = $true
                    }
                }
            }

            if($options.ContainsKey('Debug'))
            {
                $Debug = $options['Debug']

                if($Debug.GetType().ToString() -eq 'System.String')
                {
                    if($Debug -eq 'false')
                    {
                        $Debug = $false
                    }
                    elseif($Debug -eq 'true')
                    {
                        $Debug = $true
                    }
                }
            }

            if($options.ContainsKey('NoPathUpdate'))
            {
                $NoPathUpdate = $options['NoPathUpdate']

                if($NoPathUpdate.GetType().ToString() -eq 'System.String')
                {
                    if($NoPathUpdate -eq 'false')
                    {
                        $NoPathUpdate = $false
                    }
                    elseif($NoPathUpdate -eq 'true')
                    {
                        $NoPathUpdate = $true
                    }
                }
            }

            if($options.ContainsKey('MinimumVersion'))
            {
                $MinimumVersion = $options['MinimumVersion']
            }

            if($options.ContainsKey('RequiredVersion'))
            {
                $RequiredVersion = $options['RequiredVersion']
            }

            if($options.ContainsKey('InstallUpdate'))
            {
                $installUpdate = $options['InstallUpdate']

                if($installUpdate.GetType().ToString() -eq 'System.String')
                {
                    if($installUpdate -eq 'false')
                    {
                        $installUpdate = $false
                    }
                    elseif($installUpdate -eq 'true')
                    {
                        $installUpdate = $true
                    }
                }
            }

            if($Scope -and ($artifactType -eq $script:PSArtifactTypeScript) -and (-not $installUpdate))
            {
                ValidateAndSet-PATHVariableIfUserAccepts -Scope $Scope `
                                                         -ScopePath $scriptDestination `
                                                         -Request $request `
                                                         -NoPathUpdate:$NoPathUpdate `
                                                         -Force:$Force
            }

            if($artifactType -eq $script:PSArtifactTypeModule)
            {
                $message = $LocalizedData.ModuleDestination -f @($moduleDestination)
            }
            else
            {
                $message = $LocalizedData.ScriptDestination -f @($scriptDestination, $moduleDestination)
            }
            Write-Verbose $message
        }

        Write-Debug "ArtifactType is $artifactType"

        if($artifactType -eq $script:PSArtifactTypeModule)
        {
            # Test if module is already installed
            $InstalledModuleInfo = if(-not $IsSavePackage){ Test-ModuleInstalled -Name $packageName -RequiredVersion $RequiredVersion }

            if(-not $Force -and $InstalledModuleInfo)
            {
                $installedModPrerelease = $null
                if ((Get-Member -InputObject $InstalledModuleInfo -Name PrivateData -ErrorAction SilentlyContinue) -and `
                    $InstalledModuleInfo.PrivateData -and `
                    $InstalledModuleInfo.PrivateData.GetType().ToString() -eq "System.Collections.Hashtable" -and `
                    ($InstalledModuleInfo.PrivateData.ContainsKey('PSData')) -and `
                    $InstalledModuleInfo.PrivateData.PSData.GetType().ToString() -eq "System.Collections.Hashtable" -and `
                    ($InstalledModuleInfo.PrivateData.PSData.ContainsKey('Prerelease')))
                {
                    $installedModPrerelease = $InstalledModuleInfo.PrivateData.PSData.Prerelease
                }

                $result = ValidateAndGet-VersionPrereleaseStrings -Version $InstalledModuleInfo.Version -Prerelease $installedModPrerelease -CallerPSCmdlet $PSCmdlet
                if (-not $result)
                {
                    # ValidateAndGet-VersionPrereleaseStrings throws the error.
                    # returning to avoid further execution when different values are specified for -ErrorAction parameter
                    return
                }
                $installedModuleVersion = $result["Version"]
                $installedModulePrerelease = $result["Prerelease"]
                $installedModuleFullVersion = $result["FullVersion"]

                if($RequiredVersion -and (Test-ModuleSxSVersionSupport))
                {
                    # Check if the module with the required version is already installed otherwise proceed to install/update.
                    if($InstalledModuleInfo)
                    {
                        $message = $LocalizedData.ModuleWithRequiredVersionAlreadyInstalled -f ($InstalledModuleInfo.Version, $InstalledModuleInfo.Name, $InstalledModuleInfo.ModuleBase, $InstalledModuleInfo.Version)
                        Write-Error -Message $message -ErrorId "ModuleWithRequiredVersionAlreadyInstalled" -Category InvalidOperation
                        return
                    }
                }
                else
                {
                    if(-not $installUpdate)
                    {
                        if ($MinimumVersion)
                        {
                            $result = ValidateAndGet-VersionPrereleaseStrings -Version $MinimumVersion -CallerPSCmdlet $PSCmdlet
                            if (-not $result)
                            {
                                # ValidateAndGet-VersionPrereleaseStrings throws the error.
                                # returning to avoid further execution when different values are specified for -ErrorAction parameter
                                return
                            }
                            $minVersion = $result["Version"]
                            $minPrerelease = $result["Prerelease"]
                            $minFullVersion = $result["FullVersion"]
                        }
                        else
                        {
                            $minVersion = $null
                            $minPrerelease = $null
                            $minFullVersion = $null
                        }

                        if( (-not $MinimumVersion -and ($galleryItemFullVersion -ne $InstalledModuleFullVersion)) -or
                            ($MinimumVersion -and (Compare-PrereleaseVersions -FirstItemVersion $installedModuleVersion `
                                                                              -FirstItemPrerelease $installedModulePrerelease `
                                                                              -SecondItemVersion $minVersion `
                                                                              -SecondItemPrerelease $minPrerelease)))
                        {
                            if($PSVersionTable.PSVersion -ge '5.0.0')
                            {
                                $message = $LocalizedData.ModuleAlreadyInstalledSxS -f ($InstalledModuleFullVersion, $InstalledModuleInfo.Name, $InstalledModuleInfo.ModuleBase, $galleryItemFullVersion, $InstalledModuleFullVersion, $galleryItemFullVersion)
                            }
                            else
                            {
                                $message = $LocalizedData.ModuleAlreadyInstalled -f ($InstalledModuleFullVersion, $InstalledModuleInfo.Name, $InstalledModuleInfo.ModuleBase, $InstalledModuleFullVersion, $galleryItemFullVersion)
                            }
                            Write-Error -Message $message -ErrorId "ModuleAlreadyInstalled" -Category InvalidOperation
                        }
                        else
                        {
                            $message = $LocalizedData.ModuleAlreadyInstalledVerbose -f ($InstalledModuleFullVersion, $InstalledModuleInfo.Name, $InstalledModuleInfo.ModuleBase)
                            Write-Verbose $message
                        }

                        return
                    }
                    else
                    {
                        if (Compare-PrereleaseVersions -FirstItemVersion $installedModuleVersion `
                                                       -FirstItemPrerelease $installedModulePrerelease `
                                                       -SecondItemVersion $galleryItemVersion.ToString() `
                                                       -SecondItemPrerelease $galleryItemPrerelease)
                        {
                            $message = $LocalizedData.FoundModuleUpdate -f ($InstalledModuleInfo.Name, $galleryItemFullVersion)
                            Write-Verbose $message
                        }
                        else
                        {
                            $message = $LocalizedData.NoUpdateAvailable -f ($InstalledModuleInfo.Name)
                            Write-Verbose $message
                            return
                        }
                    }
                }
            }
        }

        if($artifactType -eq $script:PSArtifactTypeScript)
        {
            # Test if script is already installed
            $InstalledScriptInfo = if(-not $IsSavePackage){ Test-ScriptInstalled -Name $packageName }

            Write-Debug "InstalledScriptInfo is $InstalledScriptInfo"

            if(-not $Force -and $InstalledScriptInfo)
            {
                $result = ValidateAndGet-VersionPrereleaseStrings -Version $InstalledScriptInfo.Version -CallerPSCmdlet $PSCmdlet
                if (-not $result)
                {
                    # ValidateAndGet-VersionPrereleaseStrings throws the error.
                    # returning to avoid further execution when different values are specified for -ErrorAction parameter
                    return
                }
                $installedScriptInfoVersion = $result["Version"]
                $installedScriptInfoPrerelease = $result["Prerelease"]
                $installedScriptFullVersion = $result["FullVersion"]

                if(-not $installUpdate)
                {
                    if ($MinimumVersion)
                    {
                        $result = ValidateAndGet-VersionPrereleaseStrings -Version $MinimumVersion -CallerPSCmdlet $PSCmdlet
                        if (-not $result)
                        {
                            # ValidateAndGet-VersionPrereleaseStrings throws the error.
                            # returning to avoid further execution when different values are specified for -ErrorAction parameter
                            return
                        }
                        $minVersion = $result["Version"]
                        $minPrerelease = $result["Prerelease"]
                        $minFullVersion = $result["FullVersion"]
                    }
                    else
                    {
                        $minVersion = $null
                        $minPrerelease = $null
                        $minFullVersion = $null
                    }


                    if( (-not $MinimumVersion -and ($galleryItemFullVersion -ne $installedScriptFullVersion)) -or
                        ($MinimumVersion -and (Compare-PrereleaseVersions -FirstItemVersion $installedScriptInfoVersion `
                                                                          -FirstItemPrerelease $installedScriptInfoPrerelease `
                                                                          -SecondItemVersion $minVersion `
                                                                          -SecondItemPrerelease $minPrerelease) ))
                    {
                        $message = $LocalizedData.ScriptAlreadyInstalled -f ($installedScriptFullVersion, $InstalledScriptInfo.Name, $InstalledScriptInfo.ScriptBase, $installedScriptFullVersion, $galleryItemFullVersion)
                        Write-Error -Message $message -ErrorId "ScriptAlreadyInstalled" -Category InvalidOperation
                    }
                    else
                    {
                        $message = $LocalizedData.ScriptAlreadyInstalledVerbose -f ($installedScriptFullVersion, $InstalledScriptInfo.Name, $InstalledScriptInfo.ScriptBase)
                        Write-Verbose $message
                    }

                    return
                }
                else
                {
                    if (Compare-PrereleaseVersions -FirstItemVersion $installedScriptInfoVersion.ToString() `
                                                   -FirstItemPrerelease $installedScriptInfoPrerelease `
                                                   -SecondItemVersion $galleryItemVersion.ToString() `
                                                   -SecondItemPrerelease $galleryItemPrerelease)
                    {
                        $message = $LocalizedData.FoundScriptUpdate -f ($InstalledScriptInfo.Name, $version)
                        Write-Verbose $message
                    }
                    else
                    {
                        $message = $LocalizedData.NoScriptUpdateAvailable -f ($InstalledScriptInfo.Name)
                        Write-Verbose $message
                        return
                    }
                }
            }

            # Throw an error if there is a command with the same name and -force is not specified.
            if(-not $installUpdate -and
               -not $IsSavePackage -and
               -not $Force)
            {
                $cmd = Microsoft.PowerShell.Core\Get-Command -Name $packageName `
                                                             -ErrorAction Ignore `
                                                             -WarningAction SilentlyContinue
                if($cmd)
                {
                    $message = $LocalizedData.CommandAlreadyAvailable -f ($packageName)
                    Write-Error -Message $message -ErrorId CommandAlreadyAvailableWitScriptName -Category InvalidOperation
                    return
                }
            }
        }

        # create a temp folder and download the module
        $tempDestination = Microsoft.PowerShell.Management\Join-Path -Path $script:TempPath -ChildPath "$(Microsoft.PowerShell.Utility\Get-Random)"
        $null = Microsoft.PowerShell.Management\New-Item -Path $tempDestination -ItemType Directory -Force -Confirm:$false -WhatIf:$false

        try
        {
            $provider = $request.SelectProvider($providerName)
            if(-not $provider)
            {
                Write-Error -Message ($LocalizedData.PackageManagementProviderIsNotAvailable -f $providerName)
                return
            }

            if($request.IsCanceled)
            {
                return
            }

            Write-Verbose ($LocalizedData.SpecifiedLocationAndOGP -f ($provider.ProviderName, $providerName))

            $InstalledItemsList = $null
            $pkg = $script:FastPackRefHashtable[$fastPackageReference]

            # If an item has dependencies, prepare the list of installed items and
            # pass it to the NuGet provider to not download the already installed items.
            if($pkg.Dependencies.count -and
               -not $IsSavePackage -and
               -not $Force)
            {
                $InstalledItemsList = Microsoft.PowerShell.Core\Get-Module -ListAvailable |
                                        Microsoft.PowerShell.Core\ForEach-Object {"$($_.Name)!#!$($_.Version)".ToLower()}

                if($artifactType -eq $script:PSArtifactTypeScript)
                {
                    $InstalledItemsList += $script:PSGetInstalledScripts.GetEnumerator() |
                                               Microsoft.PowerShell.Core\ForEach-Object {
                                                   "$($_.Value.PSGetItemInfo.Name)!#!$($_.Value.PSGetItemInfo.Version)".ToLower()
                                               }
                }

                $InstalledItemsList | Select-Object -Unique -ErrorAction Ignore

                if($Debug)
                {
                    $InstalledItemsList | Microsoft.PowerShell.Core\ForEach-Object { Write-Debug -Message "Locally available Item: $_"}
                }
            }

            $ProviderOptions = @{
                                    Destination=$tempDestination;
                                }

            if($InstalledItemsList)
            {
                $ProviderOptions['InstalledPackages'] = $InstalledItemsList
            }

            $newRequest = $request.CloneRequest( $ProviderOptions, @($SourceLocation), $request.Credential )

            if($artifactType -eq $script:PSArtifactTypeModule)
            {
                $message = $LocalizedData.DownloadingModuleFromGallery -f ($packageName, $galleryItemFullVersion, $sourceLocation)
            }
            else
            {
                $message = $LocalizedData.DownloadingScriptFromGallery -f ($packageName, $galleryItemFullVersion, $sourceLocation)
            }
            Write-Verbose $message

            $installedPkgs = $provider.InstallPackage($script:FastPackRefHashtable[$fastPackageReference], $newRequest)

            $YesToAll = $false
            $NoToAll = $false
           
            foreach($pkg in $installedPkgs)
            {
                if($request.IsCanceled)
                {
                    return
                }

                $result = ValidateAndGet-VersionPrereleaseStrings -Version $pkg.Version -CallerPSCmdlet $PSCmdlet
                if (-not $result)
                {
                    # ValidateAndGet-VersionPrereleaseStrings throws the error.
                    # returning to avoid further execution when different values are specified for -ErrorAction parameter
                    return
                }
                $pkgVersion = $result["Version"]
                $pkgPrerelease = $result["Prerelease"]
                $pkgFullVersion = $result["FullVersion"]

                $destinationModulePath = Microsoft.PowerShell.Management\Join-Path -Path $moduleDestination -ChildPath $pkg.Name

                # Side-by-Side module version is available on PowerShell 5.0 or later versions only
                # By default, PowerShell module versions will be installed/updated Side-by-Side.
                if(Test-ModuleSxSVersionSupport)
                {
                    $destinationModulePath = Microsoft.PowerShell.Management\Join-Path -Path $destinationModulePath -ChildPath $pkgVersion
                }

                $destinationscriptPath = $scriptDestination

                # Get actual artifact type from the package
                $packageType = $script:PSArtifactTypeModule
                $installLocation = $destinationModulePath
                # Below logic handles the package folder name with version.
                $tempPackagePath = Microsoft.PowerShell.Management\Join-Path -Path $tempDestination -ChildPath "$($pkg.Name).$($pkg.Version)"
                if(-not (Microsoft.PowerShell.Management\Test-Path -Path $tempPackagePath -PathType Container))
                {
                    $message = $LocalizedData.UnableToDownloadThePackage -f ($provider.ProviderName, $pkg.Name, $pkg.Version, $tempPackagePath)
                    Write-Error -Message $message -ErrorId 'UnableToDownloadThePackage' -Category InvalidOperation
                    return
                }

                $packageFiles = Microsoft.PowerShell.Management\Get-ChildItem -Path $tempPackagePath -Recurse -Exclude "*.nupkg","*.nuspec"

                if($packageFiles -and $packageFiles.GetType().ToString() -eq 'System.IO.FileInfo' -and $packageFiles.Name -eq "$($pkg.Name).ps1")
                {
                    $packageType = $script:PSArtifactTypeScript
                    $installLocation = $destinationscriptPath
                }

                $AdditionalParams = @{}

                if(-not $IsSavePackage)
                {
                    # During the install operation:
                    #     InstalledDate should be the current Get-Date value
                    #     UpdatedDate should be null
                    #
                    # During the update operation:
                    #     InstalledDate should be from the previous version's InstalledDate otherwise current Get-Date value
                    #     UpdatedDate should be the current Get-Date value
                    #
                    $InstalledDate = Microsoft.PowerShell.Utility\Get-Date

                    if($installUpdate)
                    {
                        $AdditionalParams['UpdatedDate'] = Microsoft.PowerShell.Utility\Get-Date

                        $InstalledItemDetails = $null
                        if($packageType -eq $script:PSArtifactTypeModule)
                        {
                            $InstalledItemDetails = Get-InstalledModuleDetails -Name $pkg.Name | Select-Object -Last 1 -ErrorAction Ignore
                        }
                        elseif($packageType -eq $script:PSArtifactTypeScript)
                        {
                            $InstalledItemDetails = Get-InstalledScriptDetails -Name $pkg.Name | Select-Object -Last 1 -ErrorAction Ignore
                        }

                        if($InstalledItemDetails -and
                           $InstalledItemDetails.PSGetItemInfo -and
                           (Get-Member -InputObject $InstalledItemDetails.PSGetItemInfo -Name 'InstalledDate') -and
                           $InstalledItemDetails.PSGetItemInfo.InstalledDate)
                        {
                            $InstalledDate = $InstalledItemDetails.PSGetItemInfo.InstalledDate
                        }
                    }

                    $AdditionalParams['InstalledDate'] = $InstalledDate
                }

                # construct the PSGetItemInfo from SoftwareIdentity and persist it
                $psgItemInfo = New-PSGetItemInfo -SoftwareIdentity $pkg `
                                                 -PackageManagementProviderName $provider.ProviderName `
                                                 -SourceLocation $sourceLocation `
                                                 -Type $packageType `
                                                 -InstalledLocation $installLocation `
                                                 @AdditionalParams

                if($packageType -eq $script:PSArtifactTypeModule)
                {
                    if ($psgItemInfo.PowerShellGetFormatVersion -and
                        ($script:SupportedPSGetFormatVersionMajors -notcontains $psgItemInfo.PowerShellGetFormatVersion.Major))
                    {
                        $message = $LocalizedData.NotSupportedPowerShellGetFormatVersion -f ($psgItemInfo.Name, $psgItemInfo.PowerShellGetFormatVersion, $psgItemInfo.Name)
                        Write-Error -Message $message -ErrorId "NotSupportedPowerShellGetFormatVersion" -Category InvalidOperation
                        continue
                    }

                    $sourceModulePath = $tempPackagePath
                    if($psgItemInfo.PowerShellGetFormatVersion -eq "1.0")
                    {
                        $sourceModulePath = Microsoft.PowerShell.Management\Join-Path -Path $sourceModulePath -ChildPath 'Content' |
                            Microsoft.PowerShell.Management\Join-Path -ChildPath '*' |
                                Microsoft.PowerShell.Management\Join-Path -ChildPath $script:ModuleReferences |
                                    Microsoft.PowerShell.Management\Join-Path -ChildPath $pkg.Name
                    }

                    #Prompt if module requires license Acceptance
                    $requireLicenseAcceptance = $false
                    if($psgItemInfo.PowerShellGetFormatVersion -and
                       $psgItemInfo.PowerShellGetFormatVersion -ge $script:PSGetRequireLicenseAcceptanceFormatVersion)
                     {
                        if($psgItemInfo.AdditionalMetadata -and $psgItemInfo.AdditionalMetadata.requireLicenseAcceptance)
                        {
                              $requireLicenseAcceptance = $psgItemInfo.AdditionalMetadata.requireLicenseAcceptance
                        }
                    }

                    if($requireLicenseAcceptance -eq $true)
                    {
                        if($Force -and -not($AcceptLicense))
                        {
                            $message = $LocalizedData.ForceAcceptLicense -f $pkg.Name

                            ThrowError -ExceptionName "System.ArgumentException" `
                                       -ExceptionMessage $message `
                                       -ErrorId "ForceAcceptLicense" `
                                       -CallerPSCmdlet $PSCmdlet `
                                       -ErrorCategory InvalidArgument
                        }

                        If (-not ($YesToAll -or $NoToAll -or $AcceptLicense))
                        {
                            $LicenseFilePath = Join-PathUtility -Path $sourceModulePath -ChildPath 'License.txt' -PathType File
                            if(-not(Test-Path -Path $LicenseFilePath -PathType Leaf))
                            {
                                $message = $LocalizedData.LicenseTxtNotFound

                                ThrowError -ExceptionName "System.ArgumentException" `
                                           -ExceptionMessage $message `
                                           -ErrorId "LicenseTxtNotFound" `
                                           -CallerPSCmdlet $PSCmdlet `
                                           -ErrorCategory ObjectNotFound
                            }
                            $FormattedEula = (Get-Content -Path $LicenseFilePath) -Join "`r`n"
                            $message = $FormattedEula + "`r`n" + ($LocalizedData.AcceptanceLicenseQuery -f $pkg.Name)
                            $title = $LocalizedData.AcceptLicense
                            $result = $request.ShouldContinue($message, $title, [ref]$yesToAll, [ref]$NoToAll)
                            if(($result -eq $false) -or ($NoToAll -eq $true))
                            {
                                Write-Warning -Message $LocalizedData.UserDeclinedLicenseAcceptance
                                return
                            }
                        }
                    }

                    $CurrentModuleInfo = $null

                    # Validate the module
                    if(-not $IsSavePackage)
                    {
                        $CurrentModuleInfo = Test-ValidManifestModule -ModuleBasePath $sourceModulePath `
                                                                      -ModuleName $pkg.Name `
                                                                      -InstallLocation $InstallLocation `
                                                                      -AllowClobber:$AllowClobber `
                                                                      -SkipPublisherCheck:$SkipPublisherCheck `
                                                                      -IsUpdateOperation:$installUpdate

                        if(-not $CurrentModuleInfo)
                        {
                            Write-Verbose -Message ($LocalizedData.ModuleValidationFailed -f $ModuleName,$ModuleBasePath)
                            # This Install-Package provider API gets called once per an item/package/SoftwareIdentity.
                            # Return if there is an error instead of continuing further to install the dependencies or current module.
                            #
                            return
                        }
                    }

                    # Test if module is already installed
                    $InstalledModuleInfo2 = if(-not $IsSavePackage){ Test-ModuleInstalled -Name $pkg.Name -RequiredVersion $pkgFullVersion }

                    if($pkg.Name -ne $packageName)
                    {
                        if(-not $Force -and $InstalledModuleInfo2)
                        {
                            $result = ValidateAndGet-VersionPrereleaseStrings -Version $InstalledModuleInfo2.Version -CallerPSCmdlet $PSCmdlet
                            if (-not $result)
                            {
                                # ValidateAndGet-VersionPrereleaseStrings throws the error.
                                # returning to avoid further execution when different values are specified for -ErrorAction parameter
                                return
                            }
                            $installedModuleVersion = $result["Version"]
                            $installedModulePrerelease = $result["Prerelease"]
                            $installedModuleFullVersion = $result["FullVersion"]

                            if(Test-ModuleSxSVersionSupport)
                            {
                                if($pkgFullVersion -eq $installedModuleFullVersion)
                                {
                                    if(-not $installUpdate)
                                    {
                                        $message = $LocalizedData.ModuleWithRequiredVersionAlreadyInstalled -f ($installedModuleFullVersion, $InstalledModuleInfo2.Name, $InstalledModuleInfo2.ModuleBase, $InstalledModuleFullVersion)
                                    }
                                    else
                                    {
                                        $message = $LocalizedData.NoUpdateAvailable -f ($pkg.Name)
                                    }

                                    Write-Verbose $message
                                    Continue
                                }
                            }
                            else
                            {
                                if(-not $installUpdate)
                                {
                                    $message = $LocalizedData.ModuleAlreadyInstalledVerbose -f ($InstalledModuleFullVersion, $InstalledModuleInfo2.Name, $InstalledModuleInfo2.ModuleBase)
                                    Write-Verbose $message
                                    Continue
                                }
                                else
                                {
                                    if(Compare-PrereleaseVersions -FirstItemVersion $installedModuleVersion.ToString() `
                                                                  -FirstItemPrerelease $installedModPrerelease `
                                                                  -SecondItemVersion $pkgVersion.ToString() `
                                                                  -SecondItemPrerelease $pkgPrerelease)
                                    {
                                        $message = $LocalizedData.FoundModuleUpdate -f ($pkg.Name, $pkgFullVersion)
                                        Write-Verbose $message
                                    }
                                    else
                                    {
                                        $message = $LocalizedData.NoUpdateAvailable -f ($pkg.Name)
                                        Write-Verbose $message
                                        Continue
                                    }
                                }
                            }
                        }

                        if($IsSavePackage)
                        {
                            $DependencyInstallMessage = $LocalizedData.SavingDependencyModule -f ($pkg.Name, $pkgFullVersion, $packageName)
                        }
                        else
                        {
                            $DependencyInstallMessage = $LocalizedData.InstallingDependencyModule -f ($pkg.Name, $pkgFullVersion, $packageName)
                        }

                        Write-Verbose  $DependencyInstallMessage
                    }

                    # check if module is in use
                    if($InstalledModuleInfo2)
                    {
                        $moduleInUse = Test-ModuleInUse -ModuleBasePath $InstalledModuleInfo2.ModuleBase `
                                                        -ModuleName $InstalledModuleInfo2.Name `
                                                        -ModuleVersion $InstalledModuleInfo2.Version `
                                                        -Verbose:$VerbosePreference `
                                                        -WarningAction $WarningPreference `
                                                        -ErrorAction $ErrorActionPreference `
                                                        -Debug:$DebugPreference

                        if($moduleInUse)
                        {
                            $message = $LocalizedData.ModuleIsInUse -f ($psgItemInfo.Name)
                            Write-Verbose $message
                            continue
                        }
                    }

                    # Use the actual module version retrieved from the module manifest.
                    if($CurrentModuleInfo -and (Test-ModuleSxSVersionSupport) -and -not $pkgPrerelease)
                    {
                        $destinationModulePath = Microsoft.PowerShell.Management\Join-Path -Path $moduleDestination -ChildPath $pkg.Name |
                            Microsoft.PowerShell.Management\Join-Path -ChildPath $CurrentModuleInfo.Version
                        $installLocation = $destinationModulePath
                        $psgItemInfo.InstalledLocation = $installLocation
                        $psgItemInfo.Version = $CurrentModuleInfo.Version
                    }

                    Copy-Module -SourcePath $sourceModulePath -DestinationPath $destinationModulePath -PSGetItemInfo $psgItemInfo -IsSavePackage:$IsSavePackage

                    if(-not $IsSavePackage)
                    {
                        # Write warning messages if externally managed module dependencies are not installed.
                        $ExternalModuleDependencies = Get-ExternalModuleDependencies -PSModuleInfo $CurrentModuleInfo
                        foreach($ExternalDependency in $ExternalModuleDependencies)
                        {
                            $depModuleInfo = Test-ModuleInstalled -Name $ExternalDependency

                            if(-not $depModuleInfo)
                            {
                                Write-Warning -Message ($LocalizedData.MissingExternallyManagedModuleDependency -f $ExternalDependency,$pkg.Name,$ExternalDependency)
                            }
                            else
                            {
                                Write-Verbose -Message ($LocalizedData.ExternallyManagedModuleDependencyIsInstalled -f $ExternalDependency)
                            }
                        }
                    }

                    if($IsSavePackage)
                    {
                        $message = $LocalizedData.ModuleSavedSuccessfully -f ($psgItemInfo.Name, $installLocation)
                    }
                    else
                    {
                        $message = $LocalizedData.ModuleInstalledSuccessfully -f ($psgItemInfo.Name, $installLocation)
                    }
                    Write-Verbose $message
                }


                if($packageType -eq $script:PSArtifactTypeScript)
                {
                    if ($psgItemInfo.PowerShellGetFormatVersion -and
                        ($script:SupportedPSGetFormatVersionMajors -notcontains $psgItemInfo.PowerShellGetFormatVersion.Major))
                    {
                        $message = $LocalizedData.NotSupportedPowerShellGetFormatVersionScripts -f ($psgItemInfo.Name, $psgItemInfo.PowerShellGetFormatVersion, $psgItemInfo.Name)
                        Write-Error -Message $message -ErrorId "NotSupportedPowerShellGetFormatVersion" -Category InvalidOperation
                        continue
                    }

                    $sourceScriptPath = Join-PathUtility -Path $tempPackagePath -ChildPath "$($pkg.Name).ps1" -PathType File

                    $currentScriptInfo = $null
                    if(-not $IsSavePackage)
                    {
                        # Validate the script
                        $currentScriptInfo = Test-ScriptFileInfo -Path $sourceScriptPath -ErrorAction SilentlyContinue

                        if(-not $currentScriptInfo)
                        {
                            $message = $LocalizedData.InvalidPowerShellScriptFile -f ($pkg.Name)
                            Write-Error -Message $message -ErrorId "InvalidPowerShellScriptFile" -Category InvalidOperation -TargetObject $pkg.Name
                            continue
                        }

                        # Use the version extracted from the script file.
                        $psgItemInfo.Version = $currentScriptInfo.Version
                    }

                    # Test if script is already installed
                    $InstalledScriptInfo2 = if(-not $IsSavePackage){ Test-ScriptInstalled -Name $pkg.Name }


                    if($pkg.Name -ne $packageName)
                    {
                        if(-not $Force -and $InstalledScriptInfo2)
                        {
                            $result = ValidateAndGet-VersionPrereleaseStrings -Version $InstalledScriptInfo2.Version -CallerPSCmdlet $PSCmdlet
                            if (-not $result)
                            {
                                # ValidateAndGet-VersionPrereleaseStrings throws the error.
                                # returning to avoid further execution when different values are specified for -ErrorAction parameter
                                return
                            }
                            $installedScriptFullVersion = $result["FullVersion"]

                            if(-not $installUpdate)
                            {
                                $message = $LocalizedData.ScriptAlreadyInstalledVerbose -f ($InstalledScriptFullVersion, $InstalledScriptInfo2.Name, $InstalledScriptInfo2.ScriptBase)
                                Write-Verbose $message
                                Continue
                            }
                            else
                            {
                                if(Compare-PrereleaseVersions -FirstItemVersion $installedScriptInfoVersion.ToString() `
                                                              -FirstItemPrerelease $installedScriptInfoPrerelease `
                                                              -SecondItemVersion $pkgVersion `
                                                              -SecondItemPrerelease $pkgPrerelease)
                                {
                                    $message = $LocalizedData.FoundScriptUpdate -f ($pkg.Name, $pkgFullVersion)
                                    Write-Verbose $message
                                }
                                else
                                {
                                    $message = $LocalizedData.NoScriptUpdateAvailable -f ($pkg.Name)
                                    Write-Verbose $message
                                    Continue
                                }
                            }
                        }

                        if($IsSavePackage)
                        {
                            $DependencyInstallMessage = $LocalizedData.SavingDependencyScript -f ($pkg.Name, $pkgFullVersion, $packageName)
                        }
                        else
                        {
                            $DependencyInstallMessage = $LocalizedData.InstallingDependencyScript -f ($pkg.Name, $pkgFullVersion, $packageName)
                        }

                        Write-Verbose  $DependencyInstallMessage
                    }

                    Write-Debug "SourceScriptPath is $sourceScriptPath and DestinationscriptPath is $destinationscriptPath"
                    Copy-ScriptFile -SourcePath $sourceScriptPath -DestinationPath $destinationscriptPath -PSGetItemInfo $psgItemInfo -Scope $Scope

                    if(-not $IsSavePackage)
                    {
                        # Write warning messages if externally managed module dependencies are not installed.
                        foreach($ExternalDependency in $currentScriptInfo.ExternalModuleDependencies)
                        {
                            $depModuleInfo = Test-ModuleInstalled -Name $ExternalDependency

                            if(-not $depModuleInfo)
                            {
                                Write-Warning -Message ($LocalizedData.ScriptMissingExternallyManagedModuleDependency -f $ExternalDependency,$pkg.Name,$ExternalDependency)
                            }
                            else
                            {
                                Write-Verbose -Message ($LocalizedData.ExternallyManagedModuleDependencyIsInstalled -f $ExternalDependency)
                            }
                        }

                        # Write warning messages if externally managed script dependencies are not installed.
                        foreach($ExternalDependency in $currentScriptInfo.ExternalScriptDependencies)
                        {
                            $depScriptInfo = Test-ScriptInstalled -Name $ExternalDependency

                            if(-not $depScriptInfo)
                            {
                                Write-Warning -Message ($LocalizedData.ScriptMissingExternallyManagedScriptDependency -f $ExternalDependency,$pkg.Name,$ExternalDependency)
                            }
                            else
                            {
                                Write-Verbose -Message ($LocalizedData.ScriptExternallyManagedScriptDependencyIsInstalled -f $ExternalDependency)
                            }
                        }
                    }

                    # Remove the old scriptfile if it's path different from the required destination script path when -Force is specified
                    if($Force -and
                        $InstalledScriptInfo2 -and
                        -not $destinationscriptPath.StartsWith($InstalledScriptInfo2.ScriptBase, [System.StringComparison]::OrdinalIgnoreCase))
                    {
                        Microsoft.PowerShell.Management\Remove-Item -Path $InstalledScriptInfo2.Path `
                                                                    -Force `
                                                                    -ErrorAction SilentlyContinue `
                                                                    -WarningAction SilentlyContinue `
                                                                    -Confirm:$false -WhatIf:$false
                    }

                    if($IsSavePackage)
                    {
                        $message = $LocalizedData.ScriptSavedSuccessfully -f ($psgItemInfo.Name, $installLocation)
                    }
                    else
                    {
                        $message = $LocalizedData.ScriptInstalledSuccessfully -f ($psgItemInfo.Name, $installLocation)
                    }
                    Write-Verbose $message
                }

                $sid = New-SoftwareIdentityFromPackage -Package $pkg `
                    -SourceLocation $sourceLocation `
                    -PackageManagementProviderName $provider.ProviderName `
                    -Request $request `
                    -Type $packageType `
                    -InstalledLocation $installLocation `
                    @AdditionalParams

                Write-Output -InputObject $sid
            }
        }
        finally
        {
            Microsoft.PowerShell.Management\Remove-Item $tempDestination -Force -Recurse -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
        }
    }
}