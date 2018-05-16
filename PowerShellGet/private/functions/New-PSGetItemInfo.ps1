function New-PSGetItemInfo
{
    param
    (
        [Parameter(Mandatory=$true)]
        $SoftwareIdentity,

        [Parameter()]
        $PackageManagementProviderName,

        [Parameter()]
        [string]
        $SourceLocation,

        [Parameter(Mandatory=$true)]
        [string]
        $Type,

        [Parameter()]
        [string]
        $InstalledLocation,

        [Parameter()]
        [System.DateTime]
        $InstalledDate,

        [Parameter()]
        [System.DateTime]
        $UpdatedDate
    )

    foreach($swid in $SoftwareIdentity)
    {

        if($SourceLocation)
        {
            $sourceName = (Get-SourceName -Location $SourceLocation)
        }
        else
        {
            # First get the source name from the Metadata
            # if not exists, get the source name from $swid.Source
            # otherwise default to $swid.Source
            $sourceName = (Get-First $swid.Metadata["SourceName"])

            if(-not $sourceName)
            {
                $sourceName = (Get-SourceName -Location $swid.Source)
            }

            if(-not $sourceName)
            {
                $sourceName = $swid.Source
            }

            $SourceLocation = Get-SourceLocation -SourceName $sourceName
        }

        $published = (Get-First $swid.Metadata["published"])
        $PublishedDate = New-Object System.DateTime

        $InstalledDateString = (Get-First $swid.Metadata['installeddate'])
        if(-not $InstalledDate -and $InstalledDateString)
        {
            $InstalledDate = New-Object System.DateTime
            if(-not (([System.DateTime]::TryParse($InstalledDateString, [System.Globalization.DateTimeFormatInfo]::InvariantInfo, [System.Globalization.DateTimeStyles]::None, ([ref]$InstalledDate))) -or
                     ([System.DateTime]::TryParse($InstalledDateString, ([ref]$InstalledDate)))))
            {
                $InstalledDate = $null
            }
        }

        $UpdatedDateString = (Get-First $swid.Metadata['updateddate'])
        if(-not $UpdatedDate -and $UpdatedDateString)
        {
            $UpdatedDate = New-Object System.DateTime
            if(-not (([System.DateTime]::TryParse($UpdatedDateString, [System.Globalization.DateTimeFormatInfo]::InvariantInfo, [System.Globalization.DateTimeStyles]::None, ([ref]$UpdatedDate))) -or
                     ([System.DateTime]::TryParse($UpdatedDateString, ([ref]$UpdatedDate)))))
            {
                $UpdatedDate = $null
            }
        }

        $tags = (Get-First $swid.Metadata["tags"]) -split " "
        $userTags = @()

        $exportedDscResources = @()
        $exportedRoleCapabilities = @()
        $exportedCmdlets = @()
        $exportedFunctions = @()
        $exportedWorkflows = @()
        $exportedCommands = @()

        $exportedRoleCapabilities += (Get-First $swid.Metadata['RoleCapabilities']) -split " " | Microsoft.PowerShell.Core\Where-Object { $_.Trim() }
        $exportedDscResources += (Get-First $swid.Metadata["DscResources"]) -split " " | Microsoft.PowerShell.Core\Where-Object { $_.Trim() }
        $exportedCmdlets += (Get-First $swid.Metadata["Cmdlets"]) -split " " | Microsoft.PowerShell.Core\Where-Object { $_.Trim() }
        $exportedFunctions += (Get-First $swid.Metadata["Functions"]) -split " " | Microsoft.PowerShell.Core\Where-Object { $_.Trim() }
        $exportedWorkflows += (Get-First $swid.Metadata["Workflows"]) -split " " | Microsoft.PowerShell.Core\Where-Object { $_.Trim() }
        $exportedCommands += $exportedCmdlets + $exportedFunctions + $exportedWorkflows
        $PSGetFormatVersion = $null

        ForEach($tag in $tags)
        {
            if(-not $tag.Trim())
            {
                continue
            }

            $parts = $tag -split "_",2
            if($parts.Count -ne 2)
            {
                $userTags += $tag
                continue
            }

            Switch($parts[0])
            {
                $script:Command            { $exportedCommands += $parts[1]; break }
                $script:DscResource        { $exportedDscResources += $parts[1]; break }
                $script:Cmdlet             { $exportedCmdlets += $parts[1]; break }
                $script:Function           { $exportedFunctions += $parts[1]; break }
                $script:Workflow           { $exportedWorkflows += $parts[1]; break }
                $script:RoleCapability     { $exportedRoleCapabilities += $parts[1]; break }
                $script:PSGetFormatVersion { $PSGetFormatVersion = $parts[1]; break }
                $script:Includes           { break }
                Default                    { $userTags += $tag; break }
            }
        }

        $ArtifactDependencies = @()
        Foreach ($dependencyString in $swid.Dependencies)
        {
            [Uri]$packageId = $null
            if([Uri]::TryCreate($dependencyString, [System.UriKind]::Absolute, ([ref]$packageId)))
            {
                $segments = $packageId.Segments
                $Version = $null
                $DependencyName = $null
                if ($segments)
                {
                    $DependencyName = [Uri]::UnescapeDataString($segments[0].Trim('/', '\'))
                    $Version = if($segments.Count -gt 1){[Uri]::UnescapeDataString($segments[1])}
                }

                $dep = [ordered]@{
                            Name=$DependencyName
                        }

                if($Version)
                {
                    # Required/exact version is represented in NuGet as "[2.0]"
                    if ($Version -match "\[+[0-9.]+\]")
                    {
                        $dep["RequiredVersion"] = $Version.Trim('[', ']')
                    }
                    elseif ($Version -match "\[+[0-9., ]+\]")
                    {
                        # Minimum and Maximum version range is represented in NuGet as "[1.0, 2.0]"
                        $versionRange = $Version.Trim('[', ']') -split ',' | Microsoft.PowerShell.Core\Where-Object {$_}
                        if($versionRange -and $versionRange.count -eq 2)
                        {
                            $dep["MinimumVersion"] = $versionRange[0].Trim()
                            $dep["MaximumVersion"] = $versionRange[1].Trim()
                        }
                    }
                    elseif ($Version -match "\(+[0-9., ]+\]")
                    {
                        # Maximum version is represented in NuGet as "(, 2.0]"
                        $maximumVersion = $Version.Trim('(', ']') -split ',' | Microsoft.PowerShell.Core\Where-Object {$_}

                        if($maximumVersion)
                        {
                            $dep["MaximumVersion"] = $maximumVersion.Trim()
                        }
                    }
                    else
                    {
                        $dep['MinimumVersion'] = $Version
                    }
                }

                $dep["CanonicalId"]=$dependencyString

                $ArtifactDependencies += $dep
            }
        }

        $additionalMetadata =  Microsoft.PowerShell.Utility\New-Object PSCustomObject -Property ([ordered]@{})
        foreach ( $key in $swid.Metadata.Keys.LocalName)
        {
            Microsoft.PowerShell.Utility\Add-Member -InputObject $additionalMetadata `
                                                    -MemberType NoteProperty `
                                                    -Name $key `
                                                    -Value (Get-First $swid.Metadata[$key])
        }

        if (-not (Get-Member -InputObject $additionalMetadata -Name "IsPrerelease") )
        {
            if ($swid.Version -match '-')
            {
                Microsoft.PowerShell.Utility\Add-Member -InputObject $additionalMetadata `
                                                        -MemberType NoteProperty `
                                                        -Name 'IsPrerelease' `
                                                        -Value $true
            }
            else {
                Microsoft.PowerShell.Utility\Add-Member -InputObject $additionalMetadata `
                                                        -MemberType NoteProperty `
                                                        -Name 'IsPrerelease' `
                                                        -Value $false
            }
        }

        if(Get-Member -InputObject $additionalMetadata -Name 'ItemType')
        {
            $Type = $additionalMetadata.'ItemType'
        }
        elseif($userTags -contains 'PSModule')
        {
            $Type = $script:PSArtifactTypeModule
        }
        elseif($userTags -contains 'PSScript')
        {
            $Type = $script:PSArtifactTypeScript
        }


        $PSGetItemInfo = Microsoft.PowerShell.Utility\New-Object PSCustomObject -Property ([ordered]@{
                Name = $swid.Name
                Version = $swid.Version
                Type = $Type
                Description = (Get-First $swid.Metadata["description"])
                Author = (Get-EntityName -SoftwareIdentity $swid -Role "author")
                CompanyName = (Get-EntityName -SoftwareIdentity $swid -Role "owner")
                Copyright = (Get-First $swid.Metadata["copyright"])
                PublishedDate = if([System.DateTime]::TryParse($published, ([ref]$PublishedDate))){$PublishedDate};
                InstalledDate = $InstalledDate;
                UpdatedDate = $UpdatedDate;
                LicenseUri = (Get-UrlFromSwid -SoftwareIdentity $swid -UrlName "license")
                ProjectUri = (Get-UrlFromSwid -SoftwareIdentity $swid -UrlName "project")
                IconUri = (Get-UrlFromSwid -SoftwareIdentity $swid -UrlName "icon")
                Tags = $userTags

                Includes = @{
                                DscResource = $exportedDscResources
                                Command     = $exportedCommands
                                Cmdlet      = $exportedCmdlets
                                Function    = $exportedFunctions
                                Workflow    = $exportedWorkflows
                                RoleCapability = $exportedRoleCapabilities
                            }

                PowerShellGetFormatVersion=[Version]$PSGetFormatVersion

                ReleaseNotes = (Get-First $swid.Metadata["releaseNotes"])

                Dependencies = $ArtifactDependencies

                RepositorySourceLocation = $SourceLocation
                Repository = $sourceName
                PackageManagementProvider = if($PackageManagementProviderName) { $PackageManagementProviderName } else { (Get-First $swid.Metadata["PackageManagementProvider"]) }

				AdditionalMetadata = $additionalMetadata
            })

        if(-not $InstalledLocation)
        {
            $InstalledLocation = (Get-First $swid.Metadata[$script:InstalledLocation])
        }

        if($InstalledLocation)
        {
            Microsoft.PowerShell.Utility\Add-Member -InputObject $PSGetItemInfo -MemberType NoteProperty -Name $script:InstalledLocation -Value $InstalledLocation
        }

        $PSGetItemInfo.PSTypeNames.Insert(0, "Microsoft.PowerShell.Commands.PSRepositoryItemInfo")
        $PSGetItemInfo
    }
}