﻿<#####################################################################################
 # File: PSGetFindModuleTests.ps1
 # Tests for PSGet module functionality
 #
 # Copyright (c) Microsoft Corporation, 2014
 #####################################################################################>

<#
   Name: PowerShell.PSGet.FindModuleTests
   Description: Tests for Find-Module functionality

   Local PSGet Test Gallery (ex: http://localhost:8765/packages) is pre-populated with static modules:
        ContosoClient: versions 1.0, 1.5, 2.0, 2.5

        ContosoServer: versions 1.0, 1.5, 2.0, 2.5
#>
. "$PSScriptRoot\PSGetFindModuleTests.Manifests.ps1"
. "$PSScriptRoot\PSGetTests.Generators.ps1"

function SuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

    $script:MyDocumentsModulesPath = Join-Path -Path ([Environment]::GetFolderPath("MyDocuments")) -ChildPath "WindowsPowerShell\Modules"
    $script:PSGetLocalAppDataPath="$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\PowerShellGet"
    $script:DscTestModule = "DscTestModule"

    #Bootstrap NuGet binaries
    Install-NuGetBinaries

    $psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
    Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $psgetModuleInfo.ModuleBase

    $script:moduleSourcesFilePath= Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml"
    $script:moduleSourcesBackupFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml_$(get-random)_backup"
    if(Test-Path $script:moduleSourcesFilePath)
    {
        Rename-Item $script:moduleSourcesFilePath $script:moduleSourcesBackupFilePath -Force
    }

    GetAndSet-PSGetTestGalleryDetails -SetPSGallery
}

function SuiteCleanup {
    if(Test-Path $script:moduleSourcesBackupFilePath)
    {
        Move-Item $script:moduleSourcesBackupFilePath $script:moduleSourcesFilePath -Force
    }
    else
    {
        RemoveItem $script:moduleSourcesFilePath
    }

    # Import the PowerShellGet provider to reload the repositories.
    $null = Import-PackageProvider -Name PowerShellGet -Force
}

