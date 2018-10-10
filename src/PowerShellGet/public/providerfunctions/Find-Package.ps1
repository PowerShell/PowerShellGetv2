function Find-Package
{
    [CmdletBinding()]
    param
    (
        [string[]]
        $names,

        [string]
        $requiredVersion,

        [string]
        $minimumVersion,

        [string]
        $maximumVersion
    )

    Write-Debug ($LocalizedData.ProviderApiDebugMessage -f ('Find-Package'))

    Set-ModuleSourcesVariable

    if($RequiredVersion -and $MinimumVersion)
    {
        ThrowError -ExceptionName "System.ArgumentException" `
                   -ExceptionMessage $LocalizedData.VersionRangeAndRequiredVersionCannotBeSpecifiedTogether `
                   -ErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether" `
                   -CallerPSCmdlet $PSCmdlet `
                   -ErrorCategory InvalidArgument
    }

    if($RequiredVersion -or $MinimumVersion)
    {
        if(-not $names -or $names.Count -ne 1 -or (Test-WildcardPattern -Name $names[0]))
        {
            ThrowError -ExceptionName "System.ArgumentException" `
                       -ExceptionMessage $LocalizedData.VersionParametersAreAllowedOnlyWithSingleName `
                       -ErrorId "VersionParametersAreAllowedOnlyWithSingleName" `
                       -CallerPSCmdlet $PSCmdlet `
                       -ErrorCategory InvalidArgument
        }
    }

    $options = $request.Options

    foreach( $o in $options.Keys )
    {
        Write-Debug ( "OPTION: {0} => {1}" -f ($o, $options[$o]) )
    }

	# When using -Name, we don't send PSGet-specific properties to the server - we will filter it ourselves
	$postFilter = New-Object -TypeName  System.Collections.Hashtable
	if($options.ContainsKey("Name"))
	{
		if($options.ContainsKey("Includes"))
		{
			$postFilter["Includes"] = $options["Includes"]
			$null = $options.Remove("Includes")
		}

		if($options.ContainsKey("DscResource"))
		{
			$postFilter["DscResource"] = $options["DscResource"]
			$null = $options.Remove("DscResource")
		}

		if($options.ContainsKey('RoleCapability'))
		{
			$postFilter['RoleCapability'] = $options['RoleCapability']
			$null = $options.Remove('RoleCapability')
		}

		if($options.ContainsKey("Command"))
		{
			$postFilter["Command"] = $options["Command"]
			$null = $options.Remove("Command")
		}
	}

    $LocationOGPHashtable = [ordered]@{}
    if($options -and $options.ContainsKey('Source'))
    {
        $SourceNames = $($options['Source'])

        Write-Verbose ($LocalizedData.SpecifiedSourceName -f ($SourceNames))

        foreach($sourceName in $SourceNames)
        {
            if($script:PSGetModuleSources.Contains($sourceName))
            {
                $ModuleSource = $script:PSGetModuleSources[$sourceName]
                $LocationOGPHashtable[$ModuleSource.SourceLocation] = (Get-ProviderName -PSCustomObject $ModuleSource)
            }
            else
            {
                $sourceByLocation = Get-SourceName -Location $sourceName

                if ($sourceByLocation)
                {
                    $ModuleSource = $script:PSGetModuleSources[$sourceByLocation]
                    $LocationOGPHashtable[$ModuleSource.SourceLocation] = (Get-ProviderName -PSCustomObject $ModuleSource)
                }
                else
                {
                    $message = $LocalizedData.RepositoryNotFound -f ($sourceName)
                    Write-Error -Message $message `
                                -ErrorId 'RepositoryNotFound' `
                                -Category InvalidArgument `
                                -TargetObject $sourceName
                }
            }
        }
    }
    elseif($options -and
           $options.ContainsKey($script:PackageManagementProviderParam) -and
           $options.ContainsKey('Location'))
    {
        $Location = $options['Location']
        $PackageManagementProvider = $options['PackageManagementProvider']

        Write-Verbose ($LocalizedData.SpecifiedLocationAndOGP -f ($Location, $PackageManagementProvider))

        $LocationOGPHashtable[$Location] = $PackageManagementProvider
    }
    else
    {
        Write-Verbose $LocalizedData.NoSourceNameIsSpecified

        $script:PSGetModuleSources.Values | Microsoft.PowerShell.Core\ForEach-Object { $LocationOGPHashtable[$_.SourceLocation] = (Get-ProviderName -PSCustomObject $_) }
    }

    $artifactTypes = $script:PSArtifactTypeModule
    if($options.ContainsKey($script:PSArtifactType))
    {
        $artifactTypes = $options[$script:PSArtifactType]
    }

    if($artifactTypes -eq $script:All)
    {
        $artifactTypes = @($script:PSArtifactTypeModule,$script:PSArtifactTypeScript)
    }

    $providerOptions = @{}

    if($options.ContainsKey($script:AllVersions))
    {
        $providerOptions[$script:AllVersions] = $options[$script:AllVersions]
    }

    if ($options.Contains($script:AllowPrereleaseVersions))
    {
        $providerOptions[$script:AllowPrereleaseVersions] = $options[$script:AllowPrereleaseVersions]
    }

    if($options.ContainsKey($script:Filter))
    {
        $Filter = $options[$script:Filter]
        $providerOptions['Contains'] = $Filter
    }

    if($options.ContainsKey($script:Tag))
    {
        $userSpecifiedTags = $options[$script:Tag] | Microsoft.PowerShell.Utility\Select-Object -Unique -ErrorAction Ignore
    }
    else
    {
        $userSpecifiedTags = @($script:NotSpecified)
    }

    $specifiedDscResources = @()
    if($options.ContainsKey('DscResource'))
    {
        $specifiedDscResources = $options['DscResource'] |
                                    Microsoft.PowerShell.Utility\Select-Object -Unique -ErrorAction Ignore |
                                        Microsoft.PowerShell.Core\ForEach-Object {"$($script:DscResource)_$_"}
    }

    $specifiedRoleCapabilities = @()
    if($options.ContainsKey('RoleCapability'))
    {
        $specifiedRoleCapabilities = $options['RoleCapability'] |
                                        Microsoft.PowerShell.Utility\Select-Object -Unique -ErrorAction Ignore |
                                            Microsoft.PowerShell.Core\ForEach-Object {"$($script:RoleCapability)_$_"}
    }

    $specifiedCommands = @()
    if($options.ContainsKey('Command'))
    {
        $specifiedCommands = $options['Command'] |
                                Microsoft.PowerShell.Utility\Select-Object -Unique -ErrorAction Ignore |
                                    Microsoft.PowerShell.Core\ForEach-Object {"$($script:Command)_$_"}
    }

    $specifiedIncludes = @()
    if($options.ContainsKey('Includes'))
    {
        $includes = $options['Includes'] |
                        Microsoft.PowerShell.Utility\Select-Object -Unique -ErrorAction Ignore |
                            Microsoft.PowerShell.Core\ForEach-Object {"$($script:Includes)_$_"}

        # Add PSIncludes_DscResource to $specifiedIncludes iff -DscResource names are not specified
        # Add PSIncludes_RoleCapability to $specifiedIncludes iff -RoleCapability names are not specified
        # Add PSIncludes_Cmdlet or PSIncludes_Function to $specifiedIncludes iff -Command names are not specified
        # otherwise $script:NotSpecified will be added to $specifiedIncludes
        if($includes)
        {
            if(-not $specifiedDscResources -and ($includes -contains "$($script:Includes)_DscResource") )
            {
               $specifiedIncludes += "$($script:Includes)_DscResource"
            }

            if(-not $specifiedRoleCapabilities -and ($includes -contains "$($script:Includes)_RoleCapability") )
            {
               $specifiedIncludes += "$($script:Includes)_RoleCapability"
            }

            if(-not $specifiedCommands)
            {
               if($includes -contains "$($script:Includes)_Cmdlet")
               {
                   $specifiedIncludes += "$($script:Includes)_Cmdlet"
               }

               if($includes -contains "$($script:Includes)_Function")
               {
                   $specifiedIncludes += "$($script:Includes)_Function"
               }

               if($includes -contains "$($script:Includes)_Workflow")
               {
                   $specifiedIncludes += "$($script:Includes)_Workflow"
               }
            }
        }
    }

    if(-not $specifiedDscResources)
    {
        $specifiedDscResources += $script:NotSpecified
    }

    if(-not $specifiedRoleCapabilities)
    {
        $specifiedRoleCapabilities += $script:NotSpecified
    }

    if(-not $specifiedCommands)
    {
        $specifiedCommands += $script:NotSpecified
    }

    if(-not $specifiedIncludes)
    {
        $specifiedIncludes += $script:NotSpecified
    }

    $providerSearchTags = @{}

    foreach($tag in $userSpecifiedTags)
    {
        foreach($include in $specifiedIncludes)
        {
            foreach($command in $specifiedCommands)
            {
                foreach($resource in $specifiedDscResources)
                {
                    foreach($roleCapability in $specifiedRoleCapabilities)
                    {
                        $providerTags = @()
                        if($resource -ne $script:NotSpecified)
                        {
                            $providerTags += $resource
                        }

                        if($roleCapability -ne $script:NotSpecified)
                        {
                            $providerTags += $roleCapability
                        }

                        if($command -ne $script:NotSpecified)
                        {
                            $providerTags += $command
                        }

                        if($include -ne $script:NotSpecified)
                        {
                            $providerTags += $include
                        }

                        if($tag -ne $script:NotSpecified)
                        {
                            $providerTags += $tag
                        }

                        if($providerTags)
                        {
                            $providerSearchTags["$tag $resource $roleCapability $command $include"] = $providerTags
                        }
                    }
                }
            }
        }
    }

    $InstallationPolicy = "Untrusted"
    if($options.ContainsKey('InstallationPolicy'))
    {
        $InstallationPolicy = $options['InstallationPolicy']
    }

    $streamedResults = @()

    foreach($artifactType in $artifactTypes)
    {
        foreach($kvPair in $LocationOGPHashtable.GetEnumerator())
        {
            if($request.IsCanceled)
            {
                return
            }

            $Location = $kvPair.Key
            if($artifactType -eq $script:PSArtifactTypeScript)
            {
                $sourceName = Get-SourceName -Location $Location

                if($SourceName)
                {
                    $ModuleSource = $script:PSGetModuleSources[$SourceName]

                    # Skip source if no ScriptSourceLocation is available.
                    if(-not $ModuleSource.ScriptSourceLocation)
                    {
                        if($options.ContainsKey('Source'))
                        {
                            $message = $LocalizedData.ScriptSourceLocationIsMissing -f ($ModuleSource.Name)
                            Write-Error -Message $message `
                                        -ErrorId 'ScriptSourceLocationIsMissing' `
                                        -Category InvalidArgument `
                                        -TargetObject $ModuleSource.Name
                        }

                        continue
                    }

                    $Location = $ModuleSource.ScriptSourceLocation
                }
            }

            $ProviderName = $kvPair.Value

            Write-Verbose ($LocalizedData.GettingPackageManagementProviderObject -f ($ProviderName))

	        $provider = $request.SelectProvider($ProviderName)

            if(-not $provider)
            {
                Write-Error -Message ($LocalizedData.PackageManagementProviderIsNotAvailable -f $ProviderName)

                Continue
            }

            Write-Verbose ($LocalizedData.SpecifiedLocationAndOGP -f ($Location, $provider.ProviderName))

            if($providerSearchTags.Values.Count)
            {
                $tagList = $providerSearchTags.Values
            }
            else
            {
                $tagList = @($script:NotSpecified)
            }

            $namesParameterEmpty = ($names.Count -eq 1) -and ($names[0] -eq '')

            foreach($providerTag in $tagList)
            {
                if($request.IsCanceled)
                {
                    return
                }

                $FilterOnTag = @()

                if($providerTag -ne $script:NotSpecified)
                {
                    $FilterOnTag = $providerTag
                }

                if(Microsoft.PowerShell.Management\Test-Path -Path $Location)
                {
                    if($artifactType -eq $script:PSArtifactTypeScript)
                    {
                        $FilterOnTag += 'PSScript'
                    }
                    elseif($artifactType -eq $script:PSArtifactTypeModule)
                    {
                        $FilterOnTag += 'PSModule'
                    }
                }

                if($FilterOnTag)
                {
                    $providerOptions["FilterOnTag"] = $FilterOnTag
                }
                elseif($providerOptions.ContainsKey('FilterOnTag'))
                {
                    $null = $providerOptions.Remove('FilterOnTag')
                }

                if($request.Options.ContainsKey($script:FindByCanonicalId))
                {
                    $providerOptions[$script:FindByCanonicalId] = $request.Options[$script:FindByCanonicalId]
                }

                $providerOptions["Headers"] = 'PSGalleryClientVersion=1.1'

                $NewRequest = $request.CloneRequest( $providerOptions, @($Location), $request.Credential )

                $pkgs = $provider.FindPackages($names,
                                               $requiredVersion,
                                               $minimumVersion,
                                               $maximumVersion,
                                               $NewRequest )

                foreach($pkg in  $pkgs)
                {
                    if($request.IsCanceled)
                    {
                        return
                    }

                    # $pkg.Name has to match any of the supplied names, using PowerShell wildcards
                    if ($namesParameterEmpty -or ($names | Foreach-Object { if ($pkg.Name -like $_){return $true; break} } -End {return $false}))
                    {
						$includePackage = $true

						# If -Name was provided, we need to post-filter
						# Filtering has AND semantics between different parameters and OR within a parameter (each parameter is potentially an array)
						if($options.ContainsKey("Name") -and $postFilter.Count -gt 0)
						{
							if ($pkg.Metadata["DscResources"].Count -gt 0)
							{
								$pkgDscResources = $pkg.Metadata["DscResources"] -Split " " | Microsoft.PowerShell.Core\Where-Object { $_.Trim() }
							}
							else
							{
								$pkgDscResources = $pkg.Metadata["tags"] -Split " " `
									| Microsoft.PowerShell.Core\Where-Object { $_.Trim() } `
									| Microsoft.PowerShell.Core\Where-Object { $_.StartsWith($script:DscResource, [System.StringComparison]::OrdinalIgnoreCase) } `
									| Microsoft.PowerShell.Core\ForEach-Object { $_.Substring($script:DscResource.Length + 1) }
							}

							if ($pkg.Metadata['RoleCapabilities'].Count -gt 0)
							{
								$pkgRoleCapabilities = $pkg.Metadata['RoleCapabilities'] -Split ' ' | Microsoft.PowerShell.Core\Where-Object { $_.Trim() }
							}
							else
							{
								$pkgRoleCapabilities = $pkg.Metadata["tags"] -Split ' ' `
									| Microsoft.PowerShell.Core\Where-Object { $_.Trim() } `
									| Microsoft.PowerShell.Core\Where-Object { $_.StartsWith($script:RoleCapability, [System.StringComparison]::OrdinalIgnoreCase) } `
									| Microsoft.PowerShell.Core\ForEach-Object { $_.Substring($script:RoleCapability.Length + 1) }
							}

							if ($pkg.Metadata["Functions"].Count -gt 0)
							{
								$pkgFunctions = $pkg.Metadata["Functions"] -Split " " | Microsoft.PowerShell.Core\Where-Object { $_.Trim() }
							}
							else
							{
								$pkgFunctions = $pkg.Metadata["tags"] -Split " " `
									| Microsoft.PowerShell.Core\Where-Object { $_.Trim() } `
									| Microsoft.PowerShell.Core\Where-Object { $_.StartsWith($script:Function, [System.StringComparison]::OrdinalIgnoreCase) } `
									| Microsoft.PowerShell.Core\ForEach-Object { $_.Substring($script:Function.Length + 1) }
							}

							if ($pkg.Metadata["Cmdlets"].Count -gt 0)
							{
								$pkgCmdlets = $pkg.Metadata["Cmdlets"] -Split " " | Microsoft.PowerShell.Core\Where-Object { $_.Trim() }
							}
							else
							{
								$pkgCmdlets = $pkg.Metadata["tags"] -Split " " `
									| Microsoft.PowerShell.Core\Where-Object { $_.Trim() } `
									| Microsoft.PowerShell.Core\Where-Object { $_.StartsWith($script:Cmdlet, [System.StringComparison]::OrdinalIgnoreCase) } `
									| Microsoft.PowerShell.Core\ForEach-Object { $_.Substring($script:Cmdlet.Length + 1) }
							}

							if ($pkg.Metadata["Workflows"].Count -gt 0)
							{
								$pkgWorkflows = $pkg.Metadata["Workflows"] -Split " " | Microsoft.PowerShell.Core\Where-Object { $_.Trim() }
							}
							else
							{
								$pkgWorkflows = $pkg.Metadata["tags"] -Split " " `
									| Microsoft.PowerShell.Core\Where-Object { $_.Trim() } `
									| Microsoft.PowerShell.Core\Where-Object { $_.StartsWith($script:Workflow, [System.StringComparison]::OrdinalIgnoreCase) } `
									| Microsoft.PowerShell.Core\ForEach-Object { $_.Substring($script:Workflow.Length + 1) }
							}

							foreach ($key in $postFilter.Keys)
							{
								switch ($key)
								{
									"DscResource" {
										$values = $postFilter[$key]

										$includePackage = $false

										foreach ($value in $values)
										{
											$wildcardPattern = New-Object System.Management.Automation.WildcardPattern $value,$script:wildcardOptions

											$pkgDscResources | Microsoft.PowerShell.Core\ForEach-Object {
												if ($wildcardPattern.IsMatch($_))
												{
													$includePackage = $true
													break
												}
											}
										}

										if (-not $includePackage)
										{
											break
										}
									}

									'RoleCapability' {
										$values = $postFilter[$key]

										$includePackage = $false

										foreach ($value in $values)
										{
											$wildcardPattern = New-Object System.Management.Automation.WildcardPattern $value,$script:wildcardOptions

											$pkgRoleCapabilities | Microsoft.PowerShell.Core\ForEach-Object {
												if ($wildcardPattern.IsMatch($_))
												{
													$includePackage = $true
													break
												}
											}
										}

										if (-not $includePackage)
										{
											break
										}
									}

									"Command" {
										$values = $postFilter[$key]

										$includePackage = $false

										foreach ($value in $values)
										{
											$wildcardPattern = New-Object System.Management.Automation.WildcardPattern $value,$script:wildcardOptions

											$pkgFunctions | Microsoft.PowerShell.Core\ForEach-Object {
												if ($wildcardPattern.IsMatch($_))
												{
													$includePackage = $true
													break
												}
											}

											$pkgCmdlets | Microsoft.PowerShell.Core\ForEach-Object {
												if ($wildcardPattern.IsMatch($_))
												{
													$includePackage = $true
													break
												}
											}

											$pkgWorkflows | Microsoft.PowerShell.Core\ForEach-Object {
												if ($wildcardPattern.IsMatch($_))
												{
													$includePackage = $true
													break
												}
											}
										}

										if (-not $includePackage)
										{
											break
										}
									}

									"Includes" {
										$values = $postFilter[$key]

										$includePackage = $false

										foreach ($value in $values)
										{
											switch ($value)
											{
												"Cmdlet" { if ($pkgCmdlets ) { $includePackage = $true } }
												"Function" { if ($pkgFunctions ) { $includePackage = $true } }
												"DscResource" { if ($pkgDscResources ) { $includePackage = $true } }
												"RoleCapability" { if ($pkgRoleCapabilities ) { $includePackage = $true } }
												"Workflow" { if ($pkgWorkflows ) { $includePackage = $true } }
											}
										}

										if (-not $includePackage)
										{
											break
										}
									}
								}
							}
						}

						if ($includePackage)
						{
							$fastPackageReference = New-FastPackageReference -ProviderName $provider.ProviderName `
																			-PackageName $pkg.Name `
																			-Version $pkg.Version `
																			-Source $Location `
																			-ArtifactType $artifactType

							if($streamedResults -notcontains $fastPackageReference)
							{
								$streamedResults += $fastPackageReference

								$FromTrustedSource = $false

								$ModuleSourceName = Get-SourceName -Location $Location

								if($ModuleSourceName)
								{
									$FromTrustedSource = $script:PSGetModuleSources[$ModuleSourceName].Trusted
								}
								elseif($InstallationPolicy -eq "Trusted")
								{
									$FromTrustedSource = $true
								}

								$sid = New-SoftwareIdentityFromPackage -Package $pkg `
																	-PackageManagementProviderName $provider.ProviderName `
																	-SourceLocation $Location `
																	-IsFromTrustedSource:$FromTrustedSource `
																	-Type $artifactType `
																	-request $request

								$script:FastPackRefHashtable[$fastPackageReference] = $pkg

								Write-Output -InputObject $sid
							}
						}
                    }
                }
            }
        }
    }
}