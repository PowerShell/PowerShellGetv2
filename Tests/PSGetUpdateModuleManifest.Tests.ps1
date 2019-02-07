<#####################################################################################
 # File: PSGetUpdateModuleManifest.ps1
 # Tests for PSGet module functionality
 #
 # Copyright (c) Microsoft Corporation, 2015
 #####################################################################################>

<#
   Name: PowerShell.PSGet.UpdateModuleManifestTests
   Description: Tests for Update-ModuleManifest functionality

#>

Describe PowerShell.PSGet.UpdateModuleManifest -Tags 'BVT','InnerLoop' {

    BeforeAll {
        Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
        Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue
        $script:TempPath = Get-TempPath
        $script:psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
    }

    BeforeEach {
        # Create temp moduleManifest to be updated
        $script:TempModulesPath = Join-Path $script:TempPath "PSGet_$(Get-Random)"
        $null = New-Item -Path $script:TempModulesPath -ItemType Directory -Force

        $script:UpdateModuleManifestName = "ContosoPublishModule"
        $script:UpdateModuleManifestBase = Join-Path $script:TempModulesPath $script:UpdateModuleManifestName
        $null = New-Item -Path $script:UpdateModuleManifestBase -ItemType Directory -Force

        $script:testManifestPath = Microsoft.PowerShell.Management\Join-Path -Path $script:UpdateModuleManifestBase -ChildPath "$script:UpdateModuleManifestName.psd1"
    }

    AfterEach {
        RemoveItem "$script:TempModulesPath\*"
    }
    
    
    # Purpose: Validate Update-ModuleManifest will keep the properties the same as with the original manifest using PowerShellGet module as test.
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] 
    #
    # Expected Result: The updated manifest should have the same proerty values.
    #
    It UpdateModuleManifestWithNoAdditionalParameters {
        
        #Copy the PowerShellGet module to temp folder and test properties update validations
        $script:PSGetModulePath = Join-Path $script:TempModulesPath "PowerShellGet" 
        $null = New-Item -Path $script:PSGetModulePath -ItemType Directory -Force
        Copy-Item -Path "$($script:psgetModuleInfo.ModuleBase)\*" -Destination $script:PSGetModulePath -Recurse -Force
        $PSGetManifestPath = Join-Path "$script:PSGetModulePath" "PowerShellGet.psd1"

        #Remove item read-only property
        Set-ItemProperty $PSGetManifestPath -Name IsReadOnly -Value $false

        $oldModuleInfo = Test-ModuleManifest -Path $PSGetManifestPath
        Update-ModuleManifest -path $PSGetManifestPath
        $newModuleInfo = Test-ModuleManifest -Path $PSGetManifestPath

        AssertEquals $newModuleInfo.Guid $oldModuleInfo.Guid "Guid should be $($oldModuleInfo.Guid)"
        AssertEquals $newModuleInfo.Author $oldModuleInfo.Author "Author name should be $($oldModuleInfo.Author)"
        AssertEquals $newModuleInfo.CompanyName $oldModuleInfo.CompanyName "Company name should be $($oldModuleInfo.CompanyName)"
        AssertEquals $newModuleInfo.CopyRight $oldModuleInfo.CopyRight "Copyright should be $($oldModuleInfo.CopyRight)"
        AssertEquals $newModuleInfo.RootModule $oldModuleInfo.RootModule "RootModule should be $($oldModuleInfo.RootModule)"
        AssertEquals $newModuleInfo.Version $oldModuleInfo.Version "Module version should be $($oldModuleInfo.Version)"
        AssertEquals $newModuleInfo.Description $oldModuleInfo.Description "Description should be $($oldModuleInfo.Description)"
        AssertEquals $newModuleInfo.ProcessorArchitecture $oldModuleInfo.ProcessorArchitecture "Processor architecture name should be $($oldModuleInfo.ProcessorArchitecture)"
        AssertEquals $newModuleInfo.ClrVersion $oldModuleInfo.ClrVersion "ClrVersion should be $($oldModuleInfo.ClrVersion)"
        AssertEquals $newModuleInfo.DotNetFrameworkVersion $oldModuleInfo.DotNetFrameworkVersion "Dot Net Framework version should be $($oldModuleInfo.DotNetFrameworkVersion)"
        AssertEquals $newModuleInfo.PowerShellHostVersion $oldModuleInfo.PowerShellHostVersion "PowerShell Host Version should be $($oldModuleInfo.PowerShellHostVersion)"
        AssertEquals $newModuleInfo.PowerShellHostVersion $oldModuleInfo.PowerShellHostVersion "PowerShell Host Version should be $($oldModuleInfo.PowerShellHostVersion)"
        AssertEquals $newModuleInfo.ProjectUri $oldModuleInfo.ProjectUri "ProjectUri should be $($oldModuleInfo.ProjectUri)"
        AssertEquals $newModuleInfo.LicenseUri $oldModuleInfo.LicenseUri "LicenseUri should be $($oldModuleInfo.LicenseUri)"
        AssertEquals $newModuleInfo.IconUri $oldModuleInfo.IconUri "IconUri should be $($oldModuleInfo.IconUri)"
        AssertEquals $newModuleInfo.ReleaseNotes $oldModuleInfo.ReleaseNotes "ReleaseNotes should be $($oldModuleInfo.ReleaseNotes)"
        AssertEquals $newModuleInfo.HelpInfoUri $oldModuleInfo.HelpInfoURI "HelpInfoURI should be $($oldModuleInfo.HelpInfoURI)"
        AssertEquals $newModuleInfo.RequiredModules.ModuleType $oldModuleInfo.RequiredModules.ModuleType "RootModule ModuleType should be $($oldModuleInfo.RequiredModules.ModuleType)"
        AssertEquals $newModuleInfo.RequiredModules.Name $oldModuleInfo.RequiredModules.Name "RootModule ModuleType should be $($oldModuleInfo.RequiredModules.Name)"
        AssertEquals $newModuleInfo.ExportedFormatFiles.Count $oldModuleInfo.ExportedFormatFiles.Count "ExportedFormatFiles count should be $($oldModuleInfo.ExportedFormatFiles.Count)"
        Assert ($newModuleInfo.ExportedFormatFiles[0] -match "PSGet.Format.ps1xml") "Exported FormatsFile should contian 'PSGet.Format.ps1xml'"
        Assert ($newModuleInfo.ModueList.Count -eq $oldModuleInfo.ModuleList.Count) "Module list count should be $($oldModuleInfo.ModuleList.Count)";
        AssertEquals $newModuleInfo.ExportedFunctions.Count $oldModuleInfo.ExportedFunctions.Count "ExportedFunctions count should be $($oldModuleInfo.ExportedFunctions.Count)"
        Assert ($newModuleInfo.ExportedFunctions.Keys -contains "Install-Module") "ExportedFunctions should include 'Install-Module')"
        Assert ($newModuleInfo.ExportedFunctions.Keys -contains "Find-Module") "ExportedFunctions should include 'Install-Module')"
        AssertEquals $newModuleInfo.ExportedAliases.Count $oldModuleInfo.ExportedAliases.Count "ExportedAliases count should be $($oldModuleInfo.ExportedAliases.Count)"
        Assert ($newModuleInfo.ExportedAliases.Keys -contains "inmo") "ExportedAliases should include 'inmo')"
        Assert ($newModuleInfo.ExportedAliases.Keys -contains "fimo") "ExportedAliases should include 'fimo')"
        Assert ($newModuleInfo.ExportedAliases.Keys -contains "upmo") "ExportedAliases should include 'upmo')"
        Assert ($newModuleInfo.ExportedAliases.Keys -contains "pumo") "ExportedAliases should include 'pumo')"
        if($PSVersionTable.Version -ge '5.0.0')
        {
            AssertEquals $newModuleInfo.Tags.Count $oldModuleInfo.Tags.Count "Tags count should be $($oldModuleInfo.Tags.Count)"
        }
        AssertEquals $newModuleInfo.FileList.Count $oldModuleInfo.FileList.Count "FileList count should be $($oldModuleInfo.FileList.Count)"
        AssertEquals $newModuleInfo.FileList[0] $oldModuleInfo.FileList[0] "FileList[0] should be $($oldModuleInfo.FileList[0])"
        AssertEquals $newModuleInfo.FileList[1] $oldModuleInfo.FileList[1] "FileList[0] should be $($oldModuleInfo.FileList[1])"
        #Make sure the additioanl properties inside PrivateData remain the same
        AssertEquals $newModuleInfo.PrivateData.PackageManagementProviders $oldModuleInfo.PrivateData.PackageManagementProviders "PackageManagement Providers should be $($oldModuleInfo.PrivateData.PackageManagementProviders)"
        if($newModuleInfo.PrivateData.SupportedPowerShellGetFormatVersions -is [Array])
        {
            AssertEquals $newModuleInfo.PrivateData.SupportedPowerShellGetFormatVersions.Count $oldModuleInfo.PrivateData.SupportedPowerShellGetFormatVersions.Count "SupportedPowerShellGetFormatVersions count should be $($oldModuleInfo.PrivateData.SupportedPowerShellGetFormatVersions.Count)"
            foreach($ver in $oldModuleInfo.PrivateData.SupportedPowerShellGetFormatVersions)
            {                
	            Assert ($newModuleInfo.PrivateData.SupportedPowerShellGetFormatVersions -contains ($ver)) "SupportedPowerShellGetFormatVersions should contain $($ver)"
            }
        }
        else
        {
            AssertEquals $newModuleInfo.PrivateData.SupportedPowerShellGetFormatVersions $oldModuleInfo.PrivateData.SupportedPowerShellGetFormatVersions "SupportedPowerShellGetFormatVersions should be $($oldModuleInfo.PrivateData.SupportedPowerShellGetFormatVersions)"
        }
    } `
    -Skip:$($IsWindows -eq $False)

    # Purpose: Validate Update-ModuleManifest will not reset original parameter values to default values
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] 
    #
    # Expected Result: The updated manifest should have the same property values.
    #
    It UpdateModuleManifestWithNoAdditionalParameters2 {    

        if($PSVersionTable.PSVersion -ge '3.0.0' -and $PSVersionTable.Version -lt '5.0.0')
        {
            New-ModuleManifest -Path $script:testManifestPath -ModuleVersion '1.0' -FunctionsToExport '*' -CmdletsToExport '*' -AliasesToExport '*' -VariablesToExport '*'
            $expectedLength = 4
        }
        else
        {
            New-ModuleManifest -Path $script:testManifestPath -ModuleVersion '1.0' -FunctionsToExport '*' -CmdletsToExport '*' -AliasesToExport '*' -VariablesToExport '*' -DscResourcesToExport '*'
            $expectedLength = 5
        }

        #Edit company name from 'Unknown' to ''
        (get-content $script:testManifestPath) | foreach-object {$_ -replace 'Unknown', ''} | set-content $script:testManifestPath
        $editedModuleInfo = Test-ModuleManifest -Path $script:testManifestPath

        Update-ModuleManifest -path $script:testManifestPath -ModuleVersion '2.0'
        $updatedModuleInfo = Test-ModuleManifest -Path $script:testManifestPath
        
        $text = @(Get-Content -Path $script:testManifestPath | Select-String "\*")

        AssertEquals $updatedModuleInfo.CompanyName $editedModuleInfo.CompanyName "Company name should be $expectedCompanyName"
        AssertEquals $($text.length) $expectedLength "Number of wildcards should be $expectedLength"
    }

    # Purpose: Validate Update-ModuleManifest will not reset original parameter values to default values
    #
    # Action:
    #      Update-ModuleManifest -Path [Path]
    #
    # Expected Result: The updated manifest should have the same property values.
    #
    It UpdateModuleManifestWithNoAdditionalParameters3 {

        New-ModuleManifest -Path $script:testManifestPath -ModuleVersion '1.0' -FunctionsToExport 'function1' -NestedModules 'Microsoft.PowerShell.Management' -AliasesToExport 'alias1'
        Update-ModuleManifest -Path $script:testManifestPath

        Import-LocalizedData -BindingVariable ModuleManifestHashTable `
                     -FileName (Microsoft.PowerShell.Management\Split-Path $script:testManifestPath -Leaf) `
                     -BaseDirectory (Microsoft.PowerShell.Management\Split-Path $script:testManifestPath -Parent) `
                     -ErrorAction SilentlyContinue `
                     -WarningAction SilentlyContinue

        AssertEquals $ModuleManifestHashTable.FunctionsToExport 'function1' "FunctionsToExport should be 'function1'"
        AssertEquals $ModuleManifestHashTable.NestedModules 'Microsoft.PowerShell.Management' "NestedModules should be 'module1'"
        AssertEquals $ModuleManifestHashTable.AliasesToExport 'alias1' "AliasesToExport should be 'alias1'"
    } 

    # Purpose: Validate Update-ModuleManifest will keep the original property values for DefaultCommandPrefix,
    # CmdletsToExport, FunctionsToExport, AliasesToExport, and DSCResourcesToExport
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] 
    #
    # Expected Result: The updated manifest should have the same DefaultCommandPrefix as before, 
    # CmdletsToExport, FunctionsToExport, AliasesToExport, DSCResourcesToExport should not have prefixes affixed
    #                   
    It UpdateModuleManifestWithDefaultCommandPrefix {

        $DefaultCommandPrefix = "Prefix"
        $CmdletsToExport = "ExportCmdlet", "PrefixExportCmdlet", "ExportPrefixCmdlet", "ExportCmdletPrefix", "Export-Cmdlet", "Export-PrefixCmdlet", 
                           "Export-CmdletPrefix", "Export-CmdletPrefixCmdlet", "ExportPrefix-Cmdlet", "ExportPrefix-PrefixCmdlet", "ExportPrefix-CmdletPrefix", 
                           "ExportPrefix-CmdletPrefixCmdlet", "ExportPrefix-PrefixCmdlet-PrefixCmdlet", "PrefixExport-Cmdlet", "PrefixExport-PrefixCmdlet", 
                           "PrefixExport-CmdletPrefix", "PrefixExport-CmdletPrefixCmdlet"

        $FunctionsToExport = "ExportFunction", "PrefixExportFunction", "ExportPrefixFunction", "ExportFunctionPrefix", "Export-Function", "Export-PrefixFunction", 
                             "Export-FunctionPrefix", "Export-FunctionPrefixFunction", "ExportPrefix-Function", "ExportPrefix-PrefixFunction", "ExportPrefix-FunctionPrefix", 
                             "ExportPrefix-FunctionPrefixFunction", "ExportPrefix-PrefixFunction-PrefixFunction", "PrefixExport-Function", "PrefixExport-PrefixFunction", 
                             "PrefixExport-FunctionPrefix", "PrefixExport-FunctionPrefixFunction"

        $AliasesToExport =  "ExportAlias", "PrefixExportAlias", "ExportPrefixAlias", "ExportAliasPrefix", "Export-Alias", "Export-PrefixAlias","Export-AliasPrefix", 
                            "Export-AliasPrefixAlis", "ExportPrefix-Alias", "ExportPrefix-PrefixAlias", "ExportPrefix-AliasPrefix", "ExportPrefix-AliasPrefixAlias", 
                            "ExportPrefix-PrefixAlias-PrefixAlias", "PrefixExport-Alias", "PrefixExport-PrefixAlias", "PrefixExport-AliasPrefix", "PrefixExport-AliasPrefixAlias"

        New-ModuleManifest  -Path $script:testManifestPath -Confirm:$false -DefaultCommandPrefix $DefaultCommandPrefix -CmdletsToExport $CmdletsToExport `
                            -FunctionsToExport $FunctionsToExport -AliasesToExport $AliasesToExport 
        Update-ModuleManifest -Path $script:testManifestPath
        
        Import-LocalizedData -BindingVariable ModuleManifestHashTable `
                             -FileName (Microsoft.PowerShell.Management\Split-Path $script:testManifestPath -Leaf) `
                             -BaseDirectory (Microsoft.PowerShell.Management\Split-Path $script:testManifestPath -Parent) `
                             -ErrorAction SilentlyContinue `
                             -WarningAction SilentlyContinue

        AssertEquals $ModuleManifestHashTable.DefaultCommandPrefix $DefaultCommandPrefix "DefaultCommandPrefix should be $($DefaultCommandPrefix)"
        AssertEquals $ModuleManifestHashTable.CmdletsToExport.Count $CmdletsToExport.Count "CmdletsToExport count should be $($CmdletsToExport.Count)"
        for ($i = 0; $i -lt $CmdletsToExport.Length; $i++) {
            Assert ($ModuleManifestHashTable.CmdletsToExport -contains ($CmdletsToExport[$i])) "CmdletsToExport should contain $($CmdletsToExport[$i])"
        }
        AssertEquals $ModuleManifestHashTable.FunctionsToExport.Count $FunctionsToExport.Count "FunctionsToExport count should be $($FunctionsToExport.Count)"
        for ($i = 0; $i -lt $FunctionsToExport.Length; $i++) {
            Assert ($ModuleManifestHashTable.FunctionsToExport -contains ($FunctionsToExport[$i])) "FunctionsToExport should contain $($FunctionsToExport[$i])"
        }
        AssertEquals $ModuleManifestHashTable.AliasesToExport.Count $AliasesToExport.Count "AliasesToExport count should be $($AliasesToExport.Count)"
        for ($i = 0; $i -lt $AliasesToExport.Length; $i++) {
            Assert ($ModuleManifestHashTable.AliasesToExport -contains ($AliasesToExport[$i])) "AliasesToExport should contain $($AliasesToExport[$i])"
        }
    }

    # Purpose: Update a module manifest with an empty array of commandlets and functions to export
    #
    # Action: Update-ModuleManifest -Path [path] -CmdletsToExport "" -functions ""
    #
    # Expected Result: The updated module manifest should have no commandlets or functions to export
    #
    It "UpdateModuleManifestWithEmptyFunctionsAndCmdletsToExport" {
        New-ModuleManifest  -Path $script:testManifestPath -Confirm:$false -CmdletsToExport "commandlet1","commandlet2" `
                            -FunctionsToExport "function1","function2" -AliasesToExport "alias1","alias2"
        Update-ModuleManifest -Path $script:testManifestPath -CmdletsToExport "" -FunctionsToExport "" -AliasesToExport ""
        $updatedModuleInfo = Test-ModuleManifest -Path $script:testManifestPath

        AssertEquals $updatedModuleInfo.FunctionsToExport.Count 0 "FunctionsToExport count should be 0"
        AssertEquals $updatedModuleInfo.CmdletsToExport.Count 0 "CmdletsToExport count should be 0"
        AssertEquals $updatedModuleInfo.AliasesToExport.Count 0 "AliasesToExport count should be 0"
    }

    # Purpose: Update a module manifest with same parameters
    #
    # Action: Update-ModuleManifest -Path [path] -NestedModules -Guid -Author -CompanyName -Copyright -RootModule -ModuleVersion...
    #
    # Expected Result: The updated module manifest should have the same value for all the properties in the original manifest
    #
    It "UpdateModuleManifestWithSameFields" {

        $ScriptsToProcessFilePath = "$script:UpdateModuleManifestBase\$script:UpdateModuleManifestName.ps1"
        Set-Content $ScriptsToProcessFilePath -Value "function Get-$script:UpdateModuleManifestName { Get-Date }"

        Set-Content "$script:UpdateModuleManifestBase\$script:UpdateModuleManifestName.psm1" -Value "function Get-$script:UpdateModuleManifestName { Get-Date }"
        
        $Guid =  [System.Guid]::Newguid().ToString()
        $Version = "2.0"
        $Description = "$script:UpdateModuleManifestName module"
        $ProcessorArchitecture = $env:PROCESSOR_ARCHITECTURE
        $ReleaseNotes = "$script:UpdateModuleManifestName release notes"
        $Tags = "PSGet","DSC"
        $ProjectUri = "https://$script:UpdateModuleManifestName.com/Project"
        $IconUri = "https://$script:UpdateModuleManifestName.com/Icon"
        $LicenseUri = "https://$script:UpdateModuleManifestName.com/license"
        $Author = "AuthorName"
        $CompanyName = "CompanyName"
        $CopyRight = "CopyRight"
        $RootModule = "$script:UpdateModuleManifestName.psm1"
        $PowerShellVersion = "3.0"
        $ClrVersion = "2.0"
        $DotNetFrameworkVersion = "2.0"
        $PowerShellHostVersion = "0.1"
        $TypesToProcess = "types","typesTwo"
        $FormatsToPorcess = "formats","formatsTwo"
        $RequiredAssemblies = "system.management.automation"
        $ModuleList = 'Microsoft.PowerShell.Management', 
               'Microsoft.PowerShell.Utility'
        $FunctionsToExport = "function1","function2"
        $AliasesToExport = "alias1","alias2"
        $VariablesToExport = "var1","var2"
        $CmdletsToExport="get-test1","get-test2"
        $HelpInfoURI = "https://$script:UpdateModuleManifestName.com/HelpInfoURI"
        $RequiredModules = @('Microsoft.PowerShell.Management',@{ModuleName='Microsoft.PowerShell.Utility';ModuleVersion='1.0.0.0';GUID='1da87e53-152b-403e-98dc-74d7b4d63d59'})
        $NestedModules = "Microsoft.PowerShell.Management","Microsoft.PowerShell.Utility"
        $ScriptsToProcess = "$script:UpdateModuleManifestName.ps1"
        $ParamsV3 = @{}
        $ParamsV3.Add("Guid",$Guid)
        $ParamsV3.Add("Author",$Author)
        $ParamsV3.Add("CompanyName",$CompanyName)
        $ParamsV3.Add("CopyRight",$CopyRight)
        $ParamsV3.Add("RootModule",$RootModule)
        $ParamsV3.Add("ModuleVersion",$Version)
        $ParamsV3.Add("Description",$Description)
        $ParamsV3.Add("ProcessorArchitecture",$ProcessorArchitecture)
        $ParamsV3.Add("PowerShellVersion",$PowerShellVersion)
        $ParamsV3.Add("ClrVersion",$ClrVersion)
        $ParamsV3.Add("DotNetFrameworkVersion",$DotNetFrameworkVersion)
        $ParamsV3.Add("PowerShellHostVersion",$PowerShellHostVersion)
        $ParamsV3.Add("RequiredModules",$RequiredModules)
        $ParamsV3.Add("RequiredAssemblies",$RequiredAssemblies)
        $ParamsV3.Add("NestedModules",$NestedModules)
        $ParamsV3.Add("ModuleList",$ModuleList)
        $ParamsV3.Add("FunctionsToExport",$FunctionsToExport)
        $ParamsV3.Add("AliasesToExport",$AliasesToExport)
        $ParamsV3.Add("VariablesToExport",$VariablesToExport)
        $ParamsV3.Add("CmdletsToExport",$CmdletsToExport)
        $ParamsV3.Add("HelpInfoURI",$HelpInfoURI)
        $ParamsV3.Add("Path",$script:testManifestPath)
        $ParamsV3.Add("ScriptsToProcess",$ScriptsToProcess)

        $paramsV5= $ParamsV3.Clone()
        $paramsV5.Add("Tags",$Tags)
        $ParamsV5.Add("ProjectUri",$ProjectUri)
        $ParamsV5.Add("LicenseUri",$LicenseUri)
        $ParamsV5.Add("IconUri",$IconUri)
        $ParamsV5.Add("ReleaseNotes",$ReleaseNotes)


        if($PSVersionTable.PSVersion -ge '3.0.0' -and $PSVersionTable.Version -le '4.0.0')
        {
            New-ModuleManifest  @ParamsV3 -Confirm:$false 
            Update-ModuleManifest @ParamsV3 -Confirm:$false
        }
        elseif($PSVersionTable.PSVersion -ge '5.0.0')
        {
            New-ModuleManifest  @ParamsV5 -Confirm:$false 
            Update-ModuleManifest @ParamsV5 -Confirm:$false
        }

        
        $newModuleInfo = Test-ModuleManifest -Path $script:testManifestPath

        AssertEquals $newModuleInfo.Guid $Guid "Guid should be $($Guid)"
        AssertEquals $newModuleInfo.Author $Author "Author name should be $($Author)"
        AssertEquals $newModuleInfo.CompanyName $CompanyName "Company name should be $($CompanyName)"
        AssertEquals $newModuleInfo.CopyRight $CopyRight "Copyright should be $($CopyRight)"
        AssertEquals $newModuleInfo.RootModule $RootModule "RootModule should be $($RootModule)"
        AssertEquals $newModuleInfo.Version.Major $Version "Module version should be $($Version)"
        AssertEquals $newModuleInfo.Description $Description "Description should be $($Description)"
        AssertEquals $newModuleInfo.ProcessorArchitecture $ProcessorArchitecture "Processor architecture name should be $($ProcessorArchitecture)"
        AssertEquals $newModuleInfo.ClrVersion $ClrVersion "ClrVersion should be $($ClrVersion)"
        AssertEquals $newModuleInfo.DotNetFrameworkVersion $DotNetFrameworkVersion "Dot Net Framework version should be $($DotNetFrameworkVersion)"
        AssertEquals $newModuleInfo.PowerShellHostVersion $PowerShellHostVersion "PowerShell Host Version should be $($PowerShellHostVersion)"
        AssertEquals $newModuleInfo.RequiredAssemblies $RequiredAssemblies "RequiredAssemblies should be $($RequiredAssemblies)"
        AssertEquals $newModuleInfo.PowerShellHostVersion $PowerShellHostVersion "PowerShell Host Version should be $($PowerShellHostVersion)"
        Assert ($newModuleInfo.ModuleList.Name -contains $ModuleList[0]) "Module List should include $($ModuleList[0])"
        Assert ($newModuleInfo.ExportedFunctions.Keys -contains $FunctionsToExport[0]) "ExportedFunctions should include $($FunctionsToExport[0])"
        Assert ($newModuleInfo.ExportedFunctions.Keys -contains $FunctionsToExport[1]) "ExportedFunctions should include $($FunctionsToExport[1])"
        Assert ($newModuleInfo.ExportedAliases.Keys -contains $AliasesToExport[0]) "ExportedAliases should include $($AliasesToExport[0])"
        Assert ($newModuleInfo.ExportedAliases.Keys -contains $AliasesToExport[1]) "ExportedAliases should include $($AliasesToExport[1])"
        Assert ($newModuleInfo.ExportedVariables.Keys -contains $VariablesToExport[0]) "ExportedVariables should include $($VariablesToExport[0])"
        Assert ($newModuleInfo.ExportedVariables.Keys -contains $VariablesToExport[1]) "ExportedVariables should include $($VariablesToExport[1])"
        Assert ($newModuleInfo.ExportedCmdlets.Keys -contains ($CmdletsToExport[0])) "CmdletsToExport should contain $($CmdletsToExport[0])"
        Assert ($newModuleInfo.ExportedCmdlets.Keys -contains ($CmdletsToExport[1])) "CmdletsToExport should contain $($CmdletsToExport[1])"
        if($PSVersionTable.Version -gt '5.0.0')
        {
            Assert ($newModuleInfo.Tags -contains $Tags[0]) "Tags should include $($Tags[0])"
            Assert ($newModuleInfo.Tags -contains $Tags[1]) "Tags should include $($Tags[1])"
            AssertEquals $newModuleInfo.ProjectUri $ProjectUri "ProjectUri should be $($ProjectUri)"
            AssertEquals $newModuleInfo.LicenseUri $LicenseUri "LicenseUri should be $($LicenseUri)"
            AssertEquals $newModuleInfo.IconUri $IconUri "IconUri should be $($IconUri)"
            AssertEquals $newModuleInfo.ReleaseNotes $ReleaseNotes "ReleaseNotes should be $($ReleaseNotes)"
        }
      
        Assert ($newModuleInfo.Scripts -contains $ScriptsToProcessFilePath) "ScriptsToProcess should include $($ScriptsToProcess)"
        $newModuleInfo.HelpInfoUri | Should Be $HelpInfoURI
    } `
    -Skip:$($IsWindows -eq $False)

    # Purpose: Update a module manifest with all parameters
    #
    # Action: Update-ModuleManifest -Path [path] -NestedModules -Guid -Author -CompanyName -Copyright -RootModule -ModuleVersion...
    #
    # Expected Result: should be able to update all fields with the specified values and Test-ModuleManifest should not fail
    #
    It "UpdateModuleManifestWithAllFields" {

        Set-Content "$script:UpdateModuleManifestBase\$script:UpdateModuleManifestName.psm1" -Value "function Get-$script:UpdateModuleManifestName { Get-Date }"
        $Guid =  [System.Guid]::Newguid().ToString()
        $Version = "2.0"
        $Description = "$script:UpdateModuleManifestName module"
        $ProcessorArchitecture = $env:PROCESSOR_ARCHITECTURE
        $ReleaseNotes = "$script:UpdateModuleManifestName release notes"
        $Tags = "PSGet","DSC"
        $ProjectUri = "https://$script:UpdateModuleManifestName.com/Project"
        $IconUri = "https://$script:UpdateModuleManifestName.com/Icon"
        $LicenseUri = "https://$script:UpdateModuleManifestName.com/license"
        $Author = "AuthorName"
        $CompanyName = "CompanyName"
        $CopyRight = "CopyRight"
        $RootModule = "$script:UpdateModuleManifestName.psm1"
        $PowerShellVersion = "3.0"
        $ClrVersion = "2.0"
        $DotNetFrameworkVersion = "2.0"
        $PowerShellHostVersion = "0.1"
        $TypesToProcess = "types","typesTwo"
        $FormatsToPorcess = "formats","formatsTwo"
        $RequiredAssemblies = "system.management.automation"
        $ModuleList = 'Microsoft.PowerShell.Management', 
               'Microsoft.PowerShell.Utility'
        $FunctionsToExport = "function1","function2"
        $AliasesToExport = "alias1","alias2"
        $VariablesToExport = "var1","var2"
        $CmdletsToExport="get-test1","get-test2"
        $HelpInfoURI = "https://$script:UpdateModuleManifestName.com/HelpInfoURI"
        $RequiredModules = @('Microsoft.PowerShell.Management',@{ModuleName='Microsoft.PowerShell.Utility';ModuleVersion='1.0.0.0';GUID='1da87e53-152b-403e-98dc-74d7b4d63d59'})
        $NestedModules = "Microsoft.PowerShell.Management","Microsoft.PowerShell.Utility"
        $ExternalModuleDependencies = "Microsoft.PowerShell.Management","Microsoft.PowerShell.Utility"

        $ParamsV3 = @{}
        $ParamsV3.Add("Guid",$Guid)
        $ParamsV3.Add("Author",$Author)
        $ParamsV3.Add("CompanyName",$CompanyName)
        $ParamsV3.Add("CopyRight",$CopyRight)
        $ParamsV3.Add("RootModule",$RootModule)
        $ParamsV3.Add("ModuleVersion",$Version)
        $ParamsV3.Add("Description",$Description)
        $ParamsV3.Add("ProcessorArchitecture",$ProcessorArchitecture)
        $ParamsV3.Add("PowerShellVersion",$PowerShellVersion)
        $ParamsV3.Add("ClrVersion",$ClrVersion)
        $ParamsV3.Add("DotNetFrameworkVersion",$DotNetFrameworkVersion)
        $ParamsV3.Add("PowerShellHostVersion",$PowerShellHostVersion)
        $ParamsV3.Add("RequiredModules",$RequiredModules)
        $ParamsV3.Add("RequiredAssemblies",$RequiredAssemblies)
        $ParamsV3.Add("NestedModules",$NestedModules)
        $ParamsV3.Add("ModuleList",$ModuleList)
        $ParamsV3.Add("FunctionsToExport",$FunctionsToExport)
        $ParamsV3.Add("AliasesToExport",$AliasesToExport)
        $ParamsV3.Add("VariablesToExport",$VariablesToExport)
        $ParamsV3.Add("CmdletsToExport",$CmdletsToExport)
        $ParamsV3.Add("HelpInfoURI",$HelpInfoURI)
        $ParamsV3.Add("Path",$script:testManifestPath)
        $ParamsV3.Add("ExternalModuleDependencies",$ExternalModuleDependencies)

        $paramsV5= $ParamsV3.Clone()
        $paramsV5.Add("Tags",$Tags)
        $ParamsV5.Add("ProjectUri",$ProjectUri)
        $ParamsV5.Add("LicenseUri",$LicenseUri)
        $ParamsV5.Add("IconUri",$IconUri)
        $ParamsV5.Add("ReleaseNotes",$ReleaseNotes)

        if(($PSVersionTable.PSVersion -ge '3.0.0') -or ($PSVersionTable.Version -le '4.0.0'))
        {
            New-ModuleManifest  -path $script:testManifestPath -Confirm:$false 
            Update-ModuleManifest @ParamsV3 -Confirm:$false
        }
        elseif($PSVersionTable.PSVersion -ge '5.0.0')
        {
            New-ModuleManifest  -path $script:testManifestPath -Confirm:$false 
            Update-ModuleManifest @ParamsV5 -Confirm:$false
        }
        $newModuleInfo = Test-ModuleManifest -Path $script:testManifestPath

        AssertEquals $newModuleInfo.Guid $Guid "Guid should be $($Guid)"
        AssertEquals $newModuleInfo.Author $Author "Author name should be $($Author)"
        AssertEquals $newModuleInfo.CompanyName $CompanyName "Company name should be $($CompanyName)"
        AssertEquals $newModuleInfo.CopyRight $CopyRight "Copyright should be $($CopyRight)"
        AssertEquals $newModuleInfo.RootModule $RootModule "RootModule should be $($RootModule)"
        AssertEquals $newModuleInfo.Version.Major $Version "Module version should be $($Version)"
        AssertEquals $newModuleInfo.Description $Description "Description should be $($Description)"
        AssertEquals $newModuleInfo.ProcessorArchitecture $ProcessorArchitecture "Processor architecture name should be $($ProcessorArchitecture)"
        AssertEquals $newModuleInfo.ClrVersion $ClrVersion "ClrVersion should be $($ClrVersion)"
        AssertEquals $newModuleInfo.DotNetFrameworkVersion $DotNetFrameworkVersion "Dot Net Framework version should be $($DotNetFrameworkVersion)"
        AssertEquals $newModuleInfo.PowerShellHostVersion $PowerShellHostVersion "PowerShell Host Version should be $($PowerShellHostVersion)"
        AssertEquals $newModuleInfo.RequiredAssemblies $RequiredAssemblies "RequiredAssemblies should be $($RequiredAssemblies)"
        AssertEquals $newModuleInfo.PowerShellHostVersion $PowerShellHostVersion "PowerShell Host Version should be $($PowerShellHostVersion)"
        Assert ($newModuleInfo.ModuleList.Name -contains $ModuleList[0]) "Module List should include $($ModuleList[0])"
        Assert ($newModuleInfo.ExportedFunctions.Keys -contains $FunctionsToExport[0]) "ExportedFunctions should include $($FunctionsToExport[0])"
        Assert ($newModuleInfo.ExportedFunctions.Keys -contains $FunctionsToExport[1]) "ExportedFunctions should include $($FunctionsToExport[1])"
        Assert ($newModuleInfo.ExportedAliases.Keys -contains $AliasesToExport[0]) "ExportedAliases should include $($AliasesToExport[0])"
        Assert ($newModuleInfo.ExportedAliases.Keys -contains $AliasesToExport[1]) "ExportedAliases should include $($AliasesToExport[1])"
        Assert ($newModuleInfo.ExportedVariables.Keys -contains $VariablesToExport[0]) "ExportedVariables should include $($VariablesToExport[0])"
        Assert ($newModuleInfo.ExportedVariables.Keys -contains $VariablesToExport[1]) "ExportedVariables should include $($VariablesToExport[1])"
        Assert ($newModuleInfo.ExportedCmdlets.Keys -contains ($CmdletsToExport[0])) "CmdletsToExport should contain $($CmdletsToExport[0])"
        Assert ($newModuleInfo.ExportedCmdlets.Keys -contains ($CmdletsToExport[1])) "CmdletsToExport should contain $($CmdletsToExport[1])"
        if($PSVersionTable.Version -gt '5.0.0')
        {
            Assert ($newModuleInfo.Tags -contains $Tags[0]) "Tags should include $($Tags[0])"
            Assert ($newModuleInfo.Tags -contains $Tags[1]) "Tags should include $($Tags[1])"
            AssertEquals $newModuleInfo.ProjectUri $ProjectUri "ProjectUri should be $($ProjectUri)"
            AssertEquals $newModuleInfo.LicenseUri $LicenseUri "LicenseUri should be $($LicenseUri)"
            AssertEquals $newModuleInfo.IconUri $IconUri "IconUri should be $($IconUri)"
            AssertEquals $newModuleInfo.ReleaseNotes $ReleaseNotes "ReleaseNotes should be $($ReleaseNotes)"
        }
       
        $newModuleInfo.HelpInfoUri | Should Be $HelpInfoURI
        Assert ($newModuleInfo.PrivateData.PSData.ExternalModuleDependencies -contains $ExternalModuleDependencies[0]) "ExternalModuleDependencies should include $($ExternalModuleDependencies[0])"
        Assert ($newModuleInfo.PrivateData.PSData.ExternalModuleDependencies -contains $ExternalModuleDependencies[1]) "ExternalModuleDependencies should include $($ExternalModuleDependencies[1])"
    } `
    -Skip:$($IsWindows -eq $False) 
    
    # Purpose: Validate Update-ModuleManifest cmdlet with PrivateData
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] -PrivateData [Hashtable]
    #
    # Expected Result: The new manifest file should fill in the PrivataData section with the specified values of different properties
    # and Test-Modulemanifest on the newly generated manifest file should not fail 
    #
    It UpdateModuleManifestWithPrivataData {
        
        Set-Content "$script:UpdateModuleManifestBase\$script:UpdateModuleManifestName.psm1" -Value "function Get-$script:UpdateModuleManifestName { Get-Date }"

        $PrivateData = @{}
        $Tags = "Tags1","Tags2"
        $ProjectUri = "https://$script:UpdateModuleManifestName.com/Project"
        $IconUri = "https://$script:UpdateModuleManifestName.com/Icon"
        $LicenseUri = "https://$script:UpdateModuleManifestName.com/license"
        $ReleaseNotes = "ReleaseNotes"
        $PackageManagementProviders = "$script:UpdateModuleManifestName.psm1"
        $ExtraProperties = "Extra"
        $PrivateData.Add("ExtraProperties",$ExtraProperties)

        New-ModuleManifest -path $script:testManifestPath
        Update-ModuleManifest -Path $script:testManifestPath -PrivateData $PrivateData -Tags $Tags `
        -ProjectUri $ProjectUri -IconUri $IconUri -LicenseUri $LicenseUri -ReleaseNotes $ReleaseNotes `
        -PackageManagementProviders $PackageManagementProviders -Confirm:$false
        
        $newModuleInfo = Test-ModuleManifest -Path $script:testManifestPath

        if($PSVersionTable.PSVersion -ge '5.0.0')
        {
            Assert ($newModuleInfo.Tags -contains $Tags[0]) "Tags should include $($Tags[0])"
            Assert ($newModuleInfo.Tags -contains $Tags[1]) "Tags should include $($Tags[1])"
            AssertEquals $newModuleInfo.ProjectUri $ProjectUri "ProjectUri should be $($ProjectUri)"
            AssertEquals $newModuleInfo.LicenseUri $LicenseUri "LicenseUri should be $($LicenseUri)"
            AssertEquals $newModuleInfo.IconUri $IconUri "IconUri should be $($IconUri)"
            AssertEquals $newModuleInfo.ReleaseNotes $ReleaseNotes "ReleaseNotes should be $($ReleaseNotes)"

        }
        AssertEquals $newModuleInfo.PrivateData.PackageManagementProviders $PackageManagementProviders "PackageManagementProviders should be $($PackageManagementProviders)"
        AssertEquals $newModuleInfo.PrivateData.ExtraProperties $ExtraProperties "ExtraProperties should include $($ExtraProperties)"
    } 



    # Purpose: Validate Update-ModuleManifest cmdlet with ExternalModuleDependencies and PackageManagementProviders properties
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] -ExternalModuleDependencies [modules] -PackageManagementProviders [providers]
    #
    # Expected Result: The new manifest file should add two properties 'ExternalModuleDependencies' and 'PackageManagementProviders'
    # under PrivateData section
    #
    It UpdateModuleManifestWithExternalModuleDependenciesAndPackageManagementProviders {

        Set-Content "$script:UpdateModuleManifestBase\$script:UpdateModuleManifestName.psm1" -Value "function Get-$script:UpdateModuleManifestName { Get-Date }"
        Set-Content "$script:UpdateModuleManifestBase/Dependency.psm1" -Value "function Get-$script:UpdateModuleManifestName { Get-Date }"

        $NestedModules = "$script:UpdateModuleManifestBase/Dependency.psm1"
        $ExternalModuleDependencies = "$script:UpdateModuleManifestBase/Dependency.psm1"
        $PackageManagementProviders = "ContosoPublishModule.psm1"

        New-ModuleManifest -path $script:testManifestPath -NestedModules $NestedModules
        Update-ModuleManifest -Path $script:testManifestPath -ExternalModuleDependencies $ExternalModuleDependencies -PackageManagementProviders $PackageManagementProviders -Confirm:$false
        $newModuleInfo = Test-ModuleManifest -Path $script:testManifestPath

        AssertEquals $newModuleInfo.PrivateData.PackageManagementProviders $PackageManagementProviders "PackageManagementProviders should be $($PackageManagementProviders)"
        AssertEquals $newModuleInfo.PrivateData.PSData.ExternalModuleDependencies $ExternalModuleDependencies "ExternalModuleDependencies should include $($ExternalModuleDependencies)"
    } 



    # Purpose: Validate Update-ModuleManifest cmdlet throw warnings when ExportedDSCResources is specified for PowerShell version lower than 5.0
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] -PowerShellVersion 3.0 -DscResourcesToExport "DscResources"
    #
    # Expected Result: Update-ModuleManifest should throw warnings about DscResourcesToExport not supported
    #
     It UpdateModuleManifesWithExportedDSCResourcesInLowerPowerShellVersion {
        #When running on lower versin of PowerShell
        if($PSVersionTable.PSVersion -lt '5.0.0')
        {
            $DscResourcesToExport = "ExportedDscResource1"

            New-ModuleManifest -path $script:testManifestPath

            AssertFullyQualifiedErrorIdEquals -scriptblock {Update-ModuleManifest -Path $script:testManifestPath `
                                              -DscResourcesToExport $DscResourcesToExport } `
                                              -expectedFullyQualifiedErrorId "ExportedDscResourcesNotSupported,Update-ModuleManifest"
        }

        #Case where PSVersion is greater than 5.0 but module version is less than 5.0
        else
        {
            $PowerShellVersion = "3.0"
            $DscResourcesToExport = "ExportedDscResource1"

            New-ModuleManifest -path $script:testManifestPath

            AssertFullyQualifiedErrorIdEquals -scriptblock {Update-ModuleManifest -Path $script:testManifestPath -PowerShellVersion $PowerShellVersion `
                                              -DscResourcesToExport $DscResourcesToExport } `
                                              -expectedFullyQualifiedErrorId "ExportedDscResourcesNotSupported,Update-ModuleManifest"
        }
    } 


    # Purpose: Validate Update-ModuleManifest cmdlet in PowerShell version greater than 5.0
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] -DscResourcesToExport "DscResources"
    #
    # Expected Result: Update-ModuleManifest should update the field "DscResourcesToExport" in module manifest file.
    #
    It UpdateModuleManifestWithValidExportedDSCResources {
        $DscResourcesToExport = "ExportedDscResource1", "ExportedDscResources2"
        New-ModuleManifest -path $script:testManifestPath -PowerShellVersion 5.0
        Update-ModuleManifest -Path $script:testManifestPath -DscResourcesToExport $DscResourcesToExport -Confirm:$false

        $newModuleInfo = Test-ModuleManifest -Path $script:testManifestPath

        Assert ($newModuleInfo.ExportedDscResources -contains $DscResourcesToExport[0]) "DscResourcesToExport should include $($DscResourcesToExport[0])"
        Assert ($newModuleInfo.ExportedDscResources -contains $DscResourcesToExport[1]) "DscResourcesToExport should include $($DscResourcesToExport[1])"
        
    } `
    -Skip:$(($PSVersionTable.PSVersion -lt '5.0.0') -or ($PSVersionTable.PSVersion -ge '6.0.9'))

    
    # Purpose: Validate Update-ModuleManifest cmdlet throw warnings when any instance specified in 'ExternalModuleDependency'
    # is not either part of 'NestedModules' or 'RequiredModules'
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] -NestedModules $NestedModules -ExternalModuleDependencies $ExternalModuleDependences
    #
    # Expected Result: Update-ModuleManifest should throw InvalidExternalModuleDependencies errorid.
    #
    It UpdateModuleManifestWithInvalidExternalModuleDependencies {
        $NestedModules = "NestedModules"
        $ExternalModuleDependences = "ExtraModules"

        New-ModuleManifest -path $script:testManifestPath

        AssertFullyQualifiedErrorIdEquals -scriptblock {Update-ModuleManifest -Path $script:testManifestPath -NestedModules $NestedModules `
                                          -ExternalModuleDependencies $ExternalModuleDependences -Confirm:$false } `
                                          -expectedFullyQualifiedErrorId "InvalidExternalModuleDependencies,Update-ModuleManifest"
    } 


    # Purpose: Validate Update-ModuleManifest will throw errors when invalid module manifest path is provided
    #
    # Action:
    #      Update-ModuleManifest -Path [InvalidPath] 
    #
    # Expected Result: Update-ModuleManifest should throw errors about the invalid path
    #
    It UpdateModuleManifestWithInvalidModuleManifestPath {
        $Path = "//InvalidPath"

        AssertFullyQualifiedErrorIdEquals -scriptblock {Update-ModuleManifest -Path $Path} `
                                          -expectedFullyQualifiedErrorId "InvalidModuleManifestFilePath,Update-ModuleManifest"
    } 
    

    # Purpose: Validate Update-ModuleManifest will throw errors when there are paths defined in FilePath that are not in the module base
    #
    # Action:
    #      Update-ModuleManifest -FilePath [InvalidFilePath]
    #
    # Expected Result: Update-ModuleManifest should throw errors about the invalid file path
    #
    It UpdateModuleManifestWithInvalidFileList {
        $FilePath = "abcdefg.ps1"
        New-ModuleManifest -path $script:testManifestPath -FileList $FilePath

        # When running on lower versin of PowerShell
        if($PSVersionTable.PSVersion -lt '5.1.0')
        {
            AssertFullyQualifiedErrorIdEquals -scriptblock {Update-ModuleManifest -Path $script:testManifestPath} `
                                          -expectedFullyQualifiedErrorId "FilePathInFileListNotWithinModuleBase,Update-ModuleManifest"
        }
        else
        {
            AssertFullyQualifiedErrorIdEquals -scriptblock {Update-ModuleManifest -Path $script:testManifestPath} `
                                          -expectedFullyQualifiedErrorId "InvalidModuleManifestFile,Update-ModuleManifest"
        }
        
    } 

    # Purpose: Validate Update-ModuleManifest will throw errors when there are paths defined in FilePath that are not in the module base
    #
    # Action:
    #      Update-ModuleManifest -FilePath [InvalidFilePath]
    #
    # Expected Result: Update-ModuleManifest should throw errors about the invalid file path
    #
    It UpdateModuleManifestWithInvalidFileList2 {
        New-ModuleManifest -path $script:testManifestPath
        $FilePath = Join-Path $script:psgetModuleInfo.ModuleBase "abcdefg.ps1"
        AssertFullyQualifiedErrorIdEquals -scriptblock {Update-ModuleManifest -Path $script:testManifestPath -FileList $FilePath} `
                                          -expectedFullyQualifiedErrorId "FilePathInFileListNotWithinModuleBase,Update-ModuleManifest"
    } 


    # Purpose: Validate Update-ModuleManifest will throw errors if some invalid properties were provided and 
    # New-ModuleManifest failed
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] -NestedModules [InvalidModuleInfo] 
    #
    # Expected Result: Update-ModuleManifest should throw errors about New-ModuleManifest fail 
    #
    It UpdateModuleManifestWithInvalidModuleProperties {

        $NestedModules = @("Nested",@{"ModuleVersion"="1.0"})

        New-ModuleManifest -path $script:testManifestPath
        AssertFullyQualifiedErrorIdEquals -scriptblock {Update-ModuleManifest -Path $script:testManifestPath -NestedModules $NestedModules} `
                                          -expectedFullyQualifiedErrorId "NewModuleManifestFailure,Update-ModuleManifest"
    } 
    
    # Purpose: Validate Update-ModuleManifest will throw errors when any of the PackageManagementProviders specified
    # is not in the modulebase folder
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] -PackageManagementProviders [InvalidPackageManagementProviders]
    #
    # Expected Result: Update-ModuleManifest should throw errors about New-ModuleManifest fail 
    #
    It UpdateModuleManifestWithInvalidPackageManagementProviders {

        $PackageManagementProviders = "InvalidProviders"

        New-ModuleManifest -path $script:testManifestPath
        AssertFullyQualifiedErrorIdEquals -scriptblock {Update-ModuleManifest -Path $script:testManifestPath -PackageManagementProviders $PackageManagementProviders} `
                                          -expectedFullyQualifiedErrorId "InvalidPackageManagementProviders,Update-ModuleManifest"
    } 

    # Purpose: Validate Update-ModuleManifest will throw errors when an invalid RootModule is provided
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] -RootModule [InvalidRootModule]
    #
    # Expected Result: Update-ModuleManifest should throw errors about the invalid RootModule
    #
    It UpdateModuleManifestWithInvalidRootModule {

        New-ModuleManifest -path $script:testManifestPath

        $InvalidRootModule = "\/"
        AssertFullyQualifiedErrorIdEquals -scriptblock {Update-ModuleManifest -Path $script:testManifestPath -RootModule $InvalidRootModule} `
                                          -expectedFullyQualifiedErrorId "UpdateManifestFileFail,Update-ModuleManifest"

        $newModuleInfo = Test-ModuleManifest -Path $script:testManifestPath
        Assert ($newModuleInfo.RootModule -contains $InvalidRootModule -eq $False) 'Module Manifest should not contain an invalid root module'
    }`
    -Skip:$($PSVersionTable.PSVersion -lt '5.1.0')

    # Purpose: Validate Update-ModuleManifest will throw errors if the original manifest fail the Test-ModuleManifest
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] 
    #
    # Expected Result: Update-ModuleManifest should throw errors if Test-ModuleManifest fail
    #
    It UpdateModuleManifestWithInvalidManifest {

        New-ModuleManifest -path $script:testManifestPath -TypesToProcess "types1"
        AssertFullyQualifiedErrorIdEquals -scriptblock {Update-ModuleManifest -Path $script:testManifestPath} `
                                          -expectedFullyQualifiedErrorId "InvalidModuleManifestFile,Update-ModuleManifest"
    } 

   
    # Purpose: Validate Update-ModuleManifest will not change the contents of the manifest when -WhatIf is specified
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] -WhatIf
    #
    # Expected Result: Manifest contents should not be updated
    #
    It UpdateModuleManifestWithWhatIf {
        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1
        $content = $null
        $moduleContent = $null

        $author = "TestUser"
        New-ModuleManifest -path $script:testManifestPath -Author $author
        $newAuthor = "NewAuthor"

        try
        {
            $result = ExecuteCommand $runspace "Update-ModuleManifest -path $script:testManifestPath -Author $newAuthor -WhatIf"

        }
        finally
        {
            $fileName = "WriteLine-0.txt"
            $path = join-path $outputFilePath $fileName
            if(Test-Path $path)
            {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $moduleInfo = Test-ModuleManifest -Path $script:testManifestPath
        #We are not comparing the exact content of whatif message and the manifest file since some comments are changed during Test-ModuleManifest in Update-ModuleManifest
        Assert ($content -and $content.Contains("Update manifest file with new content")) "Update-ModouleManifest whatif message missing, $content"
        Assert $content.Contains("Author = 'NewAuthor'") "Update-ModuleManifest whatif message missing changing value, $content"
        AssertEquals $moduleInfo.Author $Author "Author name should be $($Author)"
    } `
    -Skip:$(($PSCulture -ne 'en-US') -or ($PSEdition -eq 'Core'))


    # Purpose: Validate Update-ModuleManifest will update the content if -Confirm:$false is used
    #
    # Action: Update-ModuleManifest -Path [Path] -Author "NewAuthor" -Confirm:$false
    #
    # Expected Result: Manifest file should be updated
    #
    It "UpdateModuleManifestWithFalseConfirm" {

        $Author = "NewAuthor"
        New-ModuleManifest -Path $script:testManifestPath
        Update-ModuleManifest -Path $script:testManifestPath -Author $Author -Confirm:$false
        
        $newModuleInfo = Test-ModuleManifest -Path $script:testManifestPath
        AssertEquals $newModuleInfo.Author $Author "Author name should be $($Author)"
    }
    
    
    # Purpose: Validate that Update-ModuleManifest will update the content when confirmed "yes" by user
    #
    # Action: Update-ModuleManifest -Path [path] -Author "NewAuthor" -Confirm
    #
    # Expected Result: Manifest file should be updated
    #
    It "UpdateModuleManifestWithConfirmAndYesToPrompt" -Test {
        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        $author = "TestUser"
        New-ModuleManifest -path $script:testManifestPath -Author $author
        $newAuthor = "NewAuthor"

        # 0 is mapped to YES in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake=0
        $content = $null

        try
        {
            $result = ExecuteCommand $runspace "Update-ModuleManifest -Path $script:testManifestPath -Author $newAuthor -Confirm"
        }
        finally
        {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if(Test-Path $path)
            {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $newModuleInfo = Test-ModuleManifest -Path $script:testManifestPath
        AssertEquals $newModuleInfo.Author $newAuthor "Author name should be $($newAuthor)"
    } `
    -Skip:$($PSEdition -eq 'Core')
    
    # Purpose: Validate Update-ModuleManifest will throw errors if current user does not have read-write permission 
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] 
    #
    # Expected Result: Update-ModuleManifest should throw errors about user does not have permission on the file
    #
    It UpdateModuleManifestWithReadOnlyManifest {

        New-ModuleManifest -path $script:testManifestPath 
        $ManifestFile = Get-Item $script:testManifestPath 
        $ManifestFile.Attributes = "ReadOnly"

        AssertFullyQualifiedErrorIdEquals -scriptblock {Update-ModuleManifest -Path $script:testManifestPath} `
                                          -expectedFullyQualifiedErrorId "ManifestFileReadWritePermissionDenied,Update-ModuleManifest"
    } 

    # Purpose: Validate Update-ModuleManifest will throw errors if the manifest file is being used
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] 
    #
    # Expected Result: Update-ModuleManifest should throw errors about not able to update the manifest
    #
    It UpdateModuleManifestWithFileBeingUsed {

        New-ModuleManifest -path $script:testManifestPath 
        $file = [System.IO.File]::Open($script:testManifestPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::None)
        AssertFullyQualifiedErrorIdEquals -scriptblock {Update-ModuleManifest -Path $script:testManifestPath} `
                                          -expectedFullyQualifiedErrorId "InvalidModuleManifestFile,Update-ModuleManifest"
    } 

    # Purpose: Validate Update-ModuleManifest have proper ReleaseNotes field when user input has single quotes
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] -ReleaseNotes [ReleaseNotes] 
    #
    # Expected Result: Update-ModuleManifest should update the manifest with correct ReleaseNotes with escape characters
    #
    It UpdateModuleManifestWithSingleQuoteInReleaseNotes {
        New-ModuleManifest -path $script:testManifestPath 
        $ReleaseNotes = "I'm a test"
        Update-ModuleManifest -Path $script:testManifestPath -ReleaseNotes $ReleaseNotes
        
        $moduleInfo = Test-ModuleManifest -Path $script:testManifestPath
        AssertEquals $moduleInfo.ReleaseNotes "I'm a test" "ReleaseNotes should be $($ReleaseNotes)"
    } `
    -Skip:$($PSVersionTable.PSVersion -lt '5.0.0') 

    # Purpose: Validate Update-ModuleManifest have proper ReleaseNotes field when there are existing releaseNotes value
    # with single quotes
    #
    # Action:
    #      Update-ModuleManifest -Path [Path]

    # Expected Result: Update-ModuleManifest should update the manifest with correct ReleaseNotes with escape characters
    #
    It UpdateModuleManifestWithSingleQuoteInExistingReleaseNotes {
        $ReleaseNotes = "I'm a test"
        New-ModuleManifest -path $script:testManifestPath -ReleaseNotes $ReleaseNotes
        
        Update-ModuleManifest -Path $script:testManifestPath
        
        $moduleInfo = Test-ModuleManifest -Path $script:testManifestPath
        AssertEquals $moduleInfo.ReleaseNotes "I'm a test" "ReleaseNotes should be $($ReleaseNotes)"
    } `
    -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    # Purpose: Validate Update-ModuleManifest have proper ReleaseNotes field when there are multiple lines of ReleaseNotes
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] -ReleaseNotes [ReleaseNotes]

    # Expected Result: Update-ModuleManifest should update the manifest with correct ReleaseNotes 
    #
    It UpdateModuleManifestWithMultipleLinesReleaseNotes {
        $ReleaseNotes = "I'm a test. \nThis is multiple lines.\n\r Try testing"
        New-ModuleManifest -path $script:testManifestPath -ReleaseNotes $ReleaseNotes
        
        Update-ModuleManifest -Path $script:testManifestPath
        
        $moduleInfo = Test-ModuleManifest -Path $script:testManifestPath
        AssertEquals $moduleInfo.ReleaseNotes $ReleaseNotes "ReleaseNotes should be $($ReleaseNotes)"
    } `
    -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    # Purpose: Validate Update-ModuleManifest have proper ReleaseNotes field when there are multiple lines of ReleaseNotes
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] -ReleaseNotes [ReleaseNotes]

    # Expected Result: Update-ModuleManifest should update the manifest with correct ReleaseNotes 
    #
    It UpdateModuleManifestWithMultipleLinesReleaseNotes2 {
        $ReleaseNotes = @"
        I'm a test.
        This is multiple lines.
        Try testing"
"@
        New-ModuleManifest -path $script:testManifestPath
        
        Update-ModuleManifest -Path $script:testManifestPath  -ReleaseNotes $ReleaseNotes
        
        $moduleInfo = Test-ModuleManifest -Path $script:testManifestPath
        AssertEquals $moduleInfo.ReleaseNotes $ReleaseNotes "ReleaseNotes should be $($ReleaseNotes)"
    } `
    -Skip:$(($PSVersionTable.PSVersion -lt '5.0.0') -or ($env:APPVEYOR_TEST_PASS -eq 'True'))

    # Purpose: Validate Update-ModuleManifest cmdlet throw warnings when CompatiblePSEditions is specified for PowerShell version lower than 5.1
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] -PowerShellVersion 3.0 -CompatiblePSEditions Desktop
    #
    # Expected Result: Update-ModuleManifest should throw warnings about CompatiblePSEditions not supported
    #
     It UpdateModuleManifesWithCompatiblePSEditionsInLowerPowerShellVersion {
        $CompatiblePSEditions = @('Desktop', 'Core')
        New-ModuleManifest -path $script:testManifestPath

        # When running on lower versin of PowerShell
        if($PSVersionTable.PSVersion -lt '5.1.0')
        {
            AssertFullyQualifiedErrorIdEquals -scriptblock {
                                                                Update-ModuleManifest -Path $script:testManifestPath `
                                                                                      -CompatiblePSEditions $CompatiblePSEditions
                                                           } `
                                              -expectedFullyQualifiedErrorId "CompatiblePSEditionsNotSupported,Update-ModuleManifest"
        }
        # When PSVersion is greater than 5.1 but PowerShellVersion is less than 5.1
        else
        {
            $PowerShellVersion = "5.0"
            AssertFullyQualifiedErrorIdEquals -scriptblock {
                                                                Update-ModuleManifest -Path $script:testManifestPath `
                                                                                      -PowerShellVersion $PowerShellVersion `
                                                                                      -CompatiblePSEditions $CompatiblePSEditions 
                                                           } `
                                              -expectedFullyQualifiedErrorId "CompatiblePSEditionsNotSupported,Update-ModuleManifest"
        }
    }

    # Purpose: Validate Update-ModuleManifest cmdlet with CompatiblePSEditions on PowerShell version greater than 5.1
    #
    # Action:
    #      Update-ModuleManifest -Path [Path] -CompatiblePSEditions 'Desktop','Core' -PowerShellVersion 5.1
    #
    # Expected Result: Update-ModuleManifest should update the field "CompatiblePSEditions" in module manifest file.
    #
    It UpdateModuleManifestWithValidCompatiblePSEditions {
        New-ModuleManifest -path $script:testManifestPath -PowerShellVersion 5.1 -CompatiblePSEditions 'Desktop'
        $moduleInfo = Test-ModuleManifest -Path $script:testManifestPath
        AssertEquals $moduleInfo.CompatiblePSEditions.Count 1 'CompatiblePSEditions should be Desktop'
        Assert ($moduleInfo.CompatiblePSEditions -contains 'Desktop') 'CompatiblePSEditions should be Desktop'

        $CompatiblePSEditions = 'Desktop','Core'
        Update-ModuleManifest -Path $script:testManifestPath -CompatiblePSEditions $CompatiblePSEditions
        $newModuleInfo = Test-ModuleManifest -Path $script:testManifestPath

        Assert ($newModuleInfo.CompatiblePSEditions -contains $CompatiblePSEditions[0]) "CompatiblePSEditions should include $($CompatiblePSEditions[0])"
        Assert ($newModuleInfo.CompatiblePSEditions -contains $CompatiblePSEditions[1]) "CompatiblePSEditions should include $($CompatiblePSEditions[1])"
    } `
    -Skip:$($PSVersionTable.PSVersion -lt '5.1.0')
}