Describe PowerShell.PSGet.FindModuleTests -Tags 'BVT','InnerLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    # Purpose:
    #   Test Find-Module cmdlet without any parameters
    #
    # Action:
    #   Find-Module
    #
    # Expected Result:
    #   Should find few modules
    #
    It "FindModuleWithoutAnyParameterValues" {
        $psgetItemInfo = Find-Module
        Assert ($psgetItemInfo.Count -ge 1) "Find-Module did not return any modules."
    }

    # Purpose: FindASpecificModule
    #
    # Action: Find-Module ContosoServer
    #
    # Expected Result: Should find ContosoServer module
    #
    It "FindASpecificModule" {
        $res = Find-Module ContosoServer
        Assert ($res -and ($res.Name -eq "ContosoServer")) "Find-Module failed to find a specific module"
    }

    # Purpose: FindModuleWithRangeWildCards
    #
    # Action: Find-Module "Co[nN]t?soS[a-z]r?er"
    #
    # Expected Result: Should find ContosoServer module
    #
    It "FindModuleWithRangeWildCards" {
        $res = Find-Module -Name "Co[nN]t?soS[a-z]r?er"
        Assert ($res -and ($res.Name -eq "ContosoServer")) "Find-Module failed to get a module with wild card in module name"
    }

    # Purpose: FindNotAvaialableModuleWithWildCards
    #
    # Action: Find-Module "Co[nN]t?soS[a-z]r?eW"
    #
    # Expected Result: Should not find any module
    #
    It "FindNotAvaialableModuleWithWildCards" {
        $res = Find-Module -Name "Co[nN]t?soS[a-z]r?eW"
        Assert (-not $res) "Find-Module should not find a not available module with wild card in module name"
    }

    # Purpose: FindModuleNonExistentModule
    #
    # Action: Find-Module NonExistentModule
    #
    # Expected Result: Should fail
    #
    It "FindModuleNonExistentModule" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Module NonExistentModule} `
                                          -expectedFullyQualifiedErrorId "NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage"
    }

    # Purpose: FindModuleWithVersionParams
    #
    # Action: Find-Module ContosoServer -MinimumVersion 1.0 -RequiredVersion 5.0
    #
    # Expected Result: Should fail with error id
    #
    It "FindModuleWithVersionParams" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Module ContosoServer -MinimumVersion 1.0 -RequiredVersion 5.0} `
                                          -expectedFullyQualifiedErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether,Find-Module"
    }

    # Purpose: Find a module using MinimumVersion
    #
    # Action: Find-Module ContosoServer -MinimumVersion 1.0
    #
    # Expected Result: Should find the ContosoServer module
    #
    It "FindModuleWithMinVersion" {
        $res = Find-Module coNTososeRVer -MinimumVersion 1.0
        Assert ($res.Name -eq "ContosoServer" -and $res.Version -ge [Version]"1.0" ) "Find-Module failed to find a module using MinimumVersion"
    }

    # Purpose: Find a module with not available MinimumVersion
    #
    # Action: Find-Module ContosoServer -MinimumVersion 10.0
    #
    # Expected Result: Should not find the ContosoServer module
    #
    It "FindModuleWithMinVersionNotAvailable" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Module ContosoServer -MinimumVersion 10.0} `
                                          -expectedFullyQualifiedErrorId "NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage"
    }

    # Purpose: FindModuleWithReqVersionNotAvailable
    #
    # Action: Find-Module ContosoServer -RequiredVersion 10.0
    #
    # Expected Result: Should not find the ContosoServer module
    #
    It "FindModuleWithReqVersionNotAvailable" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Module ContosoServer -RequiredVersion 10.0} `
                                          -expectedFullyQualifiedErrorId "NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage"
    }

    # Purpose: FindModuleWithRequiredVersion
    #
    # Action: Find-Module ContosoServer -RequiredVersion 2.0
    #
    # Expected Result: Should find the ContosoServer module with version 2.0
    #
    It "FindModuleWithRequiredVersion" {
        $res = Find-Module ContosoServer -RequiredVersion 2.0
        Assert ($res -and ($res.Name -eq "ContosoServer") -and $res.Version -eq [Version]"2.0") "Find-Module failed to find a module using RequiredVersion, $res"
    }

    # Purpose: FindModuleWithMultipleModuleNamesAndReqVersion
    #
    # Action: Find-Module ContosoServer,ContosoClient -RequiredVersion 1.0
    #
    # Expected Result: Should fail with error id
    #
    It "FindModuleWithMultipleModuleNamesAndReqVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Module ContosoServer,ContosoClient -RequiredVersion 1.0} `
                                          -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Find-Module"
    }

    # Purpose: FindModuleWithMultipleModuleNamesAndMinVersion
    #
    # Action: Find-Module Find-Module ContosoServer,ContosoClient -MinimumVersion 1.0
    #
    # Expected Result: Should fail with error id
    #
    It "FindModuleWithMultipleModuleNamesAndMinVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Module ContosoServer,ContosoClient -MinimumVersion 1.0} `
                                          -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Find-Module"
    }

    # Purpose: FindModuleWithWildcardNameAndReqVersion
    #
    # Action: Find-Module Contoso*er -RequiredVersion 1.0
    #
    # Expected Result: Should fail with error id
    #
    It "FindModuleWithWildcardNameAndReqVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Module Contoso*er -RequiredVersion 1.0} `
                                          -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Find-Module"
    }

    # Purpose: FindModuleWithWildcardNameAndMinVersion
    #
    # Action: Find-Module Contoso*er -MinimumVersion 1.0
    #
    # Expected Result: Should fail with error id
    #
    It "FindModuleWithWildcardNameAndMinVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Module Contoso*er -MinimumVersion 1.0} `
                                          -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Find-Module"
    }

    # Purpose: FindModuleWithMultiNames
    #
    # Action: Find-Module ContosoClient,ContosoServer
    #
    # Expected Result: should find ContosoClient and ContosoServer modules
    #
    It "FindModuleWithMultiNames" {
        $res = Find-Module ContosoClient,ContosoServer -Repository PSGallery
        Assert ($res.Count -eq 2) "Find-Module with multiple names should not fail, $res"
    }

    # Purpose: FindModuleWithAllVersions
    #
    # Action: Find-Module ContosoClient -AllVersions
    #
    # Expected Result: should fail
    #
    It FindModuleWithAllVersions {
        $res = Find-Module ContosoClient -Repository PSGallery -AllVersions
        Assert ($res.Count -gt 1) "Find-Module with -AllVersions should return more than one version, $res"
    }

    # Purpose: Validate Find-Module -Filter KeyWord1
    #
    # Action: Find-Module -Filter KeyWord1
    #
    # Expected Result: Find-Module should work and it should have valid metadata
    #
    It FindModuleUsingFilter {
        $psgetItemInfo = Find-Module -Filter KeyWord1
        AssertEquals $psgetItemInfo.Name $script:DscTestModule "Find-Module with filter is not working, $psgetItemInfo"
    }

    # Purpose: Validate Find-Module -Includes RoleCapability
    #
    # Action: Find-Module -Includes RoleCapability
    #
    # Expected Result: Find-Module should work and it should have valid metadata
    #
    It FindModuleUsingIncludesRoleCapability {
        $psgetModuleInfo = Find-Module -Includes RoleCapability | Where-Object {$_.Name -eq "DscTestModule"}
        AssertNotNull $psgetModuleInfo.Includes "Includes is missing on PSGetModuleInfo, $($psgetModuleInfo.Includes)"
        Assert $psgetModuleInfo.Includes.RoleCapability.Count "RoleCapability are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.RoleCapability)"
        Assert $psgetModuleInfo.Includes.DscResource.Count "DscResource are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.DscResource)"
        Assert $psgetModuleInfo.Includes.Command.Count "Commands are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Command)"
        Assert $psgetModuleInfo.Includes.Function.Count "Functions are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Function)"
        Assert $psgetModuleInfo.Includes.Cmdlet.Count "Cmdlets are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Cmdlet)"
    }

    # Purpose: Validate Find-Module -Includes DscResource
    #
    # Action: Find-Module -Includes DscResource
    #
    # Expected Result: Find-Module should work and it should have valid metadata
    #
    It FindModuleUsingIncludesDscResource {
        $psgetModuleInfo = Find-Module -Includes DscResource | Where-Object {$_.Name -eq "DscTestModule"}
        AssertNotNull $psgetModuleInfo.Includes "Includes is missing on PSGetModuleInfo, $($psgetModuleInfo.Includes)"
        Assert $psgetModuleInfo.Includes.DscResource.Count "DscResource are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.DscResource)"
        Assert $psgetModuleInfo.Includes.Command.Count "Commands are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Command)"
        Assert $psgetModuleInfo.Includes.Function.Count "Functions are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Function)"
        Assert $psgetModuleInfo.Includes.Cmdlet.Count "Cmdlets are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Cmdlet)"
    }

    # Purpose: Validate Find-Module -Includes Cmdlet
    #
    # Action: Find-Module -Includes Cmdlet
    #
    # Expected Result: Find-Module should work and it should have valid metadata
    #
    It FindModuleUsingIncludesCmdlet {
        $psgetModuleInfo = Find-Module -Includes Cmdlet | Where-Object {$_.Name -eq "DscTestModule"}
        AssertNotNull $psgetModuleInfo.Includes "Includes is missing on PSGetModuleInfo, $($psgetModuleInfo.Includes)"
        Assert $psgetModuleInfo.Includes.DscResource.Count "DscResource are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.DscResource)"
        Assert $psgetModuleInfo.Includes.Command.Count "Commands are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Command)"
        Assert $psgetModuleInfo.Includes.Function.Count "Functions are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Function)"
        Assert $psgetModuleInfo.Includes.Cmdlet.Count "Cmdlets are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Cmdlet)"
    }

    # Purpose: Validate Find-Module -Includes Function
    #
    # Action: Find-Module -Includes Function
    #
    # Expected Result: Find-Module should work and it should have valid metadata
    #
    It FindModuleUsingIncludesFunction {
        $psgetModuleInfo = Find-Module -Includes Function -Tag CommandsAndResource | Where-Object {$_.Name -eq "DscTestModule"}
        AssertNotNull $psgetModuleInfo.Includes "Includes is missing on PSGetModuleInfo, $($psgetModuleInfo.Includes)"
        Assert $psgetModuleInfo.Includes.DscResource.Count "DscResource are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.DscResource)"
        Assert $psgetModuleInfo.Includes.Command.Count "Commands are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Command)"
        Assert $psgetModuleInfo.Includes.Function.Count "Functions are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Function)"
        Assert $psgetModuleInfo.Includes.Cmdlet.Count "Cmdlets are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Cmdlet)"
    }

    # Purpose: Validate Find-RoleCapability cmdlet for single RoleCapability name
    #
    # Action: Find-RoleCapability -Name Lev1Maintenance
    #
    # Expected Result: Should return one role capability
    #
    It FindRoleCapabilityWithSingleRoleCapabilityName {
        $psgetRoleCapabilityInfo = Find-RoleCapability -Name Lev1Maintenance
        AssertEquals $psgetRoleCapabilityInfo.Name 'Lev1Maintenance' "Lev1Maintenance is not returned by Find-RoleCapability, $psgetRoleCapabilityInfo"
    }

    # Purpose: Validate Find-RoleCapability cmdlet for two RoleCapability names
    #
    # Action: Find-RoleCapability -Name Lev1Maintenance,Lev2Maintenance
    #
    # Expected Result: Should return two role capabilities
    #
    It FindRoleCapabilityWithTwoRoleCapabilityNames {
        $psgetRoleCapabilityInfos = Find-RoleCapability -Name Lev1Maintenance,Lev2Maintenance

        AssertEquals $psgetRoleCapabilityInfos.Count 2 "Find-RoleCapability did not return the expected RoleCapabilities, $psgetRoleCapabilityInfos"

        Assert ($psgetRoleCapabilityInfos.Name -contains 'Lev1Maintenance') "Lev1Maintenance is not returned by Find-RoleCapability, $psgetRoleCapabilityInfos"
        Assert ($psgetRoleCapabilityInfos.Name -contains 'Lev2Maintenance') "Lev2Maintenance is not returned by Find-RoleCapability, $psgetRoleCapabilityInfos"
    }

    # Purpose: Validate Find-DscResource cmdlet for single DSC resource name
    #
    # Action: Find-DscResource -Name DscTestResource
    #
    # Expected Result: Should return one resource
    #
    It FindDscResourceWithSingleResourceName {
        $psgetDscResourceInfo = Find-DscResource -Name DscTestResource
        AssertEquals $psgetDscResourceInfo.Name "DscTestResource" "DscTestResource is not returned by Find-DscResource, $psgetDscResourceInfo"
    }

    # Purpose: Validate Find-DscResource cmdlet for two DSC resource names
    #
    # Action: Find-DscResource -Name DscTestResource,NewDscTestResource
    #
    # Expected Result: Should return two resources
    #
    It FindDscResourceWithTwoResourceNames {
        $psgetDscResourceInfos = Find-DscResource -Name DscTestResource,NewDscTestResource

        Assert ($psgetDscResourceInfos.Count -ge 2) "Find-DscResource did not return the expected DscResources, $psgetDscResourceInfos"

        Assert ($psgetDscResourceInfos.Name -contains "DscTestResource") "DscTestResource is not returned by Find-DscResource, $psgetDscResourceInfos"
        Assert ($psgetDscResourceInfos.Name -contains "NewDscTestResource") "NewDscTestResource is not returned by Find-DscResource, $psgetDscResourceInfos"
    }


    # Purpose: Validate Find-Command cmdlet for single command
    #
    # Action: Find-Command -Name CommandName
    #
    # Expected Result: Should return one command
    #
    It FindCommandWithSingleCommandName {
        $psgetCommandInfo = Find-Command -Name Get-ContosoServer
        AssertEquals $psgetCommandInfo.Name 'Get-ContosoServer' "Get-ContosoServer is not returned by Find-Command, $psgetCommandInfo"
    }

    # Purpose: Validate Find-Command cmdlet for two command names
    #
    # Action: Find-Command -Name Get-ContosoServer,Get-ContosoClient
    #
    # Expected Result: Should return two command names
    #
    It FindCommandWithTwoResourceNames {
        $psgetCommandInfos = Find-Command -Name Get-ContosoServer,Get-ContosoClient

        Assert ($psgetCommandInfos.Count -ge 2) "Find-Command did not return the expected command names, $psgetCommandInfos"

        Assert ($psgetCommandInfos.Name -contains 'Get-ContosoServer') "Get-ContosoServer is not returned by Find-Command, $psgetCommandInfos"
        Assert ($psgetCommandInfos.Name -contains 'Get-ContosoClient') "Get-ContosoClient is not returned by Find-Command, $psgetCommandInfos"
    }
}

