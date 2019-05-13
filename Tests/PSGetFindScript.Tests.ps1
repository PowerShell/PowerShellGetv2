<#####################################################################################
 # File: PSGetFindScriptTests.ps1
 # Tests for PSGet script functionality
 #
 # Copyright (c) Microsoft Corporation, 2015
 #####################################################################################>

<#
   Name: PowerShell.PSGet.FindScriptTests
   Description: Tests for Find-Script functionality

   Local PSGet Test Gallery (ex: http://localhost:8765/packages) is pre-populated with static scripts:
        Fabrikam-ClientScript: versions 1.0, 1.5, 2.0, 2.5
        Fabrikam-ServerScript: versions 1.0, 1.5, 2.0, 2.5
#>

function SuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

    $script:PSGetLocalAppDataPath = Get-PSGetLocalAppDataPath
    $script:DscTestScript = "DscTestScript"

    #Bootstrap NuGet binaries
    Install-NuGetBinaries

    $psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
    Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $psgetModuleInfo.ModuleBase

    $script:moduleSourcesFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml"
    $script:moduleSourcesBackupFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml_$(get-random)_backup"
    if (Test-Path $script:moduleSourcesFilePath) {
        Rename-Item $script:moduleSourcesFilePath $script:moduleSourcesBackupFilePath -Force
    }

    GetAndSet-PSGetTestGalleryDetails -IsScriptSuite -SetPSGallery
}

function SuiteCleanup {
    if (Test-Path $script:moduleSourcesBackupFilePath) {
        Move-Item $script:moduleSourcesBackupFilePath $script:moduleSourcesFilePath -Force
    }
    else {
        RemoveItem $script:moduleSourcesFilePath
    }

    # Import the PowerShellGet provider to reload the repositories.
    $null = Import-PackageProvider -Name PowerShellGet -Force
}

