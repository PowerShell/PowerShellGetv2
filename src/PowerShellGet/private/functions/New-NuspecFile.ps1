function New-NuspecFile {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [version]$Version,

        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [string[]]$Authors,

        [Parameter()]
        [string[]]$Owners,

        [Parameter()]
        [string]$ReleaseNotes,

        [Parameter()]
        [bool]$RequireLicenseAcceptance,

        [Parameter()]
        [string]$Copyright,

        [Parameter()]
        [string[]]$Tags,

        [Parameter()]
        [string]$LicenseUrl,

        [Parameter()]
        [string]$ProjectUrl,

        [Parameter()]
        [string]$IconUrl,

        [Parameter()]
        [PSObject[]]$Dependencies,

        [Parameter()]
        [PSObject[]]$Files

    )

    $nameSpaceUri = "http://schemas.microsoft.com/packaging/2011/08/nuspec.xsd"
    [xml]$xml = New-Object System.Xml.XmlDocument

    $xmlDeclaration = $xml.CreateXmlDeclaration("1.0", "utf-8", $null)
    $xml.AppendChild($xmlDeclaration) | Out-Null

    #create top-level elements
    $packageElement = $xml.CreateElement("package", $nameSpaceUri)
    $metaDataElement = $xml.CreateElement("metadata", $nameSpaceUri)

    #truncate tags if they exceed nuspec specifications for size.
    $Tags = $Tags -Join " "

    if ($Tags.Length -gt 4000) {
        $Tags = $Tags.Substring(0, $Tags.LastIndexOf(" "))
        Write-Warning -Message "Nuspec 'Tag' list exceeded max 4000 characters and was truncated."
    }

    $metaDataElementsHash = [ordered]@{
        id                       = $Id
        version                  = $Version
        description              = $Description
        authors                  = $Authors -Join ","
        owners                   = $Owners -Join ","
        releaseNotes             = $ReleaseNotes
        requireLicenseAcceptance = $RequireLicenseAcceptance.ToString().ToLower()
        copyright                = $Copyright
        tags                     = $Tags
        licenseUrl               = $LicenseUrl
        projectUrl               = $ProjectUrl
        iconUrl                  = $IconUrl
    }

    foreach ($key in $metaDataElementsHash.Keys) {
        $element = $xml.CreateElement($key, $nameSpaceUri)
        $elementInnerText = $metaDataElementsHash.item($key)
        $element.InnerText = $elementInnerText

        $metaDataElement.AppendChild($element) | Out-Null
    }


    if ($Dependencies) {
        $dependenciesElement = $xml.CreateElement("dependencies", $nameSpaceUri)

        foreach ($dependency in $Dependencies) {
            $element = $xml.CreateElement("dependency", $nameSpaceUri)
            $element.SetAttribute("id", $dependency.id)
            if ($dependency.version) { $element.SetAttribute("version", $dependency.version) }

            $dependenciesElement.AppendChild($element) | Out-Null
        }
        $metaDataElement.AppendChild($dependenciesElement) | Out-Null
    }

    if ($Files) {
        $filesElement = $xml.CreateElement("files", $nameSpaceUri)

        foreach ($file in $Files) {
            $element = $xml.CreateElement("file", $nameSpaceUri)
            $element.SetAttribute("src", $file.src)
            if ($file.target) { $element.SetAttribute("target", $file.target) }
            if ($file.exclude) { $element.SetAttribute("exclude", $file.exclude) }

            $filesElement.AppendChild($element) | Out-Null
        }
    }

    $packageElement.AppendChild($metaDataElement) | Out-Null
    if ($filesElement) { $packageElement.AppendChild($filesElement) | Out-Null }

    $xml.AppendChild($packageElement) | Out-Null

    $xml.save("$OutputPath\$Id.nuspec")
}