Describe PowerShell.PSGet.FindModuleTests.P1 -Tags 'P1','OuterLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    # Purpose: FindModuleWithPrefixWildcard
    #
    # Action: Find-Module *ontosoServer
    #
    # Expected Result: Should find ContosoServer module
    #
    It "FindModuleWithPrefixWildcard" {
        $res = Find-Module *ontosoServer
        Assert ($res -and ($res.Name -eq "ContosoServer")) "Find-Module failed to get a module with wild card"
    }

    # Purpose: FindMultipleModulesWithWildcard
    #
    # Action: Find-Module Contoso*
    #
    # Expected Result: Should find atleast 3 modules
    #
    It "FindMultipleModulesWithWildcard" {
        $res = Find-Module Contoso*
        Assert ($res.Count -ge 3) "Find-Module failed to multiple modules with wild card"
    }

    # Purpose: FindModuleWithPostfixWildcard
    #
    # Action: Find-Module ContosoServe*
    #
    # Expected Result: Should find ContosoServer module
    #
    It "FindModuleWithPostfixWildcard" {
        $res = Find-Module ContosoServe*
        Assert ($res -and ($res.Name -eq "ContosoServer")) "Find-Module failed to get a module with postfix wild card search"
    }

    # Purpose: FindModuleWithWildcards
    #
    # Action: Find-Module *ontosoServe*
    #
    # Expected Result: Should find ContosoServer module
    #
    It "FindModuleWithWildcards" {
        $res = Find-Module *ontosoServe*
        Assert ($res -and ($res.Name -eq "ContosoServer")) "Find-Module failed to find module using wild cards"
    }

    # Purpose: FindModuleWithAllVersionsAndMinimumVersion
    #
    # Action: Find-Module ContosoClient -AllVersions -MinimumVersion 2.0
    #
    # Expected Result: should fail with an error id
    #
    It FindModuleWithAllVersionsAndMinimumVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Module ContosoClient -MinimumVersion 2.0 -Repository PSGallery -AllVersions} `
                                          -expectedFullyQualifiedErrorId 'AllVersionsCannotBeUsedWithOtherVersionParameters,Find-Module'
    }

    # Purpose: FindModuleWithAllVersionsAndRequiredVersion
    #
    # Action: Find-Module ContosoClient -AllVersions -RequiredVersion 2.0
    #
    # Expected Result: should fail with an error id
    #
    It FindModuleWithAllVersionsAndRequiredVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Module ContosoClient -RequiredVersion 2.0 -Repository PSGallery -AllVersions} `
                                          -expectedFullyQualifiedErrorId 'AllVersionsCannotBeUsedWithOtherVersionParameters,Find-Module'
    }

    # Purpose: Validate Find-Module -Filter KeyWordNotExists
    #
    # Action: Find-Module -Filter KeyWordNotExists
    #
    # Expected Result: Find-Module should not return any results
    #
    It FindModuleUsingFilterKeyWordNotExists {
        $psgetItemInfo = Find-Module -Filter KeyWordNotExists
        AssertNull $psgetItemInfo "Find-Module with filter is not working for KeyWordNotExists, $psgetItemInfo"
    }

    # Purpose: Validate Find-Module cmdlet with -IncludeDependencies for a module with dependencies
    #
    # Action: Find-Module -Name ModuleWithDependencies1 -IncludeDependencies
    #
    # Expected Result: Should return the module with its dependencies
    #
    It FindModuleWithIncludeDependencies {
        $ModuleName = "ModuleWithDependencies1"

        $res1 = Find-Module -Name $ModuleName -MaximumVersion "1.0" -MinimumVersion "0.1"
        AssertEquals $res1.Name $ModuleName "Find-Module didn't find the exact module which has dependencies, $res1"

        $DepencyModuleNames = $res1.Dependencies.Name

        $res2 = Find-Module -Name $ModuleName -IncludeDependencies -MaximumVersion "1.0" -MinimumVersion "0.1"
        Assert ($res2.Count -ge ($DepencyModuleNames.Count+1)) "Find-Module with -IncludeDependencies returned wrong results, $res2"

        $DepencyModuleNames | ForEach-Object { Assert ($res2.Name -Contains $_) "Find-Module with -IncludeDependencies didn't return the $_ module, $($res2.Name)"}
    }
}

