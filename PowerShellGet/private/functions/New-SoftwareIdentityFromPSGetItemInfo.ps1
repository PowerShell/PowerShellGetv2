function New-SoftwareIdentityFromPSGetItemInfo
{
    param
    (
        [Parameter(Mandatory=$true)]
        $PSGetItemInfo
    )

    $SourceLocation = $psgetItemInfo.RepositorySourceLocation

    if(Get-Member -InputObject $PSGetItemInfo -Name $script:PSArtifactType)
    {
        $artifactType = $psgetItemInfo.Type
    }
    else
    {
        $artifactType = $script:PSArtifactTypeModule
    }

    $fastPackageReference = New-FastPackageReference -ProviderName (Get-ProviderName -PSCustomObject $psgetItemInfo) `
                                                     -PackageName $psgetItemInfo.Name `
                                                     -Version $psgetItemInfo.Version `
                                                     -Source $SourceLocation `
                                                     -ArtifactType $artifactType

    $links = New-Object -TypeName  System.Collections.ArrayList
    if($psgetItemInfo.IconUri)
    {
        $links.Add( (New-Link -Href $psgetItemInfo.IconUri -RelationShip "icon") )
    }

    if($psgetItemInfo.LicenseUri)
    {
        $links.Add( (New-Link -Href $psgetItemInfo.LicenseUri -RelationShip "license") )
    }

    if($psgetItemInfo.ProjectUri)
    {
        $links.Add( (New-Link -Href $psgetItemInfo.ProjectUri -RelationShip "project") )
    }

    $entities = New-Object -TypeName  System.Collections.ArrayList
    if($psgetItemInfo.Author -and $psgetItemInfo.Author.ToString())
    {
        $entities.Add( (New-Entity -Name $psgetItemInfo.Author -Role 'author') )
    }

    if($psgetItemInfo.CompanyName -and $psgetItemInfo.CompanyName.ToString())
    {
        $entities.Add( (New-Entity -Name $psgetItemInfo.CompanyName -Role 'owner') )
    }

    $details =  @{
                    description    = $psgetItemInfo.Description
                    copyright      = $psgetItemInfo.Copyright
                    published      = $psgetItemInfo.PublishedDate.ToString()
                    installeddate  = $null
                    updateddate    = $null
                    tags           = $psgetItemInfo.Tags
                    releaseNotes   = $psgetItemInfo.ReleaseNotes
                    PackageManagementProvider = (Get-ProviderName -PSCustomObject $psgetItemInfo)
                 }

    if((Get-Member -InputObject $psgetItemInfo -Name 'InstalledDate') -and $psgetItemInfo.InstalledDate)
    {
        $details['installeddate'] = $psgetItemInfo.InstalledDate.ToString('O', [System.Globalization.DateTimeFormatInfo]::InvariantInfo)
    }

    if((Get-Member -InputObject $psgetItemInfo -Name 'UpdatedDate') -and $psgetItemInfo.UpdatedDate)
    {
        $details['updateddate'] = $psgetItemInfo.UpdatedDate.ToString('O', [System.Globalization.DateTimeFormatInfo]::InvariantInfo)
    }

    if(Get-Member -InputObject $psgetItemInfo -Name $script:InstalledLocation)
    {
        $details[$script:InstalledLocation] = $psgetItemInfo.InstalledLocation
    }

    $details[$script:PSArtifactType] = $artifactType

    $sourceName = Get-SourceName -Location $SourceLocation
    if($sourceName)
    {
        $details["SourceName"] = $sourceName
    }

    $params = @{
                FastPackageReference = $fastPackageReference;
                Name = $psgetItemInfo.Name;
                Version = $psgetItemInfo.Version;
                versionScheme  = "MultiPartNumeric";
                Source = $SourceLocation;
                Summary = $psgetItemInfo.Description;
                Details = $details;
                Entities = $entities;
                Links = $links
               }

    if($sourceName -and $script:PSGetModuleSources[$sourceName].Trusted)
    {
        $params["FromTrustedSource"] = $true
    }

    $sid = New-SoftwareIdentity @params

    return $sid
}