<#####################################################################################
 # File: PSGetUnInstallModuleTests.ps1
 # Tests for PSGet module functionality
 #
 # Copyright (c) Microsoft Corporation, 2014
 #####################################################################################>

<#
   Name: PowerShell.PSGet.UnInstallModuleTests
   Description: Tests for UnInstall-Module cmdlet functionality

   Local PSGet Test Gallery (http://localhost:8765/packages) is pre-populated with static modules:
        ContosoClient: versions 1.0, 1.5, 2.0, 2.5
        ContosoServer: versions 1.0, 1.5, 2.0, 2.5
#>

function SuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

    $script:ProgramFilesModulesPath = Get-AllUsersModulesPath
    $script:MyDocumentsModulesPath = Get-CurrentUserModulesPath
    $script:PSGetLocalAppDataPath = Get-PSGetLocalAppDataPath
    $script:TempPath = Get-TempPath

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

    PSGetTestUtils\Uninstall-Module ContosoServer
    PSGetTestUtils\Uninstall-Module ContosoClient

    $script:assertTimeOutms = 20000
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

Describe 'PowerShell.PSGet.UnInstallModuleTests' -Tags 'BVT','InnerLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    AfterEach {
        PSGetTestUtils\Uninstall-Module ContosoServer
        PSGetTestUtils\Uninstall-Module ContosoClient
        PSGetTestUtils\Uninstall-Module DscTestModule
    }

    # Purpose: UnInstallModuleWithWhatIf
    #
    # Action: Find-Module ContosoServer | Install-Module | UnInstall-Module -WhatIf
    #
    # Expected Result: it should not uninstall the module
    #
    It "UnInstallModuleWithWhatIf" {
        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1
        $content = $null

        try
        {  
	        Find-Module ContosoServer | Install-Module          
            $result = ExecuteCommand $runspace 'PowerShellGet\Uninstall-Module ContosoServer -whatif'
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

        $itemInfo = Find-Module ContosoServer -Repository PSGallery
        $uninstallShouldProcessMessage = $script:LocalizedData.InstallModulewhatIfMessage -f ($itemInfo.Name, $itemInfo.Version)
        Assert ($content -and ($content -match $uninstallShouldProcessMessage)) "Install module whatif message is missing, Expected:$uninstallShouldProcessMessage, Actual:$content"

        $mod = Get-InstalledModule ContosoServer
        Assert ($mod) "UnInstall-Module should not uninstall the module with -WhatIf option"
    } `
    -Skip:$(($PSEdition -eq 'Core') -or ($PSCulture -ne 'en-US') -or ([System.Environment]::OSVersion.Version -lt '6.2.9200.0'))

    # Purpose: UnInstallModuleWithConfirmAndNoToPrompt
    #
    # Action: UnInstall-Module ContosoServer -Confirm
    #
    # Expected Result: module should not be uninstalled after confirming NO
    #
    It 'UnInstallModuleWithConfirmAndNoToPrompt' {
        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 2 is mapped to NO in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake=2
        $content = $null

        try
        {
	        Install-Module ContosoServer -Repository PSGallery -force
            $result = ExecuteCommand $runspace 'PowerShellGet\Uninstall-Module ContosoServer -Confirm'
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
        
        $itemInfo = Find-Module ContosoServer -Repository PSGallery

        $unInstallShouldProcessMessage = $script:LocalizedData.InstallModulewhatIfMessage -f ($itemInfo.Name, $itemInfo.Version)
        Assert ($content -and ($content -match $unInstallShouldProcessMessage)) "UnInstall module confirm prompt is not working, Expected:$unInstallShouldProcessMessage, Actual:$content"

        $mod = Get-InstalledModule ContosoServer
        Assert ($mod) "UnInstall-Module should not uninstall the module if confirm is not accepted"
    } `
    -Skip:$(($PSEdition -eq 'Core') -or ($PSCulture -ne 'en-US') -or ([System.Environment]::OSVersion.Version -lt '6.2.9200.0'))

    # Purpose: UnInstallModuleWithConfirmAndYesToPrompt
    #
    # Action: Find-Module ContosoServer | Install-Module | UnInstallModule-Confirm
    #
    # Expected Result: module should be uninstalled after confirming YES
    #
    It "UnInstallModuleWithConfirmAndYesToPrompt" {
        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 0 is mapped to YES in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake=0
        $content = $null

        try
        {
            Find-Module ContosoServer | Install-Module
            $result = ExecuteCommand $runspace 'PowerShellGet\Uninstall-Module ContosoServer -Confirm'
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

        $itemInfo = Find-Module ContosoServer -Repository PSGallery

        $UninstallShouldProcessMessage = $script:LocalizedData.InstallModulewhatIfMessage -f ($itemInfo.Name, $itemInfo.Version)
        Assert ($content -and ($content -match $UninstallShouldProcessMessage)) "UnInstall module confirm prompt is not working, Expected:$UninstallShouldProcessMessage, Actual:$content"

        $res = Get-InstalledModule ContosoServer -ErrorAction SilentlyContinue
        AssertNull $res "UnInstall-Module should uninstall a module if Confirm is not accepted"
    } `
    -Skip:$(($PSEdition -eq 'Core') -or ($PSCulture -ne 'en-US') -or ([System.Environment]::OSVersion.Version -lt '6.2.9200.0'))

    <#
    Purpose: Validate the -AllVersions parameter on Get-InstalledModule and Uninstall-Module cmdlets

    Action: Install a module, update the module, get module count

    Expected Result: should be able to get the installed module.
    #>
    It ValidateGetInstalledAndUninstallModuleCmdletsWithAllVersions {

        $ModuleName = 'ContosoServer'

        Install-Module -Name $ModuleName -RequiredVersion 1.0 -Force
        $mod = Get-InstalledModule -Name $ModuleName -AllVersions
        AssertEquals $mod.Name $ModuleName "Get-InstalledModule returned wrong module, $mod"
        AssertEquals $mod.Version "1.0" "Get-InstalledModule returned wrong module version, $mod"

        Update-Module -Name $ModuleName -RequiredVersion 2.0
        $mod2 = Get-InstalledModule -Name $ModuleName
        AssertEquals $mod2.Name $ModuleName "Get-InstalledModule returned wrong module after Update-Module, $mod2"
        AssertEquals $mod2.Version "2.0"  "Get-InstalledModule returned wrong module version  after Update-Module, $mod2"

        $modules2 = Get-InstalledModule -Name $ModuleName -AllVersions

        if($PSVersionTable.PSVersion -gt '5.0.0')
        {
            AssertEquals $modules2.count 2 "Get-InstalledModule with all version is not working fine, $modules2"
        }
        else
        {
            AssertEquals $modules2.Name $ModuleName "Get-InstalledModule with all version is not working fine, $modules2"
        }        
        
        PowerShellGet\Uninstall-Module -Name $ModuleName -AllVersions

        AssertFullyQualifiedErrorIdEquals -scriptblock {Get-InstalledModule -Name $ModuleName} `
                                          -expectedFullyQualifiedErrorId 'NoMatchFound,Microsoft.PowerShell.PackageManagement.Cmdlets.GetPackage'
    }
    
    # Purpose: ValidateModuleIsInUseErrorDuringUninstallModule
    #
    # Action: Install and import a module then try to uninstall the same version
    #
    # Expected Result: should fail with an error
    #
    It "ValidateModuleIsInUseErrorDuringUninstallModule" {
        $NonAdminConsoleOutput = Join-Path ([System.IO.Path]::GetTempPath()) 'nonadminconsole-out.txt'
        Start-Process "$PSHOME\PowerShell.exe" -ArgumentList '$null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser;
                                                              $null = Import-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force;
                                                              Install-Module -Name DscTestModule -Scope CurrentUser;
                                                              Import-Module -Name DscTestModule;
                                                              Uninstall-Module -Name DscTestModule' `
                                               -Wait `
                                               -WorkingDirectory $PSHOME `
                                               -RedirectStandardOutput $NonAdminConsoleOutput
        waitFor {Test-Path $NonAdminConsoleOutput} -timeoutInMilliseconds $script:assertTimeOutms -exceptionMessage "Uninstall-Module on non-admin console failed to complete"
        $content = Get-Content $NonAdminConsoleOutput
        
        $moduleName = 'DscTestModule'
        $module = Get-InstalledModule -Name $moduleName
        AssertEquals $module.Name $moduleName "Uninstall-module should not uninstall when a module being uninstalled is in use. $content"

        if($PSVersionTable.PSVersion -gt '5.0.0')
        {
            Assert ($content -and ($content -match 'ModuleIsInUse')) "Uninstall-module should fail when a module version being uninstalled is in use, $content."
        }

        RemoveItem $NonAdminConsoleOutput
    } `
    -Skip:$(
            $whoamiValue = (whoami)

            ($whoamiValue -eq "NT AUTHORITY\SYSTEM") -or
            ($whoamiValue -eq "NT AUTHORITY\LOCAL SERVICE") -or
            ($whoamiValue -eq "NT AUTHORITY\NETWORK SERVICE") -or
            ($PSVersionTable.PSVersion -lt '4.0.0') -or
            ($env:APPVEYOR_TEST_PASS -eq 'True') -or
            ($PSEdition -eq 'Core') -or
            ($PSCulture -ne 'en-US')
        )
}
