<#####################################################################################
 # File: PSGetModuleSourceTests.ps1
 # Tests for PowerShellGet module functionality with multiple module sources
 #
 # Copyright (c) Microsoft Corporation, 2014
 #####################################################################################>

<#
   Name: PowerShell.PSGet.ModuleSourceTests
   Description: Tests for PowerShellGet module functionality with multiple module sources

   The local directory based NuGet repository is used for publishing the modules.
#>

. "$PSScriptRoot\PSGetTests.Manifests.ps1"
. "$PSScriptRoot\PSGetTests.Generators.ps1"

function SuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue
    
    $script:ProgramFilesModulesPath = Get-AllUsersModulesPath
    $script:MyDocumentsModulesPath = Get-CurrentUserModulesPath
    $script:PSGetLocalAppDataPath = Get-PSGetLocalAppDataPath
    $script:TempPath = Get-TempPath
    $script:BuiltInModuleSourceName = "PSGallery"

    $script:URI200OK = "http://go.microsoft.com/fwlink/?LinkID=533903&clcid=0x409"
    $script:URI404NotFound = "http://go.microsoft.com/fwlink/?LinkID=533902&clcid=0x409"

    #Bootstrap NuGet binaries
    Install-NuGetBinaries

    $script:PowerShellGetModuleInfo = Import-Module PowerShellGet -Global -Force -PassThru

    Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $PowerShellGetModuleInfo.ModuleBase

    # Backup the existing module sources information
    $script:moduleSourcesFilePath= Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml"
    $script:moduleSourcesBackupFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml_$(get-random)_backup"
    if(Test-Path $script:moduleSourcesFilePath)
    {
        Rename-Item $script:moduleSourcesFilePath $script:moduleSourcesBackupFilePath -Force
    }

    $script:TestModuleSourceUri = ''
    GetAndSet-PSGetTestGalleryDetails -PSGallerySourceUri ([REF]$script:TestModuleSourceUri)

    # Register the test module source
    $script:TestModuleSourceName = "PSGetTestModuleSource"
    Register-PSRepository -Name $script:TestModuleSourceName -SourceLocation $script:TestModuleSourceUri -InstallationPolicy Trusted

    $repo = Get-PSRepository -Name $script:BuiltInModuleSourceName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    if($repo)
    {
        Set-PSRepository -Name $script:BuiltInModuleSourceName -InstallationPolicy Trusted -ErrorAction SilentlyContinue
    }
    else
    {
        Register-PSRepository -Default -InstallationPolicy Trusted
    }

    $modSource = Get-PSRepository -Name $script:TestModuleSourceName
    AssertEquals $modSource.SourceLocation $script:TestModuleSourceUri "Test module source is not set properly"

    # Create a temp folder
    $script:TempModulesPath= Join-Path $script:TempPath "PSGet_$(Get-Random)"
    $null = New-Item -Path $script:TempModulesPath -ItemType Directory -Force
}

function SuiteCleanup {
    if(Test-Path $script:moduleSourcesBackupFilePath)
    {
        Move-Item $script:moduleSourcesBackupFilePath $script:moduleSourcesFilePath -Force
    }
    else
    {
        Unregister-PSRepository -Name $script:TestModuleSourceName
    }

    # To reload the repositories
    $null = Import-PackageProvider -Name PowerShellGet -Force

    RemoveItem $script:TempModulesPath
}

