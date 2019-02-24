function Update-ModuleManifest
{
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(SupportsShouldProcess=$true,
                   PositionalBinding=$false,
                   HelpUri='https://go.microsoft.com/fwlink/?LinkId=619311')]
    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [ValidateNotNullOrEmpty()]
        [Object[]]
        $NestedModules,

        [ValidateNotNullOrEmpty()]
        [Guid]
        $Guid,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Author,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $CompanyName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Copyright,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $RootModule,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Version]
        $ModuleVersion,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Reflection.ProcessorArchitecture]
        $ProcessorArchitecture,

        [Parameter()]
        [ValidateSet('Desktop','Core')]
        [string[]]
        $CompatiblePSEditions,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Version]
        $PowerShellVersion,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Version]
        $ClrVersion,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Version]
        $DotNetFrameworkVersion,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $PowerShellHostName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Version]
        $PowerShellHostVersion,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $RequiredModules,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $TypesToProcess,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $FormatsToProcess,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ScriptsToProcess,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $RequiredAssemblies,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $FileList,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [object[]]
        $ModuleList,

        [Parameter()]
        [string[]]
        $FunctionsToExport,

        [Parameter()]
        [string[]]
        $AliasesToExport,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $VariablesToExport,

        [Parameter()]
        [string[]]
        $CmdletsToExport,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $DscResourcesToExport,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]
        $PrivateData,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Tags,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $ProjectUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $LicenseUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $IconUri,

        [Parameter()]
        [string[]]
        $ReleaseNotes,

        [Parameter()]
        [string]
        $Prerelease,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $HelpInfoUri,

        [Parameter()]
        [switch]
        $PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $DefaultCommandPrefix,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $ExternalModuleDependencies,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $PackageManagementProviders,

        [Parameter()]
        [switch]
        $RequireLicenseAcceptance


    )

    if(-not (Microsoft.PowerShell.Management\Test-Path -Path $Path -PathType Leaf))
    {
        $message = $LocalizedData.UpdateModuleManifestPathCannotFound -f ($Path)
        ThrowError -ExceptionName "System.ArgumentException" `
                   -ExceptionMessage $message `
                   -ErrorId "InvalidModuleManifestFilePath" `
                   -ExceptionObject $Path `
                   -CallerPSCmdlet $PSCmdlet `
                   -ErrorCategory InvalidArgument
    }

    $ModuleManifestHashTable = $null

    try
    {
        $ModuleManifestHashTable = Get-ManifestHashTable -Path $Path -CallerPSCmdlet $PSCmdlet
    }
    catch
    {
        $message = $LocalizedData.TestModuleManifestFail -f ($_.Exception.Message)
        ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId "InvalidModuleManifestFile" `
                    -ExceptionObject $Path `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidArgument
        return
    }

    #Get the original module manifest and migrate all the fields to the new module manifest, including the specified parameter values
    $moduleInfo = $null

    try
    {
        $moduleInfo = Microsoft.PowerShell.Core\Test-ModuleManifest -Path $Path -ErrorAction Stop
    }
    catch
    {
        # Throw an error only if Test-ModuleManifest did not return the PSModuleInfo object.
        # This enables the users to use Update-ModuleManifest cmdlet to update the metadata.
        if(-not $moduleInfo)
        {
            $message = $LocalizedData.TestModuleManifestFail -f ($_.Exception.Message)
            ThrowError -ExceptionName "System.ArgumentException" `
                       -ExceptionMessage $message `
                       -ErrorId "InvalidModuleManifestFile" `
                       -ExceptionObject $Path `
                       -CallerPSCmdlet $PSCmdlet `
                       -ErrorCategory InvalidArgument
            return
        }
    }

    #Params to pass to New-ModuleManifest module
    $params = @{}

    #NestedModules is read-only property
    if($NestedModules)
    {
        $params.Add("NestedModules",$NestedModules)
    }
    elseif($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("NestedModules"))
    {
        $params.Add("NestedModules",$ModuleManifestHashtable.NestedModules)
    }

    #Guid is read-only property
    if($Guid)
    {
        $params.Add("Guid",$Guid)
    }
    elseif($moduleInfo.Guid)
    {
        $params.Add("Guid",$moduleInfo.Guid)
    }

    if($Author)
    {
        $params.Add("Author",$Author)
    }
    elseif($moduleInfo.Author)
    {
        $params.Add("Author",$moduleInfo.Author)
    }

    if($CompanyName)
    {
        $params.Add("CompanyName",$CompanyName)
    }
    elseif($moduleInfo.CompanyName)
    {
        $params.Add("CompanyName",$moduleInfo.CompanyName)
    } 
    else  
    {
        #Creating a unique disposable company name to later be replaced by ''
        #Work-around to deal with New-ModuleManifest changing '' to 'Unknown'
        $params.Add("CompanyName", '__UPDATEDCOMPANYNAMETOBEREPLACEDINFUNCTION__')
    }

    if($Copyright)
    {
        $params.Add("CopyRight",$Copyright)
    }
    elseif($moduleInfo.Copyright)
    {
        $params.Add("Copyright",$moduleInfo.Copyright)
    }

    if($RootModule)
    {
        $params.Add("RootModule",$RootModule)
    }
    elseif($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("RootModule") -and $moduleInfo.RootModule)
    {
        $params.Add("RootModule",$ModuleManifestHashTable.RootModule)
    }

    if($ModuleVersion)
    {
        $params.Add("ModuleVersion",$ModuleVersion)
    }
    elseif($moduleInfo.Version)
    {
        $params.Add("ModuleVersion",$moduleInfo.Version)
    }

    if($Description)
    {
        $params.Add("Description",$Description)
    }
    elseif($moduleInfo.Description)
    {
        $params.Add("Description",$moduleInfo.Description)
    }

    if($ProcessorArchitecture)
    {
        $params.Add("ProcessorArchitecture",$ProcessorArchitecture)
    }
    #Check if ProcessorArchitecture has a value and is not 'None' on lower version PS
    elseif($moduleInfo.ProcessorArchitecture -and $moduleInfo.ProcessorArchitecture -ne 'None')
    {
        $params.Add("ProcessorArchitecture",$moduleInfo.ProcessorArchitecture)
    }

    if($PowerShellVersion)
    {
        $params.Add("PowerShellVersion",$PowerShellVersion)
    }
    elseif($moduleinfo.PowerShellVersion)
    {
        $params.Add("PowerShellVersion",$moduleinfo.PowerShellVersion)
    }

    if($ClrVersion)
    {
        $params.Add("ClrVersion",$ClrVersion)
    }
    elseif($moduleInfo.ClrVersion)
    {
        $params.Add("ClrVersion",$moduleInfo.ClrVersion)
    }

    if($DotNetFrameworkVersion)
    {
        $params.Add("DotNetFrameworkVersion",$DotNetFrameworkVersion)
    }
    elseif($moduleInfo.DotNetFrameworkVersion)
    {
        $params.Add("DotNetFrameworkVersion",$moduleInfo.DotNetFrameworkVersion)
    }

    if($PowerShellHostName)
    {
        $params.Add("PowerShellHostName",$PowerShellHostName)
    }
    elseif($moduleInfo.PowerShellHostName)
    {
        $params.Add("PowerShellHostName",$moduleInfo.PowerShellHostName)
    }

    if($PowerShellHostVersion)
    {
        $params.Add("PowerShellHostVersion",$PowerShellHostVersion)
    }
    elseif($moduleInfo.PowerShellHostVersion)
    {
        $params.Add("PowerShellHostVersion",$moduleInfo.PowerShellHostVersion)
    }

    if($RequiredModules)
    {
        $params.Add("RequiredModules",$RequiredModules)
    }
    elseif($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("RequiredModules") -and $moduleInfo.RequiredModules)
    {
        $params.Add("RequiredModules",$ModuleManifestHashtable.RequiredModules)
    }

    if($TypesToProcess)
    {
        $params.Add("TypesToProcess",$TypesToProcess)
    }
    elseif($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("TypesToProcess") -and $moduleInfo.ExportedTypeFiles)
    {
        $params.Add("TypesToProcess",$ModuleManifestHashTable.TypesToProcess)
    }

    if($FormatsToProcess)
    {
        $params.Add("FormatsToProcess",$FormatsToProcess)
    }
    elseif($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("FormatsToProcess") -and $moduleInfo.ExportedFormatFiles)
    {
        $params.Add("FormatsToProcess",$ModuleManifestHashTable.FormatsToProcess)
    }

    if($ScriptsToProcess)
    {
        $params.Add("ScriptsToProcess",$ScriptstoProcess)
    }
    elseif($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("ScriptsToProcess") -and $moduleInfo.Scripts)
    {
        $params.Add("ScriptsToProcess",$ModuleManifestHashTable.ScriptsToProcess)
    }

    if($RequiredAssemblies)
    {
        $params.Add("RequiredAssemblies",$RequiredAssemblies)
    }
    elseif($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("RequiredAssemblies") -and $moduleInfo.RequiredAssemblies)
    {
        $params.Add("RequiredAssemblies",$moduleInfo.RequiredAssemblies)
    }

    if($FileList)
    {
        $params.Add("FileList",$FileList)
    }
    elseif($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("FileList") -and $moduleInfo.FileList)
    {
        $params.Add("FileList",$ModuleManifestHashTable.FileList)
    }

    #Make sure every path defined under FileList is within module base
    $moduleBase = $moduleInfo.ModuleBase
    foreach($file in $params["FileList"])
    {
        #If path is not root path, append the module base to it and check if the file exists
        if(-not [System.IO.Path]::IsPathRooted($file))
        {
            $combinedPath = Join-Path $moduleBase -ChildPath $file
        }
        else
        {
            $combinedPath = $file
        }
        if(-not (Microsoft.PowerShell.Management\Test-Path -Type Leaf -LiteralPath $combinedPath))
        {
            $message = $LocalizedData.FilePathInFileListNotWithinModuleBase -f ($file,$moduleBase)
            ThrowError -ExceptionName "System.ArgumentException" `
               -ExceptionMessage $message `
               -ErrorId "FilePathInFileListNotWithinModuleBase" `
               -ExceptionObject $file `
               -CallerPSCmdlet $PSCmdlet `
               -ErrorCategory InvalidArgument

            return
        }
    }

    if($ModuleList)
    {
        $params.Add("ModuleList",$ModuleList)
    }
    elseif($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("ModuleList") -and $moduleInfo.ModuleList)
    {
        $params.Add("ModuleList",$ModuleManifestHashtable.ModuleList)
    }

    if($FunctionsToExport -or $FunctionsToExport -is [array])
    {
        $params.Add("FunctionsToExport",$FunctionsToExport)
    }
    elseif($moduleInfo.ExportedFunctions)
    {
        #Get the original module info from ManifestHashTable
        if($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("FunctionsToExport") -and $ModuleManifestHashTable['FunctionsToExport'] -eq '*' `
            -and $moduleInfo.ExportedFunctions.Keys.Count -eq 0)
        {
            $params.Add("FunctionsToExport", $ModuleManifestHashTable['FunctionsToExport'])
        }
        elseif($moduleInfo.Prefix)
        {
            #Earlier call to Test-ModuleManifest adds prefix to functions, now those prefixes need to be remove
            #Prefixes are affixed to the beginning of function, or after '-'
            $originalFunctions = $moduleInfo.ExportedFunctions.Keys | 
                foreach-object { $parts = $_ -split '-', 2; $parts[-1] = $parts[-1] -replace "^$($moduleInfo.Prefix)"; $parts -join '-' }
            $params.Add("FunctionsToExport", $originalFunctions)
        }
        else 
        {
            $params.Add("FunctionsToExport",($moduleInfo.ExportedFunctions.Keys -split ' '))
        }
    }
    elseif ($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("FunctionsToExport"))
    {
        $params.Add("FunctionsToExport", $ModuleManifestHashTable['FunctionsToExport'])
    }

    if($AliasesToExport -or $AliasesToExport -is [array])
    {
        $params.Add("AliasesToExport",$AliasesToExport)
    }
    elseif($moduleInfo.ExportedAliases)
    {
        #Get the original module info from ManifestHashTable
        if($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("AliasesToExport") -and $ModuleManifestHashTable['AliasesToExport'] -eq '*' `
            -and $moduleInfo.ExportedAliases.Keys.Count -eq 0)
        {
            $params.Add("AliasesToExport", $ModuleManifestHashTable['AliasesToExport'])
        }
        elseif($moduleInfo.Prefix)
        {
            #Earlier call to Test-ModuleManifest adds prefix to aliases, now those prefixes need to be removed
            #Prefixes are affixed to the beginning of function, or after '-'
            $originalAliases = $moduleInfo.ExportedAliases.Keys | 
                ForEach-Object { $parts = $_ -split '-', 2; $parts[-1] = $parts[-1] -replace "^$($moduleInfo.Prefix)"; $parts -join '-' }
            $params.Add("AliasesToExport", $originalAliases)   
        }
        else 
        {
            $params.Add("AliasesToExport",($moduleInfo.ExportedAliases.Keys -split ' '))
        }
    }
    elseif ($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("AliasesToExport"))
    {
        $params.Add("AliasesToExport", $ModuleManifestHashTable['AliasesToExport'])
    }

    if($VariablesToExport)
    {
        $params.Add("VariablesToExport",$VariablesToExport)
    }
    elseif($moduleInfo.ExportedVariables)
    {
         #Get the original module info from ManifestHashTable
        if($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("VariablesToExport") -and $ModuleManifestHashTable['VariablesToExport'] -eq '*' `
            -and $moduleInfo.ExportedVariables.Keys.Count -eq 0)
        {
            $params.Add("VariablesToExport", $ModuleManifestHashTable['VariablesToExport'])
        }
        else {
            #Since $moduleInfo.ExportedAliases is a hashtable, we need to take the name of the
            #variables and make them into a list
            $params.Add("VariablesToExport",($moduleInfo.ExportedVariables.Keys -split ' '))
        }
    }

    if($CmdletsToExport -or $CmdletsToExport -is [array])
    {
        $params.Add("CmdletsToExport", $CmdletsToExport)
    }
    elseif($moduleInfo.ExportedCmdlets)
    {
        #Get the original module info from ManifestHashTable
        if($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("CmdletsToExport") -and $ModuleManifestHashTable['CmdletsToExport'] -eq '*' `
          -and $moduleInfo.ExportedCmdlets.Count -eq 0)
        {
            $params.Add("CmdletsToExport", $ModuleManifestHashTable['CmdletsToExport'])
        }
        elseif($moduleInfo.Prefix)
        {
            #Earlier call to Test-ModuleManifest adds prefix to cmdlets, now those prefixes need to be removed
            #Prefixes are affixed to the beginning of function, or after '-'
            $originalCmdlets = $moduleInfo.ExportedCmdlets.Keys | 
                ForEach-Object { $parts = $_ -split '-', 2; $parts[-1] = $parts[-1] -replace "^$($moduleInfo.Prefix)"; $parts -join '-' }
            $params.Add("CmdletsToExport", $originalCmdlets)
        }
        else
        {
            $params.Add("CmdletsToExport",($moduleInfo.ExportedCmdlets.Keys -split ' '))
        }
    }
    elseif ($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("CmdletsToExport"))
    {
        $params.Add("CmdletsToExport", $ModuleManifestHashTable['CmdletsToExport'])
    }

    if($DscResourcesToExport)
    {
        #DscResourcesToExport field is not available in PowerShell version lower than 5.0

        if  (($PSVersionTable.PSVersion -lt '5.0.0') -or ($PowerShellVersion -and $PowerShellVersion -lt '5.0') `
             -or (-not $PowerShellVersion -and $moduleInfo.PowerShellVersion -and $moduleInfo.PowerShellVersion -lt '5.0') `
             -or (-not $PowerShellVersion -and -not $moduleInfo.PowerShellVersion))
        {
                ThrowError -ExceptionName "System.ArgumentException" `
                   -ExceptionMessage $LocalizedData.ExportedDscResourcesNotSupportedOnLowerPowerShellVersion `
                   -ErrorId "ExportedDscResourcesNotSupported" `
                   -ExceptionObject $DscResourcesToExport `
                   -CallerPSCmdlet $PSCmdlet `
                   -ErrorCategory InvalidArgument
                return
        }

        $params.Add("DscResourcesToExport",$DscResourcesToExport)
    }
    elseif(Microsoft.PowerShell.Utility\Get-Member -InputObject $moduleInfo -name "ExportedDscResources")
    {
        if($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("DscResourcesToExport") -and $ModuleManifestHashTable['DscResourcesToExport'] -eq '*' `
                -and $moduleInfo.ExportedDscResources.Count -eq 0)
        {
            $params.Add("DscResourcesToExport", $ModuleManifestHashTable['DscResourcesToExport']) 
        }
        else 
        {
            $params.Add("DscResourcesToExport", $moduleInfo.ExportedDscResources)
        }
    }

    if($CompatiblePSEditions)
    {
        # CompatiblePSEditions field is not available in PowerShell version lower than 5.1
        #
        if  (($PSVersionTable.PSVersion -lt '5.1.0') -or ($PowerShellVersion -and $PowerShellVersion -lt '5.1') `
             -or (-not $PowerShellVersion -and $moduleInfo.PowerShellVersion -and $moduleInfo.PowerShellVersion -lt '5.1') `
             -or (-not $PowerShellVersion -and -not $moduleInfo.PowerShellVersion))
        {
                ThrowError -ExceptionName 'System.ArgumentException' `
                           -ExceptionMessage $LocalizedData.CompatiblePSEditionsNotSupportedOnLowerPowerShellVersion `
                           -ErrorId 'CompatiblePSEditionsNotSupported' `
                           -ExceptionObject $CompatiblePSEditions `
                           -CallerPSCmdlet $PSCmdlet `
                           -ErrorCategory InvalidArgument
                return
        }

        $params.Add('CompatiblePSEditions', $CompatiblePSEditions)
    }
    elseif( (Microsoft.PowerShell.Utility\Get-Member -InputObject $moduleInfo -name 'CompatiblePSEditions') -and
            $moduleInfo.CompatiblePSEditions)
    {
        $params.Add('CompatiblePSEditions', $moduleInfo.CompatiblePSEditions)
    }

    if($HelpInfoUri)
    {
        $params.Add("HelpInfoUri",$HelpInfoUri)
    }
    elseif($moduleInfo.HelpInfoUri)
    {
        $params.Add("HelpInfoUri",$moduleInfo.HelpInfoUri)
    }

    if($DefaultCommandPrefix)
    {
        $params.Add("DefaultCommandPrefix",$DefaultCommandPrefix)
    }
    elseif($ModuleManifestHashTable -and $ModuleManifestHashTable.ContainsKey("DefaultCommandPrefix") -and $ModuleManifestHashTable.DefaultCommandPrefix)
    {
        $params.Add("DefaultCommandPrefix",$ModuleManifestHashTable.DefaultCommandPrefix)
    }

    #Create a temp file within the directory and generate a new temporary manifest with the input
    $tempPath = Microsoft.PowerShell.Management\Join-Path -Path $moduleInfo.ModuleBase -ChildPath "PSGet_$($moduleInfo.Name).psd1"
    $params.Add("Path",$tempPath)

    try
    {
        #Terminates if there is error creating new module manifest
        try{
            Microsoft.PowerShell.Core\New-ModuleManifest @params -Confirm:$false -WhatIf:$false
            #If company name is the disposable name created for the new module manifest, it will be changed back to ''
            (Get-Content -Path $tempPath) | ForEach-Object {$_ -Replace '__UPDATEDCOMPANYNAMETOBEREPLACEDINFUNCTION__', ''} | Set-Content -Path $tempPath -Confirm:$false -WhatIf:$false
        }
        catch
        {
            $ErrorMessage = $LocalizedData.UpdatedModuleManifestNotValid -f ($Path, $_.Exception.Message)
            ThrowError -ExceptionName "System.ArgumentException" `
                       -ExceptionMessage $ErrorMessage `
                       -ErrorId "NewModuleManifestFailure" `
                       -ExceptionObject $params `
                       -CallerPSCmdlet $PSCmdlet `
                       -ErrorCategory InvalidArgument
            return
        }

        #Manually update the section in PrivateData since New-ModuleManifest works differently on different PS version
        $PrivateDataInput = ""
        $ExistingData = $moduleInfo.PrivateData
        $Data = @{}
        if($ExistingData)
        {
            foreach($key in $ExistingData.Keys)
            {
                if($key -ne "PSData"){
                    $Data.Add($key,$ExistingData[$key])
                }
                else
                {
                    $PSData = $ExistingData["PSData"]
                    foreach($entry in $PSData.Keys)
                    {
                        $Data.Add($entry,$PSData[$Entry])
                    }
                }
            }
        }

        if($PrivateData)
        {
            foreach($key in $PrivateData.Keys)
            {
                #if user provides PSData within PrivateData, we will parse through the PSData
                if($key -ne "PSData")
                {
                    $Data[$key] = $PrivateData[$Key]
                }

                else
                {
                    $PSData = $ExistingData["PSData"]
                    foreach($entry in $PSData.Keys)
                    {
                        $Data[$entry] = $PSData[$entry]
                    }
                }
            }
        }

        #Tags is a read-only property
        if($Tags)
        {
           $Data["Tags"] = $Tags
        }

        #The following Uris and ReleaseNotes cannot be empty
        if($ProjectUri)
        {
            $Data["ProjectUri"] = $ProjectUri
        }

        if($LicenseUri)
        {
            $Data["LicenseUri"] = $LicenseUri
        }

        if($IconUri)
        {
            $Data["IconUri"] = $IconUri
        }
        if($RequireLicenseAcceptance)
        {
            $Data["RequireLicenseAcceptance"] = $RequireLicenseAcceptance
        }

        if($ReleaseNotes)
        {
            #If value is provided as an array, we append the string.
            $Data["ReleaseNotes"] = $($ReleaseNotes -join "`r`n")
        }

        if ($Prerelease)
        {
            $result = ValidateAndGet-VersionPrereleaseStrings -Version $params["ModuleVersion"] -Prerelease $Prerelease -CallerPSCmdlet $PSCmdlet
            if (-not $result)
            {
                # ValidateAndGet-VersionPrereleaseStrings throws the error.
                # returning to avoid further execution when different values are specified for -ErrorAction parameter
                return
            }
            $validatedPrerelease = $result["Prerelease"]
            $Data[$script:Prerelease] = $validatedPrerelease
        }

        if($ExternalModuleDependencies)
        {
            #ExternalModuleDependencies have to be specified either under $RequiredModules or $NestedModules
            #Extract all the module names specified in the moduleInfo of NestedModules and RequiredModules
            $DependentModuleNames = @()
            foreach($moduleInfo in $params["NestedModules"])
            {
                if($moduleInfo.GetType() -eq [System.Collections.Hashtable])
                {
                    $DependentModuleNames += $moduleInfo.ModuleName
                }
            }

            foreach($moduleInfo in $params["RequiredModules"])
            {
                if($moduleInfo.GetType() -eq [System.Collections.Hashtable])
                {
                    $DependentModuleNames += $moduleInfo.ModuleName
                }
            }

            foreach($dependency in $ExternalModuleDependencies)
            {
                if($params["NestedModules"] -notcontains $dependency -and
                $params["RequiredModules"] -notContains $dependency -and
                $DependentModuleNames -notcontains $dependency)
                {
                    $message = $LocalizedData.ExternalModuleDependenciesNotSpecifiedInRequiredOrNestedModules -f ($dependency)
                    ThrowError -ExceptionName "System.ArgumentException" `
                        -ExceptionMessage $message `
                        -ErrorId "InvalidExternalModuleDependencies" `
                        -ExceptionObject $Exception `
                        -CallerPSCmdlet $PSCmdlet `
                        -ErrorCategory InvalidArgument
                        return
                    }
            }
            if($Data.ContainsKey("ExternalModuleDependencies"))
            {
                $Data["ExternalModuleDependencies"] = $ExternalModuleDependencies
            }
            else
            {
                $Data.Add("ExternalModuleDependencies", $ExternalModuleDependencies)
            }
        }
        if($PackageManagementProviders)
        {
            #Check if the provided value is within the relative path
            $ModuleBase = Microsoft.PowerShell.Management\Split-Path $Path -Parent
            $Files = Microsoft.PowerShell.Management\Get-ChildItem -Path $ModuleBase
            foreach($provider in $PackageManagementProviders)
            {
                if ($Files.Name -notcontains $provider)
                {
                    $message = $LocalizedData.PackageManagementProvidersNotInModuleBaseFolder -f ($provider,$ModuleBase)
                    ThrowError -ExceptionName "System.ArgumentException" `
                               -ExceptionMessage $message `
                               -ErrorId "InvalidPackageManagementProviders" `
                               -ExceptionObject $PackageManagementProviders `
                               -CallerPSCmdlet $PSCmdlet `
                               -ErrorCategory InvalidArgument
                    return
                }
            }

            $Data["PackageManagementProviders"] = $PackageManagementProviders
        }
        $PrivateDataInput = Get-PrivateData -PrivateData $Data

        #Replace the PrivateData section by first locating the linenumbers of start line and endline.
        $PrivateDataBegin = Select-String -Path $tempPath -Pattern "PrivateData ="
        $PrivateDataBeginLine = $PrivateDataBegin.LineNumber

        $newManifest = Microsoft.PowerShell.Management\Get-Content -Path $tempPath
        #Look up the endline of PrivateData section by finding the matching brackets since private data could
        #consist of multiple pairs of brackets.
        $PrivateDataEndLine=0
        if($PrivateDataBegin -match "@{")
        {
            $leftBrace = 0
            $EndLineOfFile = $newManifest.Length-1

            For($i = $PrivateDataBeginLine;$i -lt $EndLineOfFile; $i++)
            {
                if($newManifest[$i] -match "{")
                {
                    $leftBrace ++
                }
                elseif($newManifest[$i] -match "}")
                {
                    if($leftBrace -gt 0)
                    {
                        $leftBrace --
                    }
                    else
                    {
                       $PrivateDataEndLine = $i
                       break
                    }
                }
            }
        }


        try
        {
            if($PrivateDataEndLine -ne 0)
            {
                #If PrivateData section has more than one line, we will remove the old content and insert the new PrivataData
                $newManifest  | where {$_.readcount -le $PrivateDataBeginLine -or $_.readcount -gt $PrivateDataEndLine+1} `
                | ForEach-Object {
                    $_
                    if($_ -match "PrivateData = ")
                    {
                        $PrivateDataInput
                    }
                  } | Set-Content -Path $tempPath -Confirm:$false -WhatIf:$false
            }

            #In lower version, PrivateData is just a single line
            else
            {
                $PrivateDataForDownlevelPS = "PrivateData = @{ `n"+$PrivateDataInput

                $newManifest  | where {$_.readcount -le $PrivateDataBeginLine -or $_.readcount -gt $PrivateDataBeginLine } `
                | ForEach-Object {
                    $_
                    if($_ -match "PrivateData = ")
                    {
                       $PrivateDataForDownlevelPS
                    }
                } | Set-Content -Path $tempPath -Confirm:$false -WhatIf:$false
            }

            #Verify the new module manifest is valid
            $testModuleInfo = Microsoft.PowerShell.Core\Test-ModuleManifest -Path $tempPath `
                                                                        -Verbose:$VerbosePreference ` -ErrorAction Stop
        }
        #Catch the exceptions from Test-ModuleManifest
        catch
        {
            $message = $LocalizedData.UpdatedModuleManifestNotValid -f ($Path, $_.Exception.Message)

            ThrowError -ExceptionName "System.ArgumentException" `
                       -ExceptionMessage $message `
                       -ErrorId "UpdateManifestFileFail" `
                       -ExceptionObject $_.Exception `
                       -CallerPSCmdlet $PSCmdlet `
                       -ErrorCategory InvalidArgument
            return
        }


        $newContent = Microsoft.PowerShell.Management\Get-Content -Path $tempPath

        #Remove the PSGet_ prepended to the original manifest name due to the temp file name
        $newContent[1] = $newContent[1] -replace "'PSGet_", "'"

        try
        {
            #Ask for confirmation of the new manifest before replacing the original one
            if($PSCmdlet.ShouldProcess($Path,$LocalizedData.UpdateManifestContentMessage+$newContent))
            {
                Microsoft.PowerShell.Management\Set-Content -Path $Path -Value $newContent -Confirm:$false -WhatIf:$false
            }

            #Return the new content if -PassThru is specified
            if($PassThru)
            {
                return $newContent
            }
        }
        catch
        {
            $message = $LocalizedData.ManifestFileReadWritePermissionDenied -f ($Path)
            ThrowError -ExceptionName "System.ArgumentException" `
                        -ExceptionMessage $message `
                        -ErrorId "ManifestFileReadWritePermissionDenied" `
                        -ExceptionObject $Path `
                        -CallerPSCmdlet $PSCmdlet `
                        -ErrorCategory InvalidArgument
        }
    }
    finally
    {
        Microsoft.PowerShell.Management\Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
    }
}