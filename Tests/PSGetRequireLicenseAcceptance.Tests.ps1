<#####################################################################################
 # File: PSGetRequireLicenseAcceptance.ps1
 # Tests for require license acceptance PSGet module functionality
 #
 # Copyright (c) Microsoft Corporation, 2014
 #####################################################################################>

<#
   Name: PowerShell.PSGet.PSGetRequireLicenseAcceptance
   Description: Tests for Require License Acceptance functionality
#>

function SuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

    $script:ProgramFilesModulesPath = Get-AllUsersModulesPath
    $script:MyDocumentsModulesPath = Get-CurrentUserModulesPath
    $script:PSGetLocalAppDataPath = Get-PSGetLocalAppDataPath
    $script:TempPath = Get-TempPath
    $script:PSGetRequireLicenseAcceptanceFormatVersion = "2.0"

    #Bootstrap NuGet binaries
    Install-NuGetBinaries

    $script:PSGalleryRepoPath = Join-Path -Path $script:TempPath -ChildPath 'PSGalleryRepo'
    RemoveItem $script:PSGalleryRepoPath
    $null = New-Item -Path $script:PSGalleryRepoPath -ItemType Directory -Force

    $script:moduleSourcesFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml"
    $script:moduleSourcesBackupFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml_$(get-random)_backup"
    if (Test-Path $script:moduleSourcesFilePath) {
        Rename-Item $script:moduleSourcesFilePath $script:moduleSourcesBackupFilePath -Force
    }

    Set-PSGallerySourceLocation -Location $script:PSGalleryRepoPath -PublishLocation $script:PSGalleryRepoPath

    $modSource = Get-PSRepository -Name "PSGallery"
    AssertEquals $modSource.SourceLocation $script:PSGalleryRepoPath "Test repository's SourceLocation is not set properly"
    AssertEquals $modSource.PublishLocation $script:PSGalleryRepoPath "Test repository's PublishLocation is not set properly"

    $script:ApiKey = "TestPSGalleryApiKey"

    # Create temp module to be published
    $script:TempModulesPath = Join-Path -Path $script:TempPath -ChildPath "PSGet_$(Get-Random)"
    $null = New-Item -Path $script:TempModulesPath -ItemType Directory -Force

    $script:PublishModuleName = "RequireLicenseAcceptancePublishModule"
    $script:PublishModuleBase = Join-Path $script:TempModulesPath $script:PublishModuleName
    $null = New-Item -Path $script:PublishModuleBase -ItemType Directory -Force
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

    RemoveItem $script:PSGalleryRepoPath
    RemoveItem $script:TempModulesPath
}

Describe PowerShell.PSGet.PSGetRequireLicenseAcceptance.UpdateModuleManifest -Tags 'BVT', 'InnerLoop' {
    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    AfterEach {
        RemoveItem "$script:PSGalleryRepoPath\*"
        RemoveItem "$script:PublishModuleBase\*"
    }

    # Purpose: Validate Update-ModuleManifest sets RequireLicenseAcceptance flag
    #
    # Action:
    #      Update-ModuleManifest -RequireLicenseAcceptance
    # Expected Result: Update-ModuleManifest should update the manifest with RequireLicenseAcceptance value
    #
    It UpdateModuleManifestWithRequireLicenseAcceptance {
        New-ModuleManifest -Path "$script:PublishModuleBase\$script:PublishModuleName.psd1"
        Update-ModuleManifest -Path "$script:PublishModuleBase\$script:PublishModuleName.psd1" -RequireLicenseAcceptance
        $moduleInfo = Test-ModuleManifest -Path "$script:PublishModuleBase\$script:PublishModuleName.psd1"
        $moduleInfo.PrivateData.PSData.RequireLicenseAcceptance | should be $true
    }
}

