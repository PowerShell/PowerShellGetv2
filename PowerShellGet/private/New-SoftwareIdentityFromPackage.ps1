function New-SoftwareIdentityFromPackage
{
    param
    (
        [Parameter(Mandatory=$true)]
        $Package,

        [Parameter(Mandatory=$true)]
        [string]
        $PackageManagementProviderName,

        [Parameter(Mandatory=$true)]
        [string]
        $SourceLocation,

        [Parameter()]
        [switch]
        $IsFromTrustedSource,

        [Parameter(Mandatory=$true)]
        $request,

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

    $fastPackageReference = New-FastPackageReference -ProviderName $PackageManagementProviderName `
                                                     -PackageName $Package.Name `
                                                     -Version $Package.Version `
                                                     -Source $SourceLocation `
                                                     -ArtifactType $Type

    $links = New-Object -TypeName  System.Collections.ArrayList
    foreach($lnk in $Package.Links)
    {
        if( $lnk.Relationship -eq "icon" -or $lnk.Relationship -eq "license" -or $lnk.Relationship -eq "project" )
        {
            $links.Add( (New-Link -Href $lnk.HRef -RelationShip $lnk.Relationship )  )
        }
    }

    $entities = New-Object -TypeName  System.Collections.ArrayList
    foreach( $entity in $Package.Entities )
    {
        if( $entity.Role -eq "author" -or $entity.Role -eq "owner" )
        {
            $entities.Add( (New-Entity -Name $entity.Name -Role $entity.Role -RegId $entity.RegId -Thumbprint $entity.Thumbprint)  )
        }
    }

    $deps = (new-Object -TypeName  System.Collections.ArrayList)
    foreach( $dep in $pkg.Dependencies )
    {
        # Add each dependency and say it's from this provider.
        $newDep = New-Dependency -ProviderName $script:PSModuleProviderName `
                                 -PackageName $request.Services.ParsePackageName($dep) `
                                 -Version $request.Services.ParsePackageVersion($dep) `
                                 -Source $SourceLocation

        $deps.Add( $newDep )
    }


    $details =  New-Object -TypeName  System.Collections.Hashtable

	foreach ( $key in $Package.Metadata.Keys.LocalName)
	{
		if (!$details.ContainsKey($key))
		{
			$details.Add($key, (Get-First $Package.Metadata[$key]) )
		}
	}

    $details.Add( "PackageManagementProvider" , $PackageManagementProviderName )

    if($InstalledLocation)
    {
        $details.Add( $script:InstalledLocation , $InstalledLocation )
    }

    if($InstalledDate)
    {
        $details.Add( 'installeddate' , $InstalledDate.ToString('O', [System.Globalization.DateTimeFormatInfo]::InvariantInfo) )
    }

    if($UpdatedDate)
    {
        $details.Add( 'updateddate' , $UpdatedDate.ToString('O', [System.Globalization.DateTimeFormatInfo]::InvariantInfo) )
    }

    # Initialize package source name to the source location
    $sourceNameForSoftwareIdentity = $SourceLocation

    $sourceName = (Get-SourceName -Location $SourceLocation)

    if($sourceName)
    {
        $details.Add( "SourceName" , $sourceName )

        # Override the source name only if we are able to map source location to source name
        $sourceNameForSoftwareIdentity = $sourceName
    }

    $params = @{FastPackageReference = $fastPackageReference;
                Name = $Package.Name;
                Version = $Package.Version;
                versionScheme  = "MultiPartNumeric";
                Source = $sourceNameForSoftwareIdentity;
                Summary = $Package.Summary;
                SearchKey = $Package.Name;
                FullPath = $Package.FullPath;
                FileName = $Package.Name;
                Details = $details;
                Entities = $entities;
                Links = $links;
                Dependencies = $deps;
               }

    if($IsFromTrustedSource)
    {
        $params["FromTrustedSource"] = $true
    }

    $sid = New-SoftwareIdentity @params

    return $sid
}