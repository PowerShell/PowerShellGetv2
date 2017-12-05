<#####################################################################################
 # File: PSGetModuleSourceTests.ps1
 # Tests for PowerShellGet module functionality with PackageManagement integration
 #
 # Copyright (c) Microsoft Corporation, 2014
 #####################################################################################>

<#
   Name: PowerShell.PSGet.PackageManagementIntegrationTests
   Description: Tests for PowerShellGet module functionality with PackageManagement integration
#>

Describe PowerShell.PSGet.PackageManagementIntegrationTests -Tags 'P1','OuterLoop' {

    BeforeAll {
        Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
        Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

        $script:PSModuleSourcesPath = Get-PSGetLocalAppDataPath
        $script:ProgramFilesModulesPath = Get-AllUsersModulesPath
        $script:MyDocumentsModulesPath = Get-CurrentUserModulesPath
        $script:BuiltInModuleSourceName = "PSGallery"
        $script:PSGetModuleProviderName = 'PowerShellGet'

        #Bootstrap NuGet binaries
        Install-NuGetBinaries

        Import-Module PowerShellGet -Global -Force

        # Backup the existing module sources information
        $script:moduleSourcesFilePath= Join-Path $script:PSModuleSourcesPath "PSRepositories.xml"
        $script:moduleSourcesBackupFilePath = Join-Path $script:PSModuleSourcesPath "PSRepositories.xml_$(get-random)_backup"
        if(Test-Path $script:moduleSourcesFilePath)
        {
            Rename-Item $script:moduleSourcesFilePath $script:moduleSourcesBackupFilePath -Force
        }

        GetAndSet-PSGetTestGalleryDetails

        # the test module repository
        $script:TestModuleSourceUri = ''
        GetAndSet-PSGetTestGalleryDetails -PSGallerySourceUri ([REF]$script:TestModuleSourceUri)

        Unregister-PSRepository -Name $script:BuiltInModuleSourceName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        Register-PSRepository -Default -InstallationPolicy Trusted

        $script:TestModuleSourceName = "PSGetTestModuleSource"
    }

    AfterAll {
        if(Test-Path $script:moduleSourcesBackupFilePath)
        {
            Move-Item $script:moduleSourcesBackupFilePath $script:moduleSourcesFilePath -Force
        }
        else
        {
            RemoveItem $script:moduleSourcesFilePath
        }

        # To reload the repositories
        $null = Import-PackageProvider -Name PowerShellGet -Force
    }

    AfterEach {
        Get-PSRepository -Name $script:TestModuleSourceName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Unregister-PSRepository
        PSGetTestUtils\Uninstall-Module ContosoServer
        PSGetTestUtils\Uninstall-Module ContosoClient
    }

    <#
    Purpose: Validate the Register-PackageSource, Get-PackageSource and Unregister-PackageSource functionality with PowerShellGet provider

    Action: Register a module source and Get the registered module source details then unregister it.

    Expected Result: should be able to register, get the module source and unregister it.
    #>
    It ValidateRegisterPackageSourceWithPSModuleProvider {

        $Location='https://www.nuget.org/api/v2/'
        $beforePackageSources = Get-PackageSource -Provider $script:PSGetModuleProviderName

        Register-PackageSource -Name $script:TestModuleSourceName -Location $Location -Provider $script:PSGetModuleProviderName -Trusted
        $packageSource = Get-PackageSource -Name $script:TestModuleSourceName -Provider $script:PSGetModuleProviderName

        $packageSource | Unregister-PackageSource

        AssertEquals $packageSource.Name $script:TestModuleSourceName "The package source name is not same as the registered name"
        AssertEquals $packageSource.Location $Location "The package source location is not same as the registered location"
        AssertEquals $packageSource.IsTrusted $true "The package source IsTrusted is not same as specified in the registration"

        $afterPackageSources = Get-PackageSource -Provider $script:PSGetModuleProviderName

        AssertEquals $beforePackageSources.Count $afterPackageSources.Count "PackageSources count should be same after unregistering the package source with PowerShellGet provider"
    }

    <#
    Purpose: Validate the Register-PackageSource, Get-PackageSource and Unregister-PackageSource functionality with PowerShellGet provider and optional PackageManagementProvider value

    Action: Register a module source and Get the registered module source details then unregister it.

    Expected Result: should be able to register, get the module source and unregister it.
    #>
    It ValidateRegisterPackageSourceWithPSModuleProviderWithOptionalParams {

        $Location='https://www.nuget.org/api/v2/'
        $beforePackageSources = Get-PackageSource -Provider $script:PSGetModuleProviderName

        Register-PackageSource -Name $script:TestModuleSourceName -Location $Location -Provider $script:PSGetModuleProviderName -PackageManagementProvider "NuGet"

        $packageSource = Get-PackageSource -Name $script:TestModuleSourceName -Provider $script:PSGetModuleProviderName

        $packageSource | Unregister-PackageSource

        AssertEquals $packageSource.Name $script:TestModuleSourceName "The package source name is not same as the registered name"
        AssertEquals $packageSource.Location $Location "The package source location is not same as the registered location"
        AssertEquals $packageSource.IsTrusted $false "The package source IsTrusted is not same as specified in the registration"

        $afterPackageSources = Get-PackageSource -Provider $script:PSGetModuleProviderName

        AssertEquals $beforePackageSources.Count $afterPackageSources.Count "PackageSources count should be same after unregistering the package source with PowerShellGet provider"
    }

    <#
    Purpose: Validate the Register-PackageSource functionality with PowerShellGet provider and PackageManagementProvider which doesnt support modules

    Action: Register a module source with PackageManagementProvider name which doesn't support the modules.

    Expected Result: should fail.
    #>
    It ValidateRegisterPackageSourceWithPSModuleProviderOGPDoesntSupportModules {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PackageSource -provider PowerShellGet -Name TestSource -Location 'https://www.nuget.org/api/v2/' -PackageManagementProvider TestChainingPackageProvider} `
                                          -expectedFullyQualifiedErrorId "SpecifiedProviderNotAvailable,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.RegisterPackageSource"
    }

    <#
    Purpose: Validate the Register-PSRepository, Get-PSRepository, Set-PSRepository and Unregister-PSRepository functionality optional PackageManagementProvider value and InstallationPolicy

    Action: Register a module source and Get the registered module source details then unregister it.

    Expected Result: should be able to register, get the module source and unregister it.
    #>
    It ValidateModuleSourceCmdletsWithOptionalParams {

        $Location='https://www.nuget.org/api/v2/'

        $beforeSources = Get-PSRepository

        Register-PSRepository -Name $script:TestModuleSourceName -SourceLocation $Location -PackageManagementProvider "NuGet" -InstallationPolicy Trusted
        $source = Get-PSRepository -Name $script:TestModuleSourceName

        AssertEquals $source.Name $script:TestModuleSourceName "The module source name is not same as the registered name"
        AssertEquals $source.SourceLocation $Location "The module source location is not same as the registered location"
        AssertEquals $source.Trusted $true "The module source IsTrusted is not same as specified in the registration"
        AssertEquals $source.PackageManagementProvider "NuGet" "PackageManagementProvider name is not same as specified in the registration"
        AssertEquals $source.InstallationPolicy "Trusted" "The module source IsTrusted is not same as specified in the registration"

        Set-PSRepository -Name $script:TestModuleSourceName -InstallationPolicy Untrusted
        $source = Get-PSRepository -Name $script:TestModuleSourceName
        $source | Unregister-PSRepository

        AssertEquals $source.Name $script:TestModuleSourceName "The module source name is not same as the registered name"
        AssertEquals $source.SourceLocation $Location "The module source location is not same as the registered location"
        AssertEquals $source.Trusted $false "The module source IsTrusted is not same as specified in the registration"
        AssertEquals $source.PackageManagementProvider "NuGet" "PackageManagementProvider name is not same as specified in the registration"
        AssertEquals $source.InstallationPolicy "Untrusted" "The module source IsTrusted is not same as specified in the registration"

        $afterSources = Get-PSRepository

        AssertEquals $beforeSources.Count $afterSources.Count "Module Sources count should be same after unregistering the module source"
    }

    <#
    Purpose: Validate the Set-PSRepository to change the Location and InstallationPolicy values

    Action: Register a module source and change it's Location and InstallationPolicy values

    Expected Result: should be able to set new values.
    #>
    It ValidateSetModuleSourceWithNewLocationAndInstallationPolicyValues {

        $Location1 = 'https://www.nuget.org/api/v2/'
        $Location2 = $script:TestModuleSourceUri

        Register-PSRepository -Name $script:TestModuleSourceName -SourceLocation $Location1 -PackageManagementProvider "NuGet" -InstallationPolicy Trusted

        $source = Get-PSRepository -Name $script:TestModuleSourceName

        AssertEquals $source.Name $script:TestModuleSourceName "The module source name is not same as the registered name"
        AssertEquals $source.SourceLocation $Location1 "The module source location is not same as the registered location"
        AssertEquals $source.Trusted $true "The module source IsTrusted is not same as specified in the registration"
        AssertEquals $source.PackageManagementProvider "NuGet" "PackageManagementProvider name is not same as specified in the registration"
        AssertEquals $source.InstallationPolicy "Trusted" "The module source IsTrusted is not same as specified in the registration"

        Set-PSRepository -Name $script:TestModuleSourceName -SourceLocation $Location2 -InstallationPolicy Untrusted

        $source = Get-PSRepository -Name $script:TestModuleSourceName

        AssertEquals $source.Name $script:TestModuleSourceName "The module source name is not same as the specified"
        AssertEquals $source.SourceLocation $Location2 "The module source location is not same as the specified"
        AssertEquals $source.Trusted $false "The module source IsTrusted is not same as the specified"
        AssertEquals $source.PackageManagementProvider "NuGet" "PackageManagementProvider name is not same as the specified"
        AssertEquals $source.InstallationPolicy "Untrusted" "The module source IsTrusted is not same as the specified"
    }

    <#
    Purpose: Validate the Set-PSRepository with location of another module source

    Action: Register a module source and change it's location value same as that of another module source.

    Expected Result: should fail.
    #>
    It ValidateSetModuleSourceWithExistingLocationValue {

        $Location1 = 'https://nuget.org/api/v2/'
        $Location2 = 'https://msconfiggallery.cloudapp.net/api/v2/'

        Register-PSRepository -Name $script:TestModuleSourceName -SourceLocation $Location1 -PackageManagementProvider "NuGet"

        AssertFullyQualifiedErrorIdEquals -scriptblock {Set-PSRepository -Name $script:TestModuleSourceName -SourceLocation $Location2} `
                                          -expectedFullyQualifiedErrorId 'RepositoryAlreadyRegistered,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.SetPackageSource'
    }

    <#
    Purpose: Validate the Set-PSRepository to change the InstallationPolicy values for the built-in gallery

    Action: Change the InstallationPolicy values for built-in PSGallery source

    Expected Result: should be able to change the InstallationPolicy value.
    #>
    It ValidateSetModuleSourceWithNewLocationAndInstallationPolicyValuesForPSGallery {

        try {
            $ModuleSourceName='PSGallery'        

            Set-PSRepository -Name $ModuleSourceName -InstallationPolicy Trusted

            $source = Get-PSRepository -Name $ModuleSourceName

            AssertEquals $source.Name $ModuleSourceName "The module source name is not same as the specified"
            AssertEquals $source.Trusted $true "The module source IsTrusted is not same as the specified"
            AssertEquals $source.InstallationPolicy "Trusted" "The module source IsTrusted is not same as the specified"
        } finally {
            # Reset the InstallationPolicy
            Set-PSRepository -Name $script:BuiltInModuleSourceName -InstallationPolicy Untrusted
        }
    }
    
    <#
    Purpose: Validate the Get-InstalledPackage function in PowerShellGet provider using Get-Package cmdlet

    Action: Install a module, get package count, update the module, get package count

    Expected Result: should be able to get the installed package.
    #>
    It ValidateGetPackageCmdletWithPSModuleProvider {

        $ModuleName = 'ContosoServer'
        $Location = $script:TestModuleSourceUri
        Register-PSRepository -Name $script:TestModuleSourceName -SourceLocation $Location -PackageManagementProvider "NuGet" -InstallationPolicy Trusted

        Install-Module -Name ContosoClient -Repository $script:TestModuleSourceName
        $pkg = Get-Package -ProviderName $script:PSGetModuleProviderName -Name ContosoClient
        AssertEquals $pkg.Name ContosoClient "Get-Package returned wrong package, $pkg"

        Install-Module -Name $ModuleName -Repository $script:TestModuleSourceName -RequiredVersion 1.0 -Force
        $packages = Get-Package -ProviderName $script:PSGetModuleProviderName
        AssertNotNull $packages "Get-Package is not working with PowerShellGet provider"

        $pkg = Get-Package -ProviderName $script:PSGetModuleProviderName -Name $ModuleName
        AssertEquals $pkg.Name $ModuleName "Get-Package returned wrong package, $pkg"
        AssertEquals $pkg.Version "1.0" "Get-Package returned wrong package version, $pkg"

        $packages1 = Get-Package -ProviderName $script:PSGetModuleProviderName

        Update-Module -Name $ModuleName -RequiredVersion 2.0
        $pkg2 = Get-Package -ProviderName $script:PSGetModuleProviderName -Name $ModuleName -RequiredVersion "2.0"
        AssertEquals $pkg2.Name $ModuleName "Get-Package returned wrong package after Update-Module, $pkg2"
        AssertEquals $pkg2.Version "2.0"  "Get-Package returned wrong package version  after Update-Module, $pkg2"

        $packages2 = Get-Package -ProviderName $script:PSGetModuleProviderName

        # Because of TFS:1908563, we changed Get-Package to show only the latest version by default
        # hence the count is same after the update.
        AssertEquals $packages1.count $packages2.count "package count should be same before and after updating a package, before: $($packages1.count), after: $($packages2.count)"
    }
}