Describe PowerShell.PSGet.PSGetRequireLicenseAcceptance.Publish -Tags 'BVT', 'InnerLoop' {
    # Not executing these tests on Linux and MacOS as
    # the total execution time is exceeding allowed 50 min in TravisCI daily builds.
    if ($IsMacOS -or $IsLinux) {
        return
    }

    BeforeAll {
        SuiteSetup
        $ModuleManifestFilePath = Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1"
        $LicenseFilePath = Join-Path -Path $script:PublishModuleBase -ChildPath 'license.txt'
    }

    AfterAll {
        SuiteCleanup
    }

    BeforeEach {
        Set-Content "$script:PublishModuleBase\$script:PublishModuleName.psm1" -Value "function Get-$script:PublishModuleName { Get-Date }"
    }

    AfterEach {
        RemoveItem "$script:PSGalleryRepoPath\*"
        RemoveItem "$script:ProgramFilesModulesPath\$script:PublishModuleName"
        RemoveItem "$script:PublishModuleBase\*"
    }

    # Purpose: Publish module that requires license acceptance
    #
    # Action:
    #      Update-ModuleManifest -RequireLicenseAcceptance
    #      Update-ModuleManifest -LicenseUri <LicenseUri>
    #      Add License.txt
    #      Publish-Module
    # Expected Result: Update-ModuleManifest sets the RequireLicenseAcceptance flag. Publish-Module publishes the module
    #
    It "PublishModuleRequiresLicenseAcceptance" {
        $version = "1.0"
        New-ModuleManifest -Path $ModuleManifestFilePath -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"
        Update-ModuleManifest -Path $ModuleManifestFilePath -LicenseUri "http://$script:PublishModuleName.com/license"
        Update-ModuleManifest -Path $ModuleManifestFilePath -RequireLicenseAcceptance
        Set-Content $LicenseFilePath -Value "LicenseTerms"

        Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey
        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        $psgetItemInfo.AdditionalMetadata.requireLicenseAcceptance | should be "True"
        $psgetItemInfo.PowerShellGetFormatVersion | should be $script:PSGetRequireLicenseAcceptanceFormatVersion
    }

    # Purpose: Publish module without License.txt
    #
    # Action:
    #      Update-ModuleManifest -RequireLicenseAcceptance
    #      Update-ModuleManifest -LicenseUri <LicenseUri>
    #      Publish-Module
    # Expected Result: It fails with LicenseTxtNotFound error
    #
    It "PublishModuleWithoutLicenseTxt" {
        $version = "1.0"
        New-ModuleManifest -Path $ModuleManifestFilePath -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"
        Update-ModuleManifest -Path $ModuleManifestFilePath -LicenseUri "http://$script:PublishModuleName.com/license"
        Update-ModuleManifest -Path $ModuleManifestFilePath -RequireLicenseAcceptance

        AssertFullyQualifiedErrorIdEquals -scriptblock { Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey -WarningAction SilentlyContinue }`
            -expectedFullyQualifiedErrorId 'LicenseTxtNotFound,Publish-PSArtifactUtility'

    }


    # Purpose: Publish module without LicenseURI
    #
    # Action:
    #      Update-ModuleManifest -RequireLicenseAcceptance
    #      Add License.txt
    #      Publish-Module
    # Expected Result: It fails with LicenseUriNotSpecified error
    #
    It "PublishModuleWithoutLicenseUri" {
        $version = "1.0"
        New-ModuleManifest -Path $ModuleManifestFilePath -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"
        Update-ModuleManifest -Path $ModuleManifestFilePath -RequireLicenseAcceptance
        Set-Content $LicenseFilePath -Value "LicenseTerms"
        AssertFullyQualifiedErrorIdEquals -scriptblock { Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey -WarningAction SilentlyContinue }`
            -expectedFullyQualifiedErrorId 'LicenseUriNotSpecified,Publish-PSArtifactUtility'

    }

    # Purpose: Publish module without setting requireLicenseAcceptance
    #
    # Action:
    #      Add LicenseUri
    #      Add License.txt
    #      Publish-Module
    # Expected Result: Module is published with requirelicenseAcceptance set to False.
    #
    It "PublishModuleNoRequireLicenseAcceptance" {
        $version = "1.0"
        New-ModuleManifest -Path $ModuleManifestFilePath -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"
        Update-ModuleManifest -Path $ModuleManifestFilePath -LicenseUri "http://$script:PublishModuleName.com/license"
        Set-Content $LicenseFilePath -Value "LicenseTerms"

        Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey
        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        $psgetItemInfo.AdditionalMetadata.requireLicenseAcceptance | should be "False"
    }
}

function InstallSuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

    $script:ProgramFilesModulesPath = Get-AllUsersModulesPath
    $script:MyDocumentsModulesPath = Get-CurrentUserModulesPath
    $script:PSGetLocalAppDataPath = Get-PSGetLocalAppDataPath
    $script:TempPath = Get-TempPath
    $null = New-Item -Path $script:MyDocumentsModulesPath -ItemType Directory -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    #Bootstrap NuGet binaries
    Install-NuGetBinaries

    $psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
    Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $psgetModuleInfo.ModuleBase

    $script:moduleSourcesFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml"
    $script:moduleSourcesBackupFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml_$(get-random)_backup"
    if (Test-Path $script:moduleSourcesFilePath) {
        Rename-Item $script:moduleSourcesFilePath $script:moduleSourcesBackupFilePath -Force
    }

    $Global:PSGallerySourceUri = ''
    GetAndSet-PSGetTestGalleryDetails -SetPSGallery -PSGallerySourceUri ([REF]$Global:PSGallerySourceUri) -IsScriptSuite

    PSGetTestUtils\Uninstall-Module ModuleRequireLicenseAcceptance
    Get-InstalledScript -Name ScriptRequireLicenseAcceptance  -ErrorAction SilentlyContinue | Uninstall-Script -Force
}

function InstallSuiteCleanup {
    if (Test-Path $script:moduleSourcesBackupFilePath) {
        Move-Item $script:moduleSourcesBackupFilePath $script:moduleSourcesFilePath -Force
    }
    else {
        RemoveItem $script:moduleSourcesFilePath
    }

    # Import the PowerShellGet provider to reload the repositories.
    $null = Import-PackageProvider -Name PowerShellGet -Force
}