Describe PowerShell.PSGet.FindScriptTests -Tags 'BVT', 'InnerLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    # Purpose:
    #   Test Find-Script cmdlet without any parameters
    #
    # Action:
    #   Find-Script
    #
    # Expected Result:
    #   Should find few scripts
    #
    It "FindScriptWithoutAnyParameterValues" {
        $psgetItemInfo = Find-Script
        Assert ($psgetItemInfo.Count -ge 1) "Find-Script did not return any scripts."
    }

    # Purpose: FindASpecificScript
    #
    # Action: Find-Script Fabrikam-ServerScript
    #
    # Expected Result: Should find Fabrikam-ServerScript script
    #
    It "FindASpecificScript" {
        $res = Find-Script Fabrikam-ServerScript
        Assert ($res -and ($res.Name -eq "Fabrikam-ServerScript")) "Find-Script failed to find a specific script"
    }

    # Purpose: FindScriptWithRangeWildCards
    #
    # Action: Find-Script "Co[nN]t?soS[a-z]r?er"
    #
    # Expected Result: Should find Fabrikam-ServerScript script
    #
    It "FindScriptWithRangeWildCards" {
        $res = Find-Script -Name "Fab[rR]ikam?Ser[a-z]erScr?pt"
        Assert ($res -and ($res.Name -eq "Fabrikam-ServerScript")) "Find-Script failed to get a script with wild card in script name"
    }

    # Purpose: FindNotAvaialableScriptWithWildCards
    #
    # Action: Find-Script "Fab[rR]ikam?Ser[a-z]erScr?ptW"
    #
    # Expected Result: Should not find any script
    #
    It "FindNotAvaialableScriptWithWildCards" {
        $res = Find-Script -Name "Fab[rR]ikam?Ser[a-z]erScr?ptW"
        Assert (-not $res) "Find-Script should not find a not available script with wild card in script name"
    }

    # Purpose: FindScriptNonExistentScript
    #
    # Action: Find-Script NonExistentScript
    #
    # Expected Result: Should fail
    #
    It "FindScriptNonExistentScript" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script NonExistentScript} `
            -expectedFullyQualifiedErrorId 'NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage'
    }

    # Purpose: FindModuleNotScript
    #
    # Action: Find-Script ContosoServer
    #
    # Expected Result: Should fail
    #
    It "FindModuleNotScript" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script ContosoServer} `
            -expectedFullyQualifiedErrorId 'MatchInvalidType,Find-Script'
    }

    # Purpose: FindModuleNotScriptWildcard
    #
    # Action: Find-Script ContosoServer
    #
    # Expected Result: Should not return anything
    #
    It "FindModuleNotScriptWildcard" {
        $res = Find-Script ContosoServer*
        Assert (-not $res) "Find-Script returned a module"
    }

    # Purpose: Find a script using MinimumVersion
    #
    # Action: Find-Script Fabrikam-ServerScript -MinimumVersion 1.0
    #
    # Expected Result: Should find the Fabrikam-ServerScript script
    #
    It "FindScriptWithMinVersion" {
        $res = Find-Script Fabrikam-ServerScript -MinimumVersion 1.0
        Assert ($res.Name -eq "Fabrikam-ServerScript" -and $res.Version -ge [Version]"1.0" ) "Find-Script failed to find a script using MinimumVersion"
    }

    # Purpose: FindScriptWithRequiredVersion
    #
    # Action: Find-Script Fabrikam-ServerScript -RequiredVersion 2.0
    #
    # Expected Result: Should find the Fabrikam-ServerScript script with version 2.0
    #
    It "FindScriptWithRequiredVersion" {
        $res = Find-Script Fabrikam-ServerScript -RequiredVersion 2.0
        Assert ($res -and ($res.Name -eq "Fabrikam-ServerScript") -and $res.Version -eq [Version]"2.0") "Find-Script failed to find a script using RequiredVersion, $res"
    }

    # Purpose: FindScriptWithMultiNames
    #
    # Action: Find-Script Fabrikam-ClientScript,Fabrikam-ServerScript
    #
    # Expected Result: should find Fabrikam-ClientScript and Fabrikam-ServerScript scripts
    #
    It "FindScriptWithMultiNames" {
        $res = Find-Script Fabrikam-ClientScript, Fabrikam-ServerScript -Repository PSGallery
        Assert ($res.Count -eq 2) "Find-Script with multiple names should not fail, $res"
    }

    # Purpose: FindScriptWithAllVersions
    #
    # Action: Find-Script Fabrikam-ClientScript -AllVersions
    #
    # Expected Result: should find more than one version of the Fabrikam-ClientScript script
    #
    It FindScriptWithAllVersions {
        $res = Find-Script Fabrikam-ClientScript -Repository PSGallery -AllVersions
        Assert ($res.Count -gt 1) "Find-Script with -AllVersions should return more than one version, $res"
    }

    # Purpose: Validate Find-Script -Filter KeyWord1
    #
    # Action: Find-Script -Filter KeyWord1
    #
    # Expected Result: Find-Script should work and it should have valid metadata
    #
    It FindScriptUsingFilter {
        $psgetItemInfo = Find-Script -Filter Fabrikam-ClientScript
        AssertEquals $psgetItemInfo.Name Fabrikam-ClientScript "Find-Script with filter is not working, $psgetItemInfo"
    }

    # Purpose: Validate Find-Script -Includes Workflow
    #
    # Action: Find-Script -Includes Workflow
    #
    # Expected Result: Find-Script should work and it should have valid metadata
    #
    It FindScriptUsingIncludesWorkflow {
        $psgetScriptInfo = Find-Script -Includes Workflow | Where-Object {$_.Name -eq 'Fabrikam-ClientScript'}
        AssertNotNull $psgetScriptInfo.Includes "Includes is missing on PSGetScriptInfo, $($psgetScriptInfo.Includes)"
        Assert (-not $psgetScriptInfo.Includes.DscResource.Count) "Script should not have any DscResources, $($psgetScriptInfo.Includes.DscResource)"
        Assert $psgetScriptInfo.Includes.Workflow.Count "Workflows are missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Workflow)"
        AssertEquals $psgetScriptInfo.Includes.Workflow 'Test-WorkflowFromScript_Fabrikam-ClientScript' "Test-WorkflowFromScript_Fabrikam-ClientScript Workflow is missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Workflow)"
        Assert $psgetScriptInfo.Includes.Command.Count "Commands are missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Command)"
        Assert $psgetScriptInfo.Includes.Function.Count "Functions are missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Function)"
        Assert (-not $psgetScriptInfo.Includes.Cmdlet.Count) "Script should not have any cmdlets, $($psgetScriptInfo.Includes.Cmdlet)"
    }

    # Purpose: Validate Find-Script -Includes Function
    #
    # Action: Find-Script -Includes Function
    #
    # Expected Result: Find-Script should work and it should have valid metadata
    #
    It FindScriptUsingIncludesFunction {
        $psgetScriptInfo = Find-Script -Includes Function -Tag Tag1 | Where-Object {$_.Name -eq 'Fabrikam-ServerScript'}
        AssertNotNull $psgetScriptInfo.Includes "Includes is missing on PSGetScriptInfo, $($psgetScriptInfo.Includes)"
        Assert (-not $psgetScriptInfo.Includes.DscResource.Count) "Script should not have any DscResources, $($psgetScriptInfo.Includes.DscResource)"
        Assert $psgetScriptInfo.Includes.Workflow.Count "Workflows are missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Workflow)"
        Assert $psgetScriptInfo.Includes.Command.Count "Commands are missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Command)"
        Assert $psgetScriptInfo.Includes.Function.Count "Functions are missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Function)"
        AssertEquals $psgetScriptInfo.Includes.Function 'Test-FunctionFromScript_Fabrikam-ServerScript' "Test-FunctionFromScript_Fabrikam-ServerScript function is missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Function)"
        Assert (-not $psgetScriptInfo.Includes.Cmdlet.Count) "Script should not have any cmdlets, $($psgetScriptInfo.Includes.Cmdlet)"
    }

    # Purpose: Validate Find-Script with Tag parameter
    #
    # Action: Find-Script -Tag Function
    #
    # Expected Result: Find-Script should work and it should have valid metadata
    #
    It FindScriptUsingTag {
        $tagValue = 'Tag-Fabrikam-Script-2.5'
        $psgetScriptInfo = Find-Script -Tag $tagValue
        AssertNotNull $psgetScriptInfo.Tags "Tags is missing on PSGetScriptInfo, $($psgetScriptInfo.Tags)"
        Assert ($psgetScriptInfo.Tags -contains $tagValue) "$tagValue is missing in Tags, $($psgetScriptInfo.Tags)"
    }

    # Purpose: Validate Find-Script with Command parameter
    #
    # Action: Find-Script -Command Test-FunctionFromScript_Fabrikam-Script
    #
    # Expected Result: Find-Script should work and it should have valid metadata
    #
    It FindScriptUsingCommand {
        $commandName = 'Test-FunctionFromScript_Fabrikam-Script'
        $psgetScriptInfo = Find-Script -Command $commandName
        AssertNotNull $psgetScriptInfo.Includes.Command "Command list is missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Command)"
        Assert ($psgetScriptInfo.Includes.Command -contains $commandName) "$commandName is missing in Command, $($psgetScriptInfo.Includes.Command)"
    }
}