Describe PowerShell.PSGet.ModuleSourceTests -Tags 'BVT','InnerLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    <#
    Purpose: Validate the Register-PSRepository and Get-PSRepository functionality

    Action: Register a module source and Get the registered module source details

    Expected Result: should be able to register and get the module source
    #>
    It RegisterAngGetModuleSource {

        $Name='MyTestModSourceForRegisterAngGet'
        $Location='https://www.nuget.org/api/v2/'

        Register-PSRepository -Default -ErrorAction SilentlyContinue
        
        try {
            Register-PSRepository -Name $Name -SourceLocation $Location
            $moduleSource = Get-PSRepository -Name $Name
            $allModuleSources = Get-PSRepository
            $defaultModuleSourceDetails = Get-PSRepository -Name $script:BuiltInModuleSourceName

            AssertEquals $moduleSource.Name $Name "The module source name is not same as the registered name"
            AssertEquals $moduleSource.SourceLocation $Location "The module source location is not same as the registered location"

            Assert (Test-Path $script:moduleSourcesFilePath) "Missing $script:moduleSourcesFilePath file after module source registration"

            Assert ($allModuleSources.Count -ge 3) "ModuleSources count should be >=3 with registed module source along with default PSGallery Source, $allModuleSources"

            AssertEquals $defaultModuleSourceDetails.Name $script:BuiltInModuleSourceName "The default module source name is not same as the expected module source name"
        }
        finally {
            Get-PSRepository -Name $Name -ErrorAction SilentlyContinue | Unregister-PSRepository
        }
    }

    <#
    Purpose: Validate the Register-PSRepository with SMB share

    Action: Register a repository with directory and Get the registered repository details

    Expected Result: should be able to register and get the repository
    #>
    It RegisterSMBShareRepository {

        $Name='MyTestModSource'
        $Location=$script:TempModulesPath
        try
        {
            Register-PSRepository -Name $Name -SourceLocation $Location -PublishLocation $Location
            $repo = Get-PSRepository -Name $Name

            AssertEquals $repo.Name $Name "The repository name is not same as the registered name. Actual: $($repo.Name), Expected: $Name"
            AssertEquals $repo.SourceLocation $Location "The SourceLocation is not same as the registered SourceLocation. Actual: $($repo.SourceLocation), Expected: $Location"
            AssertEquals $repo.PublishLocation $Location "The PublishLocation is not same as the registered PublishLocation. Actual: $($repo.PublishLocation), Expected: $Location"
        }
        finally
        {
            Get-PSRepository -Name $Name | Unregister-PSRepository
        }
    }

    <#
    Purpose: Validate the Set-PSRepository with SMB share

    Action: Register and Set a repository with directory and Get the registered repository details

    Expected Result: should be able to set and get the repository
    #>
    It SetPSRepositoryWithSMBSharePath {

        $Name='MyTestModSource'
        $Location=$script:TempModulesPath
        try
        {
            Register-PSRepository -Name $Name -SourceLocation $Location
            Set-PSRepository -Name $Name -SourceLocation $Location -PublishLocation $Location
            $repo = Get-PSRepository -Name $Name

            AssertEquals $repo.Name $Name "The repository name is not same as the registered name. Actual: $($repo.Name), Expected: $Name"
            AssertEquals $repo.SourceLocation $Location "The SourceLocation is not same as the registered SourceLocation. Actual: $($repo.SourceLocation), Expected: $Location"
            AssertEquals $repo.PublishLocation $Location "The PublishLocation is not same as the registered PublishLocation. Actual: $($repo.PublishLocation), Expected: $Location"
        }
        finally
        {
            Get-PSRepository -Name $Name | Unregister-PSRepository
        }
    }

    <#
    Purpose: Validate the Unregister-PSRepository functionality

    Action: Unregister the registered module source

    Expected Result: module source should be unregistered and Get-PSRepository should fail with that name
    #>
    It UnregisterModuleSource {

        $Name='MyTestModSource'
        $Location='https://www.nuget.org/api/v2/'

        Register-PSRepository -Name $Name -SourceLocation $Location
        Unregister-PSRepository -Name $Name

        $expectedFullyQualifiedErrorId = 'SourceNotFound,Microsoft.PowerShell.PackageManagement.Cmdlets.GetPackageSource'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Get-PSRepository -Name $Name} `
                                          -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    <#
    Purpose:  Test Check-PSGalleryApiAvailability and Get-PSGalleryApiAvailability cmdlet for Stage 1 of PSGallery V2/V3 Transition.

    Action:  Check-PSGalleryApiAvailability -PSGalleryV2ApiUri $Uri200Ok -PSGalleryV3ApiUri $Uri404NotFound
             Get-PSGalleryApiAvailability -Repository PSGallery

    Expected Result:  Should show and do nothing.
    #>
    It CheckGetPSGalleryApiAvailabilityStage1 {
        
        $result = & $script:PowerShellGetModuleInfo Check-PSGalleryApiAvailability -PSGalleryV2ApiUri $script:Uri200Ok -PSGalleryV3ApiUri $script:Uri404NotFound
        AssertNull $result "Check-PSGalleryApiAvailability Stage 1 should not return anything."

        $err = $null
        try
        {
            $result = & $script:PowerShellGetModuleInfo Get-PSGalleryApiAvailability -Repository "PSGallery" -WarningVariable w
        }
        catch
        {
            $err = $_
        }

        AssertNull $result "Get-PSGalleryApiAvailability Stage 1 should not return anything."
        AssertEquals 0 $w.Count "Get-PSGalleryApiAvailability Stage 1 should not write a warning."
        AssertNull $err "Get-PSGalleryApiAvailability Stage 1 should not throw an error message."
    }

    <#
    Purpose:  Test Check-PSGalleryApiAvailability and Get-PSGalleryApiAvailability cmdlet for Stage 2 of PSGallery V2/V3 Transition.

    Action:  Check-PSGalleryApiAvailability -PSGalleryV2ApiUri $Uri200Ok -PSGalleryV3ApiUri $Uri200Ok
             Get-PSGalleryApiAvailability -Repository PSGallery

    Expected Result:  Should display a warning.
    #>
    It CheckGetPSGalleryApiAvailabilityStage2 {
      
        try {      
            $result = & $script:PowerShellGetModuleInfo Check-PSGalleryApiAvailability -PSGalleryV2ApiUri $script:Uri200Ok -PSGalleryV3ApiUri $script:Uri200Ok
            AssertNull $result "Check-PSGalleryApiAvailability Stage 2 should not return anything."

            $err = $null
            try
            {
                $result = & $script:PowerShellGetModuleInfo Get-PSGalleryApiAvailability -Repository "PSGallery" -WarningVariable w -WarningAction SilentlyContinue
            }
            catch
            {
                $err = $_
            }

            AssertNull $result "Get-PSGalleryApiAvailability Stage 2 should not return anything."
            AssertNotEquals 0 $w.Count "Get-PSGalleryApiAvailability Stage 2 should write a warning."
            #AssertEqualsCaseInsensitive $script:LocalizedData.PSGalleryApiV2Deprecated $w[0].Message "Get-PSGalleryApiAvailability Stage 2 wrote the wrong warning message."
            AssertNull $err "Get-PSGalleryApiAvailability Stage 2 should not throw an error message."
        }
        finally {
            # Set API availability for v2 back to true (no warnings or errors thrown)
            $result = & $script:PowerShellGetModuleInfo Check-PSGalleryApiAvailability -PSGalleryV2ApiUri $script:Uri200Ok -PSGalleryV3ApiUri $script:URI404NotFound
        }
    }

    <#
    Purpose:  Test Check-PSGalleryApiAvailability and Get-PSGalleryApiAvailability cmdlet for Stage 3 of PSGallery V2/V3 Transition.

    Action:  Check-PSGalleryApiAvailability -PSGalleryV2ApiUri $Uri404NotFound -PSGalleryV3ApiUri $Uri200Ok
             Get-PSGalleryApiAvailability -Repository PSGallery

    Expected Result:  Should throw an error.
    #>
    It CheckGetPSGalleryApiAvailabilityStage3 {
        try {
            $result = & $script:PowerShellGetModuleInfo Check-PSGalleryApiAvailability -PSGalleryV2ApiUri $script:Uri404NotFound -PSGalleryV3ApiUri $script:Uri200Ok
            AssertNull $result "Check-PSGalleryApiAvailability Stage 3 should not return anything."

            $err = $null
            try
            {
                $result = & $script:PowerShellGetModuleInfo Get-PSGalleryApiAvailability -Repository "PSGallery" -WarningVariable w
            }
            catch
            {
                $err = $_
            }

            AssertNull $result "Get-PSGalleryApiAvailability Stage 3 should not return anything."
            AssertEquals 0 $w.Count "Get-PSGalleryApiAvailability Stage 3 should not write a warning."
            AssertNotNull $err "Get-PSGalleryApiAvailability Stage 3 should throw an error message."
            AssertEqualsCaseInsensitive "PSGalleryApiV2Discontinued,Get-PSGalleryApiAvailability" $err.FullyQualifiedErrorId "Get-PSGalleryApiAvailability Stage 3 threw a different error: $err"
        }
        finally {            
            # Set API availability for v2 back to true (no warnings or errors thrown)
            $result = & $script:PowerShellGetModuleInfo Check-PSGalleryApiAvailability -PSGalleryV2ApiUri $script:Uri200Ok -PSGalleryV3ApiUri $script:URI404NotFound
        }
    }

    <#
    Purpose:  Test Check-PSGalleryApiAvailability and Get-PSGalleryApiAvailability cmdlet when no API is available.  
                This indicates that the site is down.

    Action:  Check-PSGalleryApiAvailability -PSGalleryV2ApiUri $Uri404NotFound -PSGalleryV3ApiUri $Uri404NotFound
             Get-PSGalleryApiAvailability -Repository PSGallery

    Expected Result:  Should throw an error.
    #>
    It CheckGetPSGalleryUnavailable {
        try {
            $result = & $script:PowerShellGetModuleInfo Check-PSGalleryApiAvailability -PSGalleryV2ApiUri $script:Uri404NotFound -PSGalleryV3ApiUri $script:Uri404NotFound
            AssertNull $result "Check-PSGalleryApiAvailability should not return anything."

            $err = $null
            try
            {
                $result = & $script:PowerShellGetModuleInfo Get-PSGalleryApiAvailability -Repository "PSGallery" -WarningVariable w
            }
            catch
            {
                $err = $_
            }

            AssertNull $result "Get-PSGalleryApiAvailability should not return anything."
            AssertEquals 0 $w.Count "Get-PSGalleryApiAvailability should not write a warning."
            AssertNotNull $err "Get-PSGalleryApiAvailability Stage 3 should throw an error message."
            AssertEqualsCaseInsensitive "PowerShellGalleryUnavailable,Get-PSGalleryApiAvailability" $err.FullyQualifiedErrorId "Get-PSGalleryApiAvailability Stage 3 threw a different error: $err"
        }
        finally {            
            # Set API availability for v2 back to true (no warnings or errors thrown)
            $result = & $script:PowerShellGetModuleInfo Check-PSGalleryApiAvailability -PSGalleryV2ApiUri $script:Uri200Ok -PSGalleryV3ApiUri $script:URI404NotFound
        }
    }
    
    <#
    Purpose:  Test Get-PSGalleryApiAvailability cmdlet when no repository specified.

    Action:   Get-PSGalleryApiAvailability

    Expected Result:  Should show and do nothing.
    #>
    It GetPSGalleryApiAvailabilityNoRepositorySpecified {
        
        $err = $null
        try
        {
            $result = & $script:PowerShellGetModuleInfo Get-PSGalleryApiAvailability -WarningVariable w
        }
        catch
        {
            $err = $_
        }

        AssertNull $result "Get-PSGalleryApiAvailability should not return anything."
        AssertEquals 0 $w.Count "Get-PSGalleryApiAvailability should not write a warning."
        AssertNull $err "Get-PSGalleryApiAvailability should not throw an error message."
    }


    <#
    Purpose:  Test Get-PSGalleryApiAvailability cmdlet when no repository specified.

    Action:   Get-PSGalleryApiAvailability

    Expected Result:  Should show and do nothing.
    #>
    It GetPSGalleryApiAvailabilityDifferentRepositorySpecified {
        
        $err = $null
        try
        {
            $result = & $script:PowerShellGetModuleInfo Get-PSGalleryApiAvailability -Repository "MSPSGallery" -WarningVariable w
        }
        catch
        {
            $err = $_
        }

        AssertNull $result "Get-PSGalleryApiAvailability should not return anything."
        AssertEquals 0 $w.Count "Get-PSGalleryApiAvailability should not write a warning."
        AssertNull $err "Get-PSGalleryApiAvailability should not throw an error message."
    }
}

Describe PowerShell.PSGet.ModuleSourceTests.P1 -Tags 'P1','OuterLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    <#
    Purpose: Validate the Register-PSRepository with not available directory path

    Action: Register a repository with not available directory path

    Expected Result: should fail
    #>
    It RegisterPSRepositoryWithInvalidSMBShareSourceLocation {

        $Name='MyTestModSource'
        $Location = Join-Path $script:TempPath 'DirNotAvailable'
        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name $Name -SourceLocation $Location} `
                                          -expectedFullyQualifiedErrorId "PathNotFound,Register-PSRepository"
    }

    <#
    Purpose: Validate the Register-PSRepository with invalid SMB share value

    Action: Register a repository with not available directory path

    Expected Result: should fail
    #>
    It RegisterPSRepositoryWithInvalidSMBSharePublishLocation {

        $Name='MyTestModSource'
        $Location=$script:TempModulesPath
        $PublishLocation = Join-Path $script:TempPath 'DirNotAvailable'
        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name $Name -SourceLocation $Location -PublishLocation $PublishLocation} `
                                          -expectedFullyQualifiedErrorId "PathNotFound,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.RegisterPackageSource"
    }

    <#
    Purpose: Validate the Set-PSRepository with invalid SMB share value

    Action: Register a repository with a valid directory and set it to invalid directory

    Expected Result: should fail
    #>
    It SetPSRepositoryWithInvalidSMBShareSourceLocation {

        $Name='MyTestModSource'
        $Location=$script:TempModulesPath
        $Location2 = Join-Path $script:TempPath 'DirNotAvailable'
        try
        {
            Register-PSRepository -Name $Name -SourceLocation $Location
            AssertFullyQualifiedErrorIdEquals -scriptblock {Set-PSRepository -Name $Name -SourceLocation $Location2} `
                                              -expectedFullyQualifiedErrorId "PathNotFound,Set-PSRepository"
        }
        finally
        {
            Get-PSRepository -Name $Name | Unregister-PSRepository
        }
    }

    <#
    Purpose: Validate the Set-PSRepository with invalid SMB share value

    Action: Register a repository with a valid directory and set it to invalid directory

    Expected Result: should fail
    #>
    It SetPSRepositoryWithInvalidSMBSharePublishLocation {

        $Name='MyTestModSource'
        $Location=$script:TempModulesPath
        $Location2 = Join-Path $script:TempPath 'DirNotAvailable'
        try
        {
            Register-PSRepository -Name $Name -SourceLocation $Location -PublishLocation $Location
            AssertFullyQualifiedErrorIdEquals -scriptblock {Set-PSRepository -Name $Name -SourceLocation $Location -PublishLocation $Location2} `
                                              -expectedFullyQualifiedErrorId "PathNotFound,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.SetPackageSource"
        }
        finally
        {
            Get-PSRepository -Name $Name | Unregister-PSRepository
        }
    }

    <#
    Purpose: Validate the Get-PSRepository functionality with wildcards in name

    Action: Register a module source and Get the registered module source with wildcards in name

    Expected Result: should get the module source names with wildcards
    #>
    It GetModuleSourceWithWildCards {
        $Name='MyTestModSource'
        $Location='https://www.nuget.org/api/v2/'
        try
        {
            Register-PSRepository -Name $Name -SourceLocation $Location
            $moduleSource = Get-PSRepository -Name 'MyTestModS*rce'

            AssertEquals $moduleSource.Name $Name "The module source name is not same as the registered name"
            AssertEquals $moduleSource.SourceLocation $Location "The module source location is not same as the registered location"

            Assert (Test-Path $script:moduleSourcesFilePath) "Missing $script:moduleSourcesFilePath file after module source registration"
        }
        finally
        {
            Get-PSRepository -Name $Name | Unregister-PSRepository
        }
    }

    <#
    Purpose: Validate Register-PSRepository functionality with existing source name

    Action: Register a module source with existing name

    Expected Result: Should fail with an error
    #>
    It RegisterModuleSourceWithSameName {
        $Name='MyTestModSource'
        $Location='https://www.nuget.org/api/v2/'
        try
        {
            Register-PSRepository -Name $Name -SourceLocation $Location

            AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name $Name -SourceLocation $Location} `
                                              -expectedFullyQualifiedErrorId 'PackageSourceExists,Microsoft.PowerShell.PackageManagement.Cmdlets.RegisterPackageSource'
        }
        finally
        {
            Get-PSRepository -Name $Name | Unregister-PSRepository
        }
    }

    <#
    Purpose: Validate Register-PSRepository functionality with location same as the existing source

    Action: Register a module source with same location as the already registered module source

    Expected Result: Should fail with an error
    #>
    It RegisterModuleSourceWithAlreadyRegisteredLocation {
        $Name='MyTestModSource'
        $Location='https://www.nuget.org/api/v2/'
        try
        {
            Register-PSRepository -Name $Name -SourceLocation $Location

            $expectedFullyQualifiedErrorId = 'RepositoryAlreadyRegistered,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.RegisterPackageSource'

            AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name 'MyTestModSource2' -SourceLocation $Location} `
                                              -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
        }
        finally
        {
            Get-PSRepository -Name $Name | Unregister-PSRepository
        }
    }

    <#
    Purpose: Validate Register-PSRepository functionality with non available location

    Action: Register a module source with non available location

    Expected Result: Should fail with an error
    #>
    It RegisterModuleSourceWithNotAvailableLocation {

        $expectedFullyQualifiedErrorId = 'InvalidWebUri,Register-PSRepository'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name myNuGetSource -SourceLocation https://www.nonexistingcompany.com/api/v2/} `
                                    -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    <#
    Purpose: Validate Register-PSRepository functionality with non available location and without api/v2

    Action: Register a module source with non available location

    Expected Result: Should fail with an error
    #>
    It RegisterModuleSourceWithNotAvailableLocation2 {

        $expectedFullyQualifiedErrorId = 'InvalidWebUri,Register-PSRepository'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name myNuGetSource2 -SourceLocation https://www.nonexistingcompany.com} `
                                          -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    <#
    Purpose: Validate Register-PSRepository functionality with invalid URL

    Action: Register a module source with invalid URL

    Expected Result: Should fail with an error
    #>
    It RegisterModuleSourceWithInvalidWebUri {

        $expectedFullyQualifiedErrorId = 'PathNotFound,Register-PSRepository'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name myNuGetSource1 -SourceLocation myget.org/F/powershellgetdemo} `
                                          -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }
    
    <#
    Purpose: Validate Register-PSRepository functionality with wildcard in source name

    Action: Register a module source with wildcard in source name

    Expected Result: Should fail with an error
    #>
    It RegisterModuleSourceWithWildCardInName {

        $expectedFullyQualifiedErrorId = 'RepositoryNameContainsWildCards,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.RegisterPackageSource'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name my*NuGetSource -SourceLocation https://www.myget.org/F/powershellgetdemo} `
                                          -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    <#
    Purpose: Validate Get-PSRepository functionality with non registered modul source

    Action: Get the non-registered module source details

    Expected Result: Should fail with an error
    #>
    It GetNonRegisteredModuleSource {

        $expectedFullyQualifiedErrorId = 'SourceNotFound,Microsoft.PowerShell.PackageManagement.Cmdlets.GetPackageSource'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Get-PSRepository -Name 'MyTestModSourceNotRegistered'} `
                                          -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    <#
    Purpose: Validate Get-PSRepository functionality with wildcard in non registered modul source name

    Action: Get the non-registered module source details with wildcard in the name

    Expected Result: Should return null results without any error
    #>
    It GetNonRegisteredModuleSourceNameWithWildCards {
        $moduleSources = Get-PSRepository -Name 'MyTestModSourceNotRegiste*ed' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        AssertNull $moduleSources "Get-PSRepository should not return the $moduleSources module source"
    }

    <#
    Purpose: Validate the Unregister-PSRepository functionality with wildcards in name

    Action: Unregister a registered module source name with wildcards

    Expected Result: should fail with an error
    #>
    It UnregisterModuleSourceWithWildCards {
        $Name='MyTestModSource'
        $Location='https://www.nuget.org/api/v2/'
        try
        {
            Register-PSRepository -Name $Name -SourceLocation $Location

            AssertFullyQualifiedErrorIdEquals -scriptblock {Unregister-PSRepository -Name 'MyTestMo*ource'} `
                                              -expectedFullyQualifiedErrorId 'RepositoryNameContainsWildCards,Unregister-PSRepository'
        }
        finally
        {
            Get-PSRepository $Name -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Unregister-PSRepository
        }
    }

    <#
    Purpose: Validate the Unregister-PSRepository functionality with built-in repository name

    Action: Unregister built-in module source $script:BuiltInModuleSourceName

    Expected Result: should not fail
    #>
    It UnregisterBuiltinModuleSource {
        try {
            Unregister-PSRepository -Name $script:BuiltInModuleSourceName

            $expectedFullyQualifiedErrorId = 'SourceNotFound,Microsoft.PowerShell.PackageManagement.Cmdlets.GetPackageSource'
            AssertFullyQualifiedErrorIdEquals -scriptblock {Get-PSRepository -Name $script:BuiltInModuleSourceName} `
                                              -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId

            $expectedFullyQualifiedErrorId = 'PSGalleryNotFound,Publish-Module'
            AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Name MyTempModule} `
                                              -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
        }
        finally {
            Register-PSRepository -Default -InstallationPolicy Trusted
        }
    } `
    -Skip:$($PSEdition -eq 'Core')

    <#
    Purpose: Validate the Unregister-PSRepository functionality with non-registered module source name

    Action: Unregister a not registered module source

    Expected Result: should fail with an error
    #>
    It UnregisterNotRegisteredModuleSource {

        $expectedFullyQualifiedErrorId = 'SourceNotFound,Microsoft.PowerShell.PackageManagement.Cmdlets.UnregisterPackageSource'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Unregister-PSRepository -Name "NonAvailableModuleSource"} `
                                          -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    It RegisterPSRepositoryShouldFailWithPSModuleAsPMProviderName {        
        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name Foo -SourceLocation $script:TempPath -PackageManagementProvider PowerShellGet} `
                                          -expectedFullyQualifiedErrorId "InvalidPackageManagementProviderValue,Register-PSRepository"
    }

    It SetPSRepositoryShouldFailWithPSModuleAsPMProviderName {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Set-PSRepository -Name PSGallery -PackageManagementProvider PowerShellGet} `
                                          -expectedFullyQualifiedErrorId "InvalidPackageManagementProviderValue,Set-PSRepository"
    }

    It RegisterPackageSourceShouldFailWithPSModuleAsPMProviderName {        
        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PackageSource -ProviderName PowerShellGet -Name Foo -Location $script:TempPath -PackageManagementProvider PowerShellGet} `
                                          -expectedFullyQualifiedErrorId "InvalidPackageManagementProviderValue,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.RegisterPackageSource"
    }
}

Describe PowerShell.PSGet.FindModule.ModuleSourceTests.P1 -Tags 'P1','OuterLoop' {

    # Not executing these tests on MacOS as 
    # the total execution time is exceeding allowed 50 min in TravisCI daily builds.
    if($IsMacOS) {
        return
    }

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    <#
    Purpose: Verify the Find-Module functionality with different values for -Repository parameter.

    Action: Use parameter generator to get different values to be tested with Find-Module cmdlet

    Expected Result: Module list or Error depending on the input variation
    #>
    $ParameterSets = Get-FindModuleWithSourcesParameterSets
    $ParameterSetCount = $ParameterSets.Count
    $i = 1
    foreach ($inputParameters in $ParameterSets)
    {
        Write-Verbose -Message "Combination #$i out of $ParameterSetCount"
        Write-Verbose -Message "$($inputParameters | Out-String)"
        Write-Progress -Activity "Combination $i out of $ParameterSetCount" -PercentComplete $(($i/$ParameterSetCount) * 100)

        $scriptBlock = $null
        if($inputParameters.Name -and $inputParameters.Source)
        {
            $scriptBlock = { Find-Module -Name $inputParameters.Name -Repository $inputParameters.Source }.GetNewClosure()
        }
        elseif($inputParameters.Name)
        {
            $scriptBlock = { Find-Module -Name $inputParameters.Name }.GetNewClosure()
        }
        elseif($inputParameters.Source)
        {
            $scriptBlock = { Find-Module -Repository $inputParameters.Source }.GetNewClosure()
        }
        else
        {
            $scriptBlock = { Find-Module }
        }

        It "FindModuleWithModuleSourcesTests - Combination $i/$ParameterSetCount" {
            if($inputParameters.PositiveCase)
            {
                $res = Invoke-Command -ScriptBlock $scriptBlock

                if($inputParameters.ExpectedModuleCount -gt 1)
                {
                    Assert ($res.Count -ge $inputParameters.ExpectedModuleCount) "Combination #$i : Find-Module did not return expected module count with Source input. Actual value $($res.Count) should be greater than or equal to the expected value $($inputParameters.ExpectedModuleCount)."
                }
                else
                {
                    AssertEqualsCaseInsensitive $res.Name $inputParameters.Name "Combination #$i : Find-Module did not return expected module with Source input"
                }
            }
            else
            {
                AssertFullyQualifiedErrorIdEquals -scriptblock $scriptBlock -expectedFullyQualifiedErrorId $inputParameters.FullyQualifiedErrorID
            }
        }

        $i = $i+1
    }
}

Describe PowerShell.PSGet.InstallModule.ModuleSourceTests.P1 -Tags 'P1','OuterLoop' {

    # Not executing these tests on MacOS as 
    # the total execution time is exceeding allowed 50 min in TravisCI daily builds.
    if($IsMacOS) {
        return
    }

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    <#
    Purpose: Verify the Install-Module functionality with different values for -Repository parameter.

    Action: Use parameter generator to get different values to be tested with Install-Module cmdlet

    Expected Result: The specified module should be installed or fail with an error depending on the input variation
    #>
    $ParameterSets = Get-InstallModuleWithSourcesParameterSets
    $ParameterSetCount = $ParameterSets.Count
    $i = 1
    foreach ($inputParameters in $ParameterSets)
    {
        Write-Verbose -Message "Combination #$i out of $ParameterSetCount"
        Write-Verbose -Message "$($inputParameters | Out-String)"
        Write-Progress -Activity "Combination $i out of $ParameterSetCount" -PercentComplete $(($i/$ParameterSetCount) * 100)

        $scriptBlock = $null
        if($inputParameters.Source)
        {
            $scriptBlock = { Install-Module -Name $inputParameters.Name -Repository $inputParameters.Source }.GetNewClosure()
        }
        else
        {
            $scriptBlock = { Install-Module -Name $inputParameters.Name }.GetNewClosure()
        }

        It "InstallModuleWithModuleSourcesTests - Combination $i/$ParameterSetCount" {
            try {
                if($inputParameters.PositiveCase)
                {
                    Invoke-Command -ScriptBlock $scriptBlock

                    $res = Get-Module -ListAvailable -Name $inputParameters.Name

                    AssertEqualsCaseInsensitive $res.Name $inputParameters.Name "Combination #$i : Install-Module did not install the expected module with Source input, $res"
                }
                else
                {
                    AssertFullyQualifiedErrorIdEquals -scriptblock $scriptBlock -expectedFullyQualifiedErrorId $inputParameters.FullyQualifiedErrorID
                }
            } finally {
                PSGetTestUtils\Uninstall-Module $inputParameters.Name
            }
        }

        $i = $i+1
    }
}