Describe PowerShell.PSGet.PSGetRequireLicenseAcceptance.InstallSaveUpdate -Tags 'BVT', 'InnerLoop' {

    BeforeAll {
        InstallSuiteSetup
    }

    AfterAll {
        InstallSuiteCleanup
    }

    AfterEach {
        Get-InstalledScript -Name ScriptRequireLicenseAcceptance  -ErrorAction SilentlyContinue | Uninstall-Script -Force -ErrorAction SilentlyContinue
        PSGetTestUtils\Uninstall-Module ModuleWithDependency
        PSGetTestUtils\Uninstall-Module ModuleRequireLicenseAcceptance
    }

    # Purpose: InstallModuleRequiringLicenseAcceptanceAndNoToPrompt
    #
    # Action: Install-Module ModuleRequireLicenseAcceptance
    #
    # Expected Result: module should not be installed after confirming NO
    #
    It "InstallModuleRequiringLicenseAcceptanceAndNoToPrompt" {
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 2 is mapped to NO in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake = 2
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Install-Module ModuleRequireLicenseAcceptance -Repository PSGallery'
        }
        finally {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Module ModuleRequireLicenseAcceptance -Repository PSGallery

        $installShouldProcessMessage = $script:LocalizedData.AcceptanceLicenseQuery -f ($itemInfo.Name)
        Assert ($content -and ($content -match $installShouldProcessMessage)) "Install module confirm prompt is not working, Expected:$installShouldProcessMessage, Actual:$content"

        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        AssertNull $res "Install-Module should not install a module if Confirm is not accepted"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: InstallModuleRequiringLicenseAcceptanceAndYesToPrompt
    #
    # Action: Install-Module ModuleRequireLicenseAcceptance
    #
    # Expected Result: module should be installed after confirming YES
    #
    It "InstallModuleRequiringLicenseAcceptanceAndYesToPrompt" {
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 0 is mapped to YES in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake = 0
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Install-Module ModuleRequireLicenseAcceptance'
        }
        finally {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Module ModuleRequireLicenseAcceptance -Repository PSGallery

        $installShouldProcessMessage = $script:LocalizedData.AcceptanceLicenseQuery -f ($itemInfo.Name)
        Assert ($content -and ($content -match $installShouldProcessMessage)) "Install module confirm prompt is not working, Expected:$installShouldProcessMessage, Actual:$content"

        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleRequireLicenseAcceptance")) "Install-Module should install a module if Confirm is accepted"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: InstallModuleAcceptLicense
    #
    # Action: Install-Module ModuleRequireLicenseAcceptance -AcceptLicennse
    #
    # Expected Result: module is installed successfully
    #
    It "InstallModuleAcceptLicense" {
        Install-Module ModuleRequireLicenseAcceptance -Repository PSGallery -AcceptLicense -ErrorAction Stop -Verbose 4> .\verbose.txt
        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleRequireLicenseAcceptance")) "Install-Module should install the module if -AcceptLicense is specified ($($res | Out-String; Get-content .\verbose.txt; Get-Module -ListAvailable | Out-String)) "
    }


    # Purpose: InstallModuleForce
    #
    # Action: Install-Module ModuleRequireLicenseAcceptance -Force
    #
    # Expected Result: module should fail to install with error ForceAcceptLicense
    #
    It "InstallModuleForce" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Install-Module ModuleRequireLicenseAcceptance -Repository PSGallery -Force }`
            -expectedFullyQualifiedErrorId 'ForceAcceptLicense,Install-Module'
    }


    # Purpose: InstallModuleWithDependencyAndYesToPrompt
    #
    # Action: Install-Module ModuleWithDependency
    #
    # Expected Result: User is prompted to accept license for dependant module. On yes, module is installed
    #
    It "InstallModuleWithDependencyAndYesToPrompt" {
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 0 is mapped to YES in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake = 0
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Install-Module ModuleWithDependency'
        }
        finally {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Module ModuleRequireLicenseAcceptance -Repository PSGallery
        $installShouldProcessMessage = $script:LocalizedData.AcceptanceLicenseQuery -f ($itemInfo.Name)
        Assert ($content -and ($content -match $installShouldProcessMessage)) "Install Module confirm prompt is not working, Expected:$installShouldProcessMessage, Actual:$content"

        $res = Get-Module ModuleWithDependency -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleWithDependency")) "Install-Module should install a module if Confirm is accepted"

        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleRequireLicenseAcceptance")) "Install-Module should install a module if Confirm is accepted"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: InstallModuleWithDependencyAndNoToPrompt
    #
    # Action: Install-Module ModuleWithDependency
    #
    # Expected Result: User is prompted to accept license for dependant module. On No, neither of two modules is installed
    #
    It "InstallModuleWithDependencyAndNoToPrompt" {
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 2 is mapped to NO in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake = 2
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Install-Module ModuleWithDependency -Repository PSGallery'
        }
        finally {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Module ModuleRequireLicenseAcceptance -Repository PSGallery

        $installShouldProcessMessage = $script:LocalizedData.AcceptanceLicenseQuery -f ($itemInfo.Name)
        Assert ($content -and ($content -match $installShouldProcessMessage)) "Install module confirm prompt is not working, Expected:$installShouldProcessMessage, Actual:$content"

        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        AssertNull $res "Install-Module should not install dependant module if Confirm is not accepted"

        $res = Get-Module ModuleWithDependency -ListAvailable
        AssertNull $res "Install-Module should not install a module if Confirm is not accepted"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: InstallModuleWithDependencyAcceptLicense
    #
    # Action: Install-Module ModuleWithDependency -AcceptLicennse
    #
    # Expected Result: module is installed successfully
    #
    It "InstallModuleWithDependencyAcceptLicense" {
        Install-Module ModuleWithDependency -AcceptLicense -ErrorAction Stop

        $res = Get-Module ModuleWithDependency -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleWithDependency")) "Install-Module should install the module if -AcceptLicense is specified"

        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleRequireLicenseAcceptance")) "Install-Module should install the module if -AcceptLicense is specified"
    }

    # Purpose: InstallScriptAndYesToPrompt
    #
    # Action: Install-Script ScriptRequireLicenseAcceptance
    #
    # Expected Result: Script and dependent module should be installed after confirming YES
    #
    It "InstallScriptAndYesToPrompt" {
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 0 is mapped to YES in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake = 0
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Install-Script ScriptRequireLicenseAcceptance -NoPathUpdate'
        }
        finally {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Module ModuleRequireLicenseAcceptance -Repository PSGallery
        $installShouldProcessMessage = $script:LocalizedData.AcceptanceLicenseQuery -f ($itemInfo.Name)
        Assert ($content -and ($content -match $installShouldProcessMessage)) "Install script confirm prompt is not working, Expected:$installShouldProcessMessage, Actual:$content"

        $res = Get-InstalledScript ScriptRequireLicenseAcceptance
        AssertEquals $res.Name "ScriptRequireLicenseAcceptance" "Install-Script failed to install $scriptName, $res"

        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleRequireLicenseAcceptance")) "Install-Module should install a module if Confirm is accepted"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))


    # Purpose: InstallScriptAndNoToPrompt
    #
    # Action: Install-Script ScriptRequireLicenseAcceptance
    #
    # Expected Result: Script and dependent module should NOT be installed after confirming NO
    #
    It "InstallScriptAndNoToPrompt" {
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 2 is mapped to NO in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake = 2
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Install-Script ScriptRequireLicenseAcceptance -NoPathUpdate'
        }
        finally {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Module ModuleRequireLicenseAcceptance -Repository PSGallery
        $installShouldProcessMessage = $script:LocalizedData.AcceptanceLicenseQuery -f ($itemInfo.Name)
        Assert ($content -and ($content -match $installShouldProcessMessage)) "Install script confirm prompt is not working, Expected:$installShouldProcessMessage, Actual:$content"

        $res = Get-InstalledScript ScriptRequireLicenseAcceptance -ErrorAction SilentlyContinue
        AssertNull $res "Script should not be installed"

        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        AssertNull $res "Dependant module should not be installed if Confirm is not accepted"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))


    # Purpose: InstallScriptAcceptLicense
    #
    # Action: Install-Script ScriptRequireLicenseAcceptance -AcceptLicennse
    #
    # Expected Result: script and dependant module are installed successfully
    #
    It "InstallScriptAcceptLicense" {
        Install-Script ScriptRequireLicenseAcceptance -AcceptLicense -NoPathUpdate -ErrorAction Stop

        $res = Get-InstalledScript ScriptRequireLicenseAcceptance
        AssertEquals $res.Name "ScriptRequireLicenseAcceptance" "Install-Script failed to install $scriptName, $res"

        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleRequireLicenseAcceptance")) "Install-Module should install the module if -AcceptLicense is specified"
    }

    # Purpose: SaveModuleRequiringLicenseAcceptanceAndNoToPrompt
    #
    # Action: Save-Module ModuleRequireLicenseAcceptance
    #
    # Expected Result: Module should not be saved after confirming NO
    #
    It "SaveModuleRequiringLicenseAcceptanceAndNoToPrompt" {
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 2 is mapped to NO in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake = 2
        $content = $null

        try {
            $result = ExecuteCommand $runspace "Save-Module ModuleRequireLicenseAcceptance -Path $script:MyDocumentsModulesPath -ErrorAction SilentlyContinue"
        }
        finally {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Module ModuleRequireLicenseAcceptance -Repository PSGallery

        $saveShouldProcessMessage = $script:LocalizedData.AcceptanceLicenseQuery -f ($itemInfo.Name)
        Assert ($content -and ($content -match $saveShouldProcessMessage)) "Save module confirm prompt is not working, Expected:$installShouldProcessMessage, Actual:$content"

        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        AssertNull $res "Save-Module should not install a module if Confirm is not accepted"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: SaveModuleRequiringLicenseAcceptanceAndYesToPrompt
    #
    # Action: Save-Module ModuleRequireLicenseAcceptance
    #
    # Expected Result: module should be Saved after confirming YES
    #
    It "SaveModuleRequiringLicenseAcceptanceAndYesToPrompt" {
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 0 is mapped to YES in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake = 0
        $content = $null

        try {
            $result = ExecuteCommand $runspace "Save-Module ModuleRequireLicenseAcceptance -Path $script:MyDocumentsModulesPath"
        }
        finally {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Module ModuleRequireLicenseAcceptance -Repository PSGallery

        $saveShouldProcessMessage = $script:LocalizedData.AcceptanceLicenseQuery -f ($itemInfo.Name)
        Assert ($content -and ($content -match $saveShouldProcessMessage)) "save module confirm prompt is not working, Expected:$installShouldProcessMessage, Actual:$content"

        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleRequireLicenseAcceptance")) "save-Module should save a module if Confirm is accepted"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: SaveModuleAcceptLicense
    #
    # Action: Save-Module ModuleRequireLicenseAcceptance -AcceptLicennse
    #
    # Expected Result: module is saved successfully
    #
    It "SaveModuleAcceptLicense" {
        Save-Module ModuleRequireLicenseAcceptance -Repository PSGallery -AcceptLicense -Path $script:MyDocumentsModulesPath -ErrorAction Stop
        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleRequireLicenseAcceptance")) "Install-Module should install the module if -AcceptLicense is specified"
    }

    # Purpose: SaveModuleForce
    #
    # Action: Save-Module ModuleRequireLicenseAcceptance -Force
    #
    # Expected Result: module should fail to save with error ForceAcceptLicense
    #
    It "SaveModuleForce" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Save-Module ModuleRequireLicenseAcceptance -Repository PSGallery -Force -Path $script:MyDocumentsModulesPath -WarningAction SilentlyContinue }`
            -expectedFullyQualifiedErrorId 'ForceAcceptLicense,Install-Module'
    }

    # Purpose: SaveModuleWithDependencyAndYesToPrompt
    #
    # Action: Save-Module ModuleWithDependency
    #
    # Expected Result: User is prompted to accept license for dependant module. On yes, module is Saved
    #
    It "SaveModuleWithDependencyAndYesToPrompt" {
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 0 is mapped to YES in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake = 0
        $content = $null

        try {
            $result = ExecuteCommand $runspace "Save-Module ModuleWithDependency -Path $script:MyDocumentsModulesPath"
        }
        finally {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Module ModuleRequireLicenseAcceptance -Repository PSGallery
        $SaveShouldProcessMessage = $script:LocalizedData.AcceptanceLicenseQuery -f ($itemInfo.Name)
        Assert ($content -and ($content -match $SaveShouldProcessMessage)) "Save Module confirm prompt is not working, Expected:$installShouldProcessMessage, Actual:$content"

        $res = Get-Module ModuleWithDependency -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleWithDependency")) "Save-Module should Save a module if Confirm is accepted"

        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleRequireLicenseAcceptance")) "Save-Module should Save a module if Confirm is accepted"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: SaveModuleWithDependencyAndNoToPrompt
    #
    # Action: Save-Module ModuleWithDependency
    #
    # Expected Result: User is prompted to accept license for dependant module. On No, neither of two modules is Saved
    #
    It "SaveModuleWithDependencyAndNoToPrompt" {
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 2 is mapped to NO in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake = 2
        $content = $null

        try {
            $result = ExecuteCommand $runspace "Save-Module ModuleWithDependency  -Path $script:MyDocumentsModulesPath -ErrorAction SilentlyContinue"
        }
        finally {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Module ModuleRequireLicenseAcceptance -Repository PSGallery

        $saveShouldProcessMessage = $script:LocalizedData.AcceptanceLicenseQuery -f ($itemInfo.Name)
        Assert ($content -and ($content -match $saveShouldProcessMessage)) "Save module confirm prompt is not working, Expected:$installShouldProcessMessage, Actual:$content"

        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        AssertNull $res "Save-Module should not save dependant module if Confirm is not accepted"

        $res = Get-Module ModuleWithDependency -ListAvailable
        AssertNull $res "Save-Module should not install a module if Confirm is not accepted"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))


    # Purpose: SaveModuleWithDependencyAcceptLicense
    #
    # Action: Save-Module ModuleWithDependency -AcceptLicennse
    #
    # Expected Result: module is installed successfully
    #
    It "SaveModuleWithDependencyAcceptLicense" {
        Save-Module ModuleWithDependency -AcceptLicense -Path $script:MyDocumentsModulesPath -ErrorAction Stop

        $res = Get-Module ModuleWithDependency -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleWithDependency")) "Install-Module should install the module if -AcceptLicense is specified"

        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleRequireLicenseAcceptance")) "Install-Module should install the module if -AcceptLicense is specified"
    }

    # Purpose: SaveScriptAndYesToPrompt
    #
    # Action: Save-Script ScriptRequireLicenseAcceptance
    #
    # Expected Result: Script and dependent module should be installed after confirming YES
    #
    It "SaveScriptAndYesToPrompt" {
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 0 is mapped to YES in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake = 0
        $content = $null

        try {
            $result = ExecuteCommand $runspace "Save-Script ScriptRequireLicenseAcceptance -Path $script:MyDocumentsModulesPath"
        }
        finally {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Module ModuleRequireLicenseAcceptance -Repository PSGallery
        $SaveShouldProcessMessage = $script:LocalizedData.AcceptanceLicenseQuery -f ($itemInfo.Name)
        Assert ($content -and ($content -match $SaveShouldProcessMessage)) "Save script confirm prompt is not working, Expected:$installShouldProcessMessage, Actual:$content"



        if (-not (Test-Path -Path "$script:MyDocumentsModulesPath\ScriptRequireLicenseAcceptance.ps1" -PathType Leaf)) {
            Assert $false "Save-Script should save script $ScriptName"
        }

        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleRequireLicenseAcceptance")) "Save-Module should save a module if Confirm is accepted"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: SaveScriptAcceptLicense
    #
    # Action: Save-Script ScriptRequireLicenseAcceptance -AcceptLicennse
    #
    # Expected Result: script and dependant module are Saved successfully
    #
    It "SaveScriptAcceptLicense" {
        Save-Script ScriptRequireLicenseAcceptance -AcceptLicense  -Path $script:MyDocumentsModulesPath -ErrorAction Stop

        if (-not (Test-Path -Path "$script:MyDocumentsModulesPath\ScriptRequireLicenseAcceptance.ps1" -PathType Leaf)) {
            Assert $false "Save-Script should save script $ScriptName"
        }

        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleRequireLicenseAcceptance")) "Save-Module should Save the module if -AcceptLicense is specified"
    }


    # Purpose: UpdateModuleRequiringLicenseAcceptanceAndNoToPrompt
    #
    # Action: Update-Module ModuleRequireLicenseAcceptance
    #
    # Expected Result: Module should not be updated after confirming NO
    #
    It "UpdateModuleRequiringLicenseAcceptanceAndNoToPrompt" {

        Install-module ModuleRequireLicenseAcceptance -RequiredVersion 1.0 -AcceptLicense -Force

        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 2 is mapped to NO in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake = 2
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Update-Module ModuleRequireLicenseAcceptance'
        }
        finally {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Module ModuleRequireLicenseAcceptance -Repository PSGallery

        $updateShouldProcessMessage = $script:LocalizedData.AcceptanceLicenseQuery -f ($itemInfo.Name)
        Assert ($content -and ($content -match $updateShouldProcessMessage)) "Update module confirm prompt is not working, Expected:$updateShouldProcessMessage, Actual:$content"



        $res = Get-Module ModuleRequireLicenseAcceptance -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ModuleRequireLicenseAcceptance") -and ($res.Version -eq [Version]"1.0")) "Update-Module should not update the module if confirm is declined"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))


    # Purpose: UpdateModuleRequiringLicenseAcceptanceAndYesToPrompt
    #
    # Action: Update-Module ModuleRequireLicenseAcceptance
    #
    # Expected Result: Module should be Updated after confirming YES
    #
    It "UpdateModuleRequiringLicenseAcceptanceAndYesToPrompt" {

        Install-module ModuleRequireLicenseAcceptance -RequiredVersion 1.0 -AcceptLicense -Force

        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 0 is mapped to YES in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake = 0
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Update-Module ModuleRequireLicenseAcceptance'
        }
        finally {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Module ModuleRequireLicenseAcceptance -Repository PSGallery

        $UpdateShouldProcessMessage = $script:LocalizedData.AcceptanceLicenseQuery -f ($itemInfo.Name)
        Assert ($content -and ($content -match $UpdateShouldProcessMessage)) "Update module confirm prompt is not working, Expected:$UpdateShouldProcessMessage, Actual:$content"

        $res = Get-InstalledModule ModuleRequireLicenseAcceptance -RequiredVersion 3.0
        AssertNotNull $res "Update-Module should Update a module if Confirm is accepted"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))


    # Purpose: UpdateModuleAcceptLicnese
    #
    # Action: Update-Module ModuleRequireLicenseAcceptance -AcceptLicennse
    #
    # Expected Result: module is Updated successfully
    #
    It "UpdateModuleAcceptLicnese" {
        Install-module ModuleRequireLicenseAcceptance -RequiredVersion 1.0 -AcceptLicense -Force
        Update-Module ModuleRequireLicenseAcceptance -AcceptLicense
        $res = Get-InstalledModule ModuleRequireLicenseAcceptance -RequiredVersion 3.0
        AssertNotNull $res "Update-Module should Update a module"
    }

    # Purpose: UpdateModuleForce
    #
    # Action: Update-Module ModuleRequireLicenseAcceptance -Force
    #
    # Expected Result: module should fail to Update with error ForceAcceptLicense
    #
    It "UpdateModuleForce" {
        Install-module ModuleRequireLicenseAcceptance -RequiredVersion 1.0 -AcceptLicense -Force
        AssertFullyQualifiedErrorIdEquals -scriptblock { Update-Module ModuleRequireLicenseAcceptance -Force }`
            -expectedFullyQualifiedErrorId 'ForceAcceptLicense,Update-Module'
    }
}
