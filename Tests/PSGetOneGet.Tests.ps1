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
        $script:IsWindows = (-not (Get-Variable -Name IsWindows -ErrorAction Ignore)) -or $IsWindows

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

        $script:userName = "PSGetUser"
        $password = "Password1"
        if($PSEdition -ne 'Core')
        {
            $null = net user $script:userName $password /add
        }
        else{
            $null = useradd $script:userName --password $password
        }
        $secstr = ConvertTo-SecureString $password -AsPlainText -Force
        $script:credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $script:userName, $secstr
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

    # Purpose: Install a package with current user scope parameter for non-admin User
    #
    # Action: Try to install a package with current user scope in a non-admin console
    #
    # Expected Result: It should succeed and install only to current user
    #
    It "InstallPackageWithCurrentUserScopeParameterForNonAdminUser" {
        $PSprocess = "pwsh"
        if ($script:IsWindows) {
            $PSprocess = "PowerShell.exe";
        }

        $NonAdminConsoleOutput = Join-Path ([System.IO.Path]::GetTempPath()) 'nonadminconsole-out.txt'

        Start-Process $PSprocess -ArgumentList '$null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser;
                                                              $null = Import-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force;
                                                              if(-not (Get-PSRepository -Name INTGallery -ErrorAction SilentlyContinue)) {
                                                                Register-PSRepository -Name INTGallery -SourceLocation https://dtlgalleryint.cloudapp.net/api/v2/ -InstallationPolicy Trusted
                                                              }
                                                              Install-Package -Name ContosoServer -Source INTGallery -Scope CurrentUser;
                                                              Get-Package ContosoServer | Format-List Name, SwidTagText' `
                                               -Credential $script:credential `
                                               -Wait `
                                               -RedirectStandardOutput $NonAdminConsoleOutput

        waitFor {Test-Path $NonAdminConsoleOutput} -timeoutInMilliseconds $script:assertTimeOutms -exceptionMessage "Install-Module on non-admin console failed to complete"
        $content = Get-Content $NonAdminConsoleOutput
        RemoveItem $NonAdminConsoleOutput

        AssertNotNull ($content) "Install package with CurrentUser scope on non-admin user console should succeed"
        Assert ($content -match "ContosoServer") "Package did not install correctly"
        if ($script:IsWindows) {
            Assert ($content -match "Documents") "Package did not install to the correct location"
        }
        else {
            Assert ($content -match "home") "Package did not install to the correct location"
        }
    } `
    -Skip:$(
        $whoamiValue = (whoami)

        ($whoamiValue -eq "NT AUTHORITY\SYSTEM") -or
        ($whoamiValue -eq "NT AUTHORITY\LOCAL SERVICE") -or
        ($whoamiValue -eq "NT AUTHORITY\NETWORK SERVICE") -or
        ($PSVersionTable.PSVersion -lt '4.0.0') -or
        # Temporarily skip tests until .NET Core is updated to v2.1
        ($PSEdition -eq 'Core')
    )

    # Purpose: Install a package with all users scope parameter for non-admin user
    #
    # Action: Try to install a package with all users scope in a non-admin console
    #
    # Expected Result: It should fail with an error
    #
    It "InstallPackageWithAllUsersScopeParameterForNonAdminUser" {
        $PSprocess = "pwsh"
        if ($script:IsWindows) {
            $PSprocess = "PowerShell.exe";
        }

        $NonAdminConsoleOutput = Join-Path ([System.IO.Path]::GetTempPath()) 'nonadminconsole-out.txt'

        Start-Process $PSprocess -ArgumentList '$null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers;
                                                              $null = Import-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force;
                                                              Install-Package ContosoServer -Source INTGallery -Scope AllUsers;
                                                              Get-InstalledModule -Name ContosoServer | Format-List Name, SwidTagText' `
                                               -Credential $script:credential `
                                               -Wait `
                                               -RedirectStandardOutput $NonAdminConsoleOutput


        waitFor {Test-Path $NonAdminConsoleOutput} -timeoutInMilliseconds $script:assertTimeOutms -exceptionMessage "Install-Package on non-admin console failed to complete"
        $content = Get-Content $NonAdminConsoleOutput
        RemoveItem $NonAdminConsoleOutput

        AssertNotNull ($content) "Install-Package with CurrentUser scope on non-admin user console should not succeed"
        Assert ($content -match "Administrator rights are required to install packages") "Install-package with AllUsers scope on non-admin user console should fail, $content"
    } `
    -Skip:$(
        $whoamiValue = (whoami)

        ($whoamiValue -eq "NT AUTHORITY\SYSTEM") -or
        ($whoamiValue -eq "NT AUTHORITY\LOCAL SERVICE") -or
        ($whoamiValue -eq "NT AUTHORITY\NETWORK SERVICE") -or
        ($PSVersionTable.PSVersion -lt '4.0.0') -or
        # Temporarily skip tests until .NET Core is updated to v2.1
        ($PSEdition -eq 'Core')
    )

    # Purpose: Install a package with default scope parameter for non-admin user
    #
    # Action: Try to install a package with default (current user) scope in a non-admin console
    #
    # Expected Result: It should succeed and install only to current user
    #
    It "InstallPackageWithDefaultScopeParameterForNonAdminUser" {
        $PSprocess = "pwsh"
        if ($script:IsWindows) {
            $PSprocess = "PowerShell.exe";
        }

        $NonAdminConsoleOutput = Join-Path ([System.IO.Path]::GetTempPath()) 'nonadminconsole-out.txt'

        Start-Process $PSprocess -ArgumentList '$null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser;
                                                              $null = Import-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force;
                                                              Install-Package ContosoServer -Source INTGallery;
                                                              Get-Package ContosoServer | Format-List Name, SwidTagText' `
                                               -Credential $script:credential `
                                               -Wait `
                                               -RedirectStandardOutput $NonAdminConsoleOutput

        waitFor {Test-Path $NonAdminConsoleOutput} -timeoutInMilliseconds $script:assertTimeOutms -exceptionMessage "Install-Package on non-admin console failed to complete"
        $content = Get-Content $NonAdminConsoleOutput
        RemoveItem $NonAdminConsoleOutput

        AssertNotNull ($content) "Install-Package with CurrentUser scope on non-admin user console should succeed"
        Assert ($content -match "ContosoServer") "Package did not install correctly"
        if ($script:IsWindows) {
            Assert ($content -match "Documents") "Package did not install to the correct location"
        }
        else {
            Assert ($content -match "home") "Package did not install to the correct location"
        }
    } `
    -Skip:$(
        $whoamiValue = (whoami)

        ($whoamiValue -eq "NT AUTHORITY\SYSTEM") -or
        ($whoamiValue -eq "NT AUTHORITY\LOCAL SERVICE") -or
        ($whoamiValue -eq "NT AUTHORITY\NETWORK SERVICE") -or
        ($PSVersionTable.PSVersion -lt '4.0.0') -or
        # Temporarily skip tests until .NET Core is updated to v2.1
        ($PSEdition -eq 'Core')
    )

    # Purpose: Install a packge with current user scope parameter for admin user
    #
    # Action: Try to install a package with current user scope in an admin console
    #
    # Expected Result: It should succeed and install to current user
    #
    It "InstallPackageWithCurrentUserScopeParameterForAdminUser" {
        Register-PSRepository -Name INTGallery -SourceLocation https://dtlgalleryint.cloudapp.net/api/v2/ -InstallationPolicy Trusted
        Install-Package -Name ContosoServer -Scope CurrentUser
        $pkg = Get-Package -Name ContosoServer
        Get-PSRepository -Name INTGallery -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Unregister-PSRepository

        AssertNotNull ($pkg) "Package did not install properly."
        Assert ($pkg.Name -eq "ContosoServer") "Get-Package returned wrong package, $($pkg.Name)"
        Assert($pkg.SwidTagText -match "Documents") "$($pkg.Name) did not install to the correct location"
    }

    # Purpose: Install a package with all users scope parameter for admin user
    #
    # Action: Try to install a package with all users scope in an admin console
    #
    # Expected Result: It should succeed and install to all users
    #
    It "InstallPackageWithAllUsersScopeParameterForAdminUser" {
        Register-PSRepository -Name INTGallery -SourceLocation https://dtlgalleryint.cloudapp.net/api/v2/ -InstallationPolicy Trusted
        Install-Package -Name ContosoServer -Scope AllUsers
        $pkg = Get-Package -Name ContosoServer
        Get-PSRepository -Name INTGallery -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Unregister-PSRepository

        AssertNotNull ($pkg) "Package did not install properly."
        Assert ($pkg.Name -eq "ContosoServer") "Get-Package returned wrong package, $($pkg.Name)"
        Assert($pkg.SwidTagText -match "Program Files") "$($pkg.Name) did not install to the correct location"
    }

    # Purpose: Install a package with default scope parameter for admin user
    #
    # Action: Try to install a package with default (all users) scope in an admin console
    #
    # Expected Result: It should succeed and install to all users if Windows, and current user if non-Windows.
    #
    It "InstallPackageWithDefaultScopeParameterForAdminUser" {
        Register-PSRepository -Name INTGallery -SourceLocation https://dtlgalleryint.cloudapp.net/api/v2/ -InstallationPolicy Trusted
        Install-Package -Name ContosoServer
        $pkg = Get-Package -Name ContosoServer
        Get-PSRepository -Name INTGallery -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Unregister-PSRepository


        AssertNotNull ($pkg) "Package did not install properly."
        Assert ($pkg.Name -eq "ContosoServer") "Get-Package returned wrong module, $($pkg.Name)"
        if ($script:IsWindows)
        {
            Assert($pkg.SwidTagText -match "Program Files") "$($pkg.Name) did not install to the correct location"
        }
        else
        {
            Assert($pkg.SwidTagText -match "Documents") "$($pkg.Name) did not install to the correct location"
        }
    }
}