Describe PowerShell.PSGet.FindScriptTests.P1 -Tags 'P1', 'OuterLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    # Purpose: FindScriptWithPostfixWildcard
    #
    # Action: Find-Script Fabrikam-Serve*
    #
    # Expected Result: Should find Fabrikam-ServerScript script
    #
    It "FindScriptWithPostfixWildcard" {
        $res = Find-Script Fabrikam-Serve*
        Assert ($res -and ($res.Name -eq "Fabrikam-ServerScript")) "Find-Script failed to get a script with postfix wild card search"
    }

    # Purpose: FindScriptWithPrefixWildcard
    #
    # Action: Find-Script *ontosoServer
    #
    # Expected Result: Should find Fabrikam-ServerScript script
    #
    It "FindScriptWithPrefixWildcard" {
        $res = Find-Script *ServerScript
        Assert ($res -and ($res.Name -eq "Fabrikam-ServerScript")) "Find-Script failed to get a script with wild card"
    }

    # Purpose: FindMultipleScriptsWithWildcard
    #
    # Action: Find-Script Fabrikam*
    #
    # Expected Result: Should find atleast 3 scripts
    #
    It "FindMultipleScriptsWithWildcard" {
        $res = Find-Script Fabrikam*
        Assert ($res.Count -ge 3) "Find-Script failed to multiple scripts with wild card"
    }

    # Purpose: FindScriptWithWildcards
    #
    # Action: Find-Script *ontosoServe*
    #
    # Expected Result: Should find Fabrikam-ServerScript script
    #
    It "FindScriptWithWildcards" {
        $res = Find-Script *rikam-ServerScr*
        Assert ($res -and ($res.Name -eq "Fabrikam-ServerScript")) "Find-Script failed to find script using wild cards"
    }

    # Purpose: FindScriptWithVersionParams
    #
    # Action: Find-Script Fabrikam-ServerScript -MinimumVersion 1.0 -RequiredVersion 5.0
    #
    # Expected Result: Should fail with error id
    #
    It "FindScriptWithVersionParams" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-ServerScript -MinimumVersion 1.0 -RequiredVersion 5.0} `
            -expectedFullyQualifiedErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether,Find-Script"
    }

    # Purpose: Find a script with not available MinimumVersion
    #
    # Action: Find-Script Fabrikam-ServerScript -MinimumVersion 10.0
    #
    # Expected Result: Should not find the Fabrikam-ServerScript script
    #
    It "FindScriptWithMinVersionNotAvailable" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-ServerScript -MinimumVersion 10.0} `
            -expectedFullyQualifiedErrorId "NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage"
    }

    # Purpose: FindScriptWithReqVersionNotAvailable
    #
    # Action: Find-Script Fabrikam-ServerScript -RequiredVersion 10.0
    #
    # Expected Result: Should not find the Fabrikam-ServerScript script
    #
    It "FindScriptWithReqVersionNotAvailable" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-ServerScript -RequiredVersion 10.0} `
            -expectedFullyQualifiedErrorId "NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage"
    }

    # Purpose: FindScriptWithMultipleScriptNamesAndReqVersion
    #
    # Action: Find-Script Fabrikam-ServerScript,Fabrikam-ClientScript -RequiredVersion 1.0
    #
    # Expected Result: Should fail with error id
    #
    It "FindScriptWithMultipleScriptNamesAndReqVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-ServerScript, Fabrikam-ClientScript -RequiredVersion 1.0} `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Find-Script"
    }

    # Purpose: FindScriptWithMultipleScriptNamesAndMinVersion
    #
    # Action: Find-Script Fabrikam-ServerScript,Fabrikam-ClientScript -MinimumVersion 1.0
    #
    # Expected Result: Should fail with error id
    #
    It "FindScriptWithMultipleScriptNamesAndMinVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-ServerScript, Fabrikam-ClientScript -MinimumVersion 1.0} `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Find-Script"
    }

    # Purpose: FindScriptWithWildcardNameAndReqVersion
    #
    # Action: Find-Script Fabrikam-Ser*er -RequiredVersion 1.0
    #
    # Expected Result: Should fail with error id
    #
    It "FindScriptWithWildcardNameAndReqVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-Ser*er -RequiredVersion 1.0} `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Find-Script"
    }

    # Purpose: FindScriptWithWildcardNameAndMinVersion
    #
    # Action: Find-Script Fabrikam-Ser*er -MinimumVersion 1.0
    #
    # Expected Result: Should fail with error id
    #
    It "FindScriptWithWildcardNameAndMinVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-Ser*er -MinimumVersion 1.0} `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Find-Script"
    }

    # Purpose: FindScriptWithAllVersionsAndMinimumVersion
    #
    # Action: Find-Script Fabrikam-ClientScript -AllVersions -MinimumVersion 2.0
    #
    # Expected Result: should fail with an error id
    #
    It FindScriptWithAllVersionsAndMinimumVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-ClientScript -MinimumVersion 2.0 -Repository PSGallery -AllVersions} `
            -expectedFullyQualifiedErrorId 'AllVersionsCannotBeUsedWithOtherVersionParameters,Find-Script'
    }

    # Purpose: FindScriptWithAllVersionsAndRequiredVersion
    #
    # Action: Find-Script Fabrikam-ClientScript -AllVersions -RequiredVersion 2.0
    #
    # Expected Result: should fail with an error id
    #
    It FindScriptWithAllVersionsAndRequiredVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-ClientScript -RequiredVersion 2.0 -Repository PSGallery -AllVersions} `
            -expectedFullyQualifiedErrorId 'AllVersionsCannotBeUsedWithOtherVersionParameters,Find-Script'
    }

    # Purpose: Validate Find-Script -Filter KeyWordNotExists
    #
    # Action: Find-Script -Filter KeyWordNotExists
    #
    # Expected Result: Find-Script should not return any results
    #
    It FindScriptUsingFilterKeyWordNotExists {
        $psgetItemInfo = Find-Script -Filter KeyWordNotExists
        AssertNull $psgetItemInfo "Find-Script with filter is not working for KeyWordNotExists, $psgetItemInfo"
    }

    # Purpose: Validate Find-Script cmdlet with -IncludeDependencies for a script with dependencies
    #
    # Action: Find-Script -Name ScriptWithDependencies1 -IncludeDependencies
    #
    # Expected Result: Should return the script with its dependencies
    #
    It FindScriptWithIncludeDependencies {
        $ScriptName = "Script-WithDependencies1"

        $res1 = Find-Script -Name $ScriptName -MaximumVersion "1.0" -MinimumVersion "0.1"
        AssertEquals $res1.Name $ScriptName "Find-Script didn't find the exact script which has dependencies, $res1"

        $DepencyScriptNames = $res1.Dependencies.Name

        $res2 = Find-Script -Name $ScriptName -IncludeDependencies -MaximumVersion "1.0" -MinimumVersion "0.1"
        Assert ($res2.Count -ge ($DepencyScriptNames.Count + 1)) "Find-Script with -IncludeDependencies returned wrong results, $res2"

        $DepencyScriptNames | ForEach-Object { Assert ($res2.Name -Contains $_) "Find-Script with -IncludeDependencies didn't return the $_ script, $($res2.Name)"}
    }
}
