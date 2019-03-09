function Get-PrivateData
#Utility function to help form the content string for PrivateData
{
    param
    (
        [System.Collections.Hashtable]
        $PrivateData
    )

    if($PrivateData.Keys.Count -eq 0)
    {
        $content = "
    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = `$false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable"
        return $content
    }


    #Validate each of the property of PSData is of the desired data type
    $Tags= $PrivateData["Tags"] -join "','" | Foreach-Object {"'$_'"}
    $LicenseUri = $PrivateData["LicenseUri"]| Foreach-Object {"'$_'"}
    $ProjectUri = $PrivateData["ProjectUri"] | Foreach-Object {"'$_'"}
    $IconUri = $PrivateData["IconUri"] | Foreach-Object {"'$_'"}
    $ReleaseNotesEscape = $PrivateData["ReleaseNotes"] -Replace "'","''"
    $ReleaseNotes = $ReleaseNotesEscape | Foreach-Object {"'$_'"}
    $Prerelease = $PrivateData[$script:Prerelease] | Foreach-Object {"'$_'"}
    $RequireLicenseAcceptance = $PrivateData["RequireLicenseAcceptance"]
    $ExternalModuleDependencies = $PrivateData["ExternalModuleDependencies"] -join "','" | Foreach-Object {"'$_'"}
    $DefaultProperties = @("Tags","LicenseUri","ProjectUri","IconUri","ReleaseNotes",$script:Prerelease,"ExternalModuleDependencies","RequireLicenseAcceptance")

    $ExtraProperties = @()
    foreach($key in $PrivateData.Keys)
    {
        if($DefaultProperties -notcontains $key)
        {
            $PropertyString = "#"+"$key"+ " of this module"
            $PropertyString += "`r`n    "
            if(($PrivateData[$key]).GetType().IsArray)
            {
                $PropertyString += $key +" = " +" @("
                $PrivateData[$key] | Foreach-Object { $PropertyString += "'" + $_ +"'" + "," }
                if($PrivateData[$key].Length -ge 1)
                {
                    #Remove extra ,
                    $PropertyString = $PropertyString -Replace ".$"
                }
                $PropertyString += ")"
            }
            else
            {
                $PropertyString += $key +" = " + "'"+$PrivateData[$key]+"'"
            }

            $ExtraProperties += ,$PropertyString
        }
    }

    $ExtraPropertiesString = ""
    $firstProperty = $true
    foreach($property in $ExtraProperties)
    {
        if($firstProperty)
        {
            $firstProperty = $false
        }
        else
        {
            $ExtraPropertiesString += "`r`n`r`n    "
        }
        $ExtraPropertiesString += $Property
    }

    $TagsLine ="# Tags = @()"
    if($Tags -ne "''")
    {
        $TagsLine = "Tags = "+$Tags
    }
    $LicenseUriLine = "# LicenseUri = ''"
    if($LicenseUri -ne "''")
    {
        $LicenseUriLine = "LicenseUri = "+$LicenseUri
    }
    $ProjectUriLine = "# ProjectUri = ''"
    if($ProjectUri -ne "''")
    {
        $ProjectUriLine = "ProjectUri = " +$ProjectUri
    }
    $IconUriLine = "# IconUri = ''"
    if($IconUri -ne "''")
    {
        $IconUriLine = "IconUri = " +$IconUri
    }
    $ReleaseNotesLine = "# ReleaseNotes = ''"
    if($ReleaseNotes -ne "''")
    {
        $ReleaseNotesLine = "ReleaseNotes = "+$ReleaseNotes
    }
    $PrereleaseLine = "# Prerelease = ''"
    if ($Prerelease -ne "''")
    {
        $PrereleaseLine = "Prerelease = " +$Prerelease
    }

    $RequireLicenseAcceptanceLine = "# RequireLicenseAcceptance = `$false"
    if($RequireLicenseAcceptance)
    {
        $RequireLicenseAcceptanceLine = "RequireLicenseAcceptance = `$true"
    }

    $ExternalModuleDependenciesLine ="# ExternalModuleDependencies = @()"
    if($ExternalModuleDependencies -ne "''")
    {
        $ExternalModuleDependenciesLine = "ExternalModuleDependencies = @($ExternalModuleDependencies)"
    }

    if(-not $ExtraPropertiesString -eq "")
    {
        $Content = "
    ExtraProperties

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        $TagsLine

        # A URL to the license for this module.
        $LicenseUriLine

        # A URL to the main website for this project.
        $ProjectUriLine

        # A URL to an icon representing this module.
        $IconUriLine

        # ReleaseNotes of this module
        $ReleaseNotesLine

        # Prerelease string of this module
        $PrereleaseLine

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        $RequireLicenseAcceptanceLine

        # External dependent modules of this module
        $ExternalModuleDependenciesLine

    } # End of PSData hashtable

} # End of PrivateData hashtable"

        #Replace the Extra PrivateData in the block
        $Content -replace "ExtraProperties", $ExtraPropertiesString
    }
    else
    {
        $content = "
    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        $TagsLine

        # A URL to the license for this module.
        $LicenseUriLine

        # A URL to the main website for this project.
        $ProjectUriLine

        # A URL to an icon representing this module.
        $IconUriLine

        # ReleaseNotes of this module
        $ReleaseNotesLine

        # Prerelease string of this module
        $PrereleaseLine

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        $RequireLicenseAcceptanceLine

        # External dependent modules of this module
        $ExternalModuleDependenciesLine

    } # End of PSData hashtable

 } # End of PrivateData hashtable"
        return $content
    }
}