Describe PowerShell.PSGet.FindModuleTests.P2 -Tags 'P2', 'OuterLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    <#
    Purpose: Verify the Find-Module functionality with different values for different parameter combinations.

    Action: Use the parameter generator to get different values to be tested with Find-Module cmdlet

    Expected Result: Module list or Error depending on the input variation
    #>
    It FindModuleParameterCombinationsTests {

        $ParameterSets = Get-FindModuleParameterSets

        $ParameterSetCount = $ParameterSets.Count + 1
        $i = 1
        foreach ($inputParameters in $ParameterSets)
        {
            Write-Verbose -Message "Combination #$i out of $ParameterSetCount"
            Write-Verbose -Message "$($inputParameters | Out-String)"
            Write-Progress -Activity "Combination $i out of $ParameterSetCount" -PercentComplete $(($i/$ParameterSetCount) * 100)
            $i = $i+1

            $params = $inputParameters.FindModuleInputParameters
            Write-Verbose -Message ($params | Out-String)

            $scriptBlock = { Find-Module @params }.GetNewClosure()

            if($inputParameters.PositiveCase)
            {
                $res = Invoke-Command -ScriptBlock $scriptBlock

                if($inputParameters.ExpectedModuleCount -gt 1)
                {
                    Assert ($res.Count -ge $inputParameters.ExpectedModuleCount) "Combination #$i : Find-Module did not return expected module count. Actual value $($res.Count) should be greater than or equal to the expected value $($inputParameters.ExpectedModuleCount)."
                }
                else
                {
                    AssertEqualsCaseInsensitive $res.Name $inputParameters.ExpectedModuleNames "Combination #$i : Find-Module did not return expected module"
                }
            }
            else
            {
                AssertFullyQualifiedErrorIdEquals -Scriptblock $scriptBlock -ExpectedFullyQualifiedErrorId $inputParameters.FullyQualifiedErrorId
            }
        }
    }
}
