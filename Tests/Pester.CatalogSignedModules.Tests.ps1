﻿# This is a Pester test suite to validate the PowerShellGet cmdlets with VSTS Authenticated feeds.
#
# Copyright (c) Microsoft Corporation, 2016

Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue

$Script:RepositoryName = 'Local'
$SourceLocation = "$PSScriptRoot\PSGalleryTestRepo"
$Script:RegisteredLocalRepo = $false

$Script:INTRepositoryName = 'DTLGalleryINT'
$Script:INTRepoLocation = 'https://dtlgalleryint.cloudapp.net/api/v2'
$Script:RegisteredINTRepo = $false

$MicrosoftPowerShellArchive = 'Microsoft.PowerShell.Archive'
$TestArchiveModule = 'TestArchiveModule'
$ContosoServer = 'ContosoServer'
$SmallContosoServer = 'SmallContosoServer'
$SystemModulesPath = Join-Path -Path $PSHOME -ChildPath 'Modules'
$ProgramFilesModulesPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell\Modules"

function Publish-TestModule
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [Version]
        $Version
    )

    if(-not (Test-Path -Path "$SourceLocation\$Name.$version.nupkg" -PathType Leaf))
    {
        $SourceModulePath = Join-Path -Path $PSScriptRoot -ChildPath "TestModules\$Name\$version"
        Publish-Module -Path $SourceModulePath -Repository $Script:RepositoryName -Force -WarningAction SilentlyContinue
    }
}

function SignAndPublish-TestModule
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [Version]
        $Version,

        [Parameter(Mandatory=$true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        $Certificate
    )

    if(-not (Test-Path -Path "$SourceLocation\$Name.$version.nupkg" -PathType Leaf))
    {
        $SourceModulePath = Join-Path -Path $PSScriptRoot -ChildPath "TestModules\$Name\$version"
        $catalogFilePath = "$SourceModulePath\$Name.cat"

        $null = Set-AuthenticodeSignature -Certificate $Certificate -FilePath "$SourceModulePath\$Name.psd1"

        if(($version -ne [Version]'1.0.1.2') -and 
           (Get-Command -Name New-FileCatalog -Module Microsoft.PowerShell.Security -ErrorAction SilentlyContinue))
        {
            Remove-Item -Path $catalogFilePath -Force -ErrorAction SilentlyContinue
            $null = New-FileCatalog -Path $SourceModulePath -CatalogFilePath $catalogFilePath
        }

        $null = Set-AuthenticodeSignature -Certificate $Certificate -FilePath $catalogFilePath
        Publish-Module -Path $SourceModulePath -Repository $Script:RepositoryName -Force -WarningAction SilentlyContinue
    }
}

function SuiteSetup {
    Install-NuGetBinaries

    if(-not (Test-Path -Path $SourceLocation -PathType Container))
    {
        $null = New-Item -Path $SourceLocation -ItemType Directory -Force
    }

    $repo = Get-PSRepository -ErrorAction SilentlyContinue | 
                Where-Object {$_.SourceLocation.StartsWith($SourceLocation, [System.StringComparison]::OrdinalIgnoreCase)}
    if($repo)
    {
        $Script:RepositoryName = $repo.Name
    }
    else
    {
        Register-PSRepository -Name $Script:RepositoryName -SourceLocation $SourceLocation -InstallationPolicy Trusted
        $Script:RegisteredLocalRepo = $true
    }

    $INTRepo = Get-PSRepository -ErrorAction SilentlyContinue | 
                   Where-Object {$_.SourceLocation.StartsWith($Script:INTRepoLocation, [System.StringComparison]::OrdinalIgnoreCase)}
    if($INTRepo)
    {
        $Script:INTRepositoryName = $INTRepo.Name
    }
    else
    {
        Register-PSRepository -Name $Script:INTRepositoryName -SourceLocation $Script:INTRepoLocation -InstallationPolicy Trusted
        $Script:RegisteredINTRepo = $true
    }

    # Publish test modules to the repository
    @('1.0.1.3','1.0.1.4') | ForEach-Object { Publish-TestModule -Name $TestArchiveModule -Version $_ }
    @('1.0','1.5','2.0','2.5') | ForEach-Object { Publish-TestModule -Name $ContosoServer -Version $_ }
    Publish-TestModule -Name $SmallContosoServer -Version 1.0

    if(([System.Environment]::OSVersion.Version -le '6.1.7601.65536') -or ($PSVersionTable.PSVersion -lt '5.1.0'))
    {
        @('1.0.1.1','1.0.1.2','1.0.1.5', '1.0.1.11') | ForEach-Object { Publish-TestModule -Name $TestArchiveModule -Version $_ }
        Publish-TestModule -Name $MicrosoftPowerShellArchive -Version '1.0.1.5'
    }
    else
    {
        # Create certificate and publish the versions of TestArchiveModule
        # Create a new test certificate if we are not able to find existing one
        $CertSubject = 'CN=PSCatalog Code Signing'
        $null = Create-CodeSigningCert
        $cert = (Get-Childitem cert:\LocalMachine -recurse | Where-Object -FilterScript {$_.Subject -eq $CertSubject})[0]
        if(-not $cert)
        {
            Throw "'$CertSubject' code signing certificate is not created properly."
        }
        '1.0.1.1','1.0.1.2','1.0.1.11' | ForEach-Object {SignAndPublish-TestModule -Name $TestArchiveModule -Version $_ -Certificate $cert}

        $PSGetSubject = 'PowerShellGet Catalog Code Signing'
        $null = Create-CodeSigningCert -Subject $PSGetSubject -CertRA "PowerShellGet Test Root Authority"
        $PSGetCert = (Get-Childitem cert:\LocalMachine -recurse | Where-Object -FilterScript {$_.Subject -eq "CN=$PSGetSubject"})[0]
        if(-not $PSGetCert)
        {
            Throw "'$PSGetSubject' code signing certificate is not created properly."
        }

        SignAndPublish-TestModule -Name $TestArchiveModule -Version '1.0.1.5' -Certificate $PSGetCert
        SignAndPublish-TestModule -Name $MicrosoftPowerShellArchive -Version '1.0.1.5' -Certificate $Cert
    }
}

Describe 'Test PowerShellGet cmdlets support for catalog signed modules with a system module' -tags 'P1','OuterLoop' {

    if(([System.Environment]::OSVersion.Version -le '6.1.7601.65536') -or ($PSVersionTable.PSVersion -lt '5.1.0')) { return }

    BeforeAll {
        if(([System.Environment]::OSVersion.Version -le '6.1.7601.65536') -or ($PSVersionTable.PSVersion -lt '5.1.0')) { return }

        SuiteSetup

        # Install a module to the system modules path to mock it as a system module
        $null = Install-Package -ProviderName NuGet `
                                -Source $SourceLocation `
                                -Name $TestArchiveModule `
                                -RequiredVersion 1.0.1.1 `
                                -Destination $SystemModulesPath `
                                -ExcludeVersion
    }

    AfterAll {
        Get-InstalledModule -Name $TestArchiveModule -AllVersions -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
        Remove-Item -Path "$SystemModulesPath\$TestArchiveModule" -Recurse -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }

    BeforeEach {
        Get-InstalledModule -Name $TestArchiveModule -AllVersions -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
    }

    It 'Installing a valid catalog signed module with a previous version under System32 path: Should work' {
        Install-Module -Name $TestArchiveModule -RequiredVersion 1.0.1.11 -Repository $Script:RepositoryName -Force
        Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.11 -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        Get-Module -ListAvailable -FullyQualifiedName @{ModuleName=$TestArchiveModule;RequiredVersion='1.0.1.1'} | Should Not BeNullOrEmpty
    }

    It 'Catalog authenticode signature is missing in the version: Should fail' {
        Install-Module -Name $TestArchiveModule -RequiredVersion 1.0.1.4 -Repository $Script:RepositoryName -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'ModuleIsNotCatalogSigned,Validate-ModuleAuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'
        Get-InstalledModule -Name $TestArchiveModule -ErrorAction SilentlyContinue | Should BeNullOrEmpty
    }

    It 'catalog authenticode signature is invalid: Should fail' {
        Install-Module -Name $TestArchiveModule -RequiredVersion 1.0.1.3 -Repository $Script:RepositoryName -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'InvalidAuthenticodeSignature,ValidateAndGet-AuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'
        Get-InstalledModule -Name $TestArchiveModule -ErrorAction SilentlyContinue | Should BeNullOrEmpty
    }

    It 'catalog file is invalid: Should fail' {
        Install-Module -Name $TestArchiveModule -RequiredVersion 1.0.1.2 -Repository $Script:RepositoryName -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'InvalidCatalogSignature,ValidateAndGet-AuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'
        Get-InstalledModule -Name $TestArchiveModule  -ErrorAction SilentlyContinue | Should BeNullOrEmpty
    }    
}

Describe 'Test PowerShellGet cmdlets support for catalog signed modules' -tags 'P1','OuterLoop' {

    if(([System.Environment]::OSVersion.Version -le '6.1.7601.65536') -or ($PSVersionTable.PSVersion -lt '5.1.0')) { return }

    BeforeAll {        
        if(([System.Environment]::OSVersion.Version -le '6.1.7601.65536') -or ($PSVersionTable.PSVersion -lt '5.1.0')) { return }

        SuiteSetup
    }

    AfterAll {
        Get-InstalledModule -Name $TestArchiveModule -AllVersions -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
        Get-InstalledModule -Name $ContosoServer -AllVersions -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
    }

    BeforeEach {
        Get-InstalledModule -Name $TestArchiveModule -AllVersions -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
        Get-InstalledModule -Name $ContosoServer -AllVersions -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
        Get-InstalledModule -Name $SmallContosoServer -AllVersions -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
    }
    
    It 'Authenticode publisher is different from the previously installed module version: Should fail' {        
        Install-Module -Name $TestArchiveModule -RequiredVersion 1.0.1.1 -Repository $Script:RepositoryName
        Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.1 | Should Not BeNullOrEmpty

        Install-Module -Name $TestArchiveModule -RequiredVersion 1.0.1.5 -Repository $Script:RepositoryName -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'AuthenticodeIssuerMismatch,Validate-ModuleAuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'
    }

    It 'Installing a valid catalog signed module with a previous version under different modules path: Should work' {        
        Install-Module -Name $TestArchiveModule -RequiredVersion 1.0.1.1 -Repository $Script:RepositoryName -Scope CurrentUser
        Install-Module -Name $TestArchiveModule -RequiredVersion 1.0.1.11 -Repository $Script:RepositoryName -Force
        Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.11 | Should Not BeNullOrEmpty
        Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.1 | Should Not BeNullOrEmpty
    }

    It 'Without AllowClobber --- installing an unsigned module with a previous version under different modules path: Should work' {        
        Install-Module -Name $ContosoServer -RequiredVersion 1.0 -Repository $Script:RepositoryName -Scope CurrentUser
        Install-Module -Name $ContosoServer -RequiredVersion 2.5 -Repository $Script:RepositoryName -Force        
        Get-InstalledModule -Name $ContosoServer -RequiredVersion 2.5 | Should Not BeNullOrEmpty
        Get-InstalledModule -Name $ContosoServer -RequiredVersion 1.0 | Should Not BeNullOrEmpty
    }

    It 'Without Force and AllowClobber --- installing an unsigned module with a previous version under different modules path: Should work' {
        Install-Module -Name $ContosoServer -RequiredVersion 1.0 -Repository $Script:RepositoryName -Scope CurrentUser
        Install-Module -Name $ContosoServer -RequiredVersion 2.5 -Repository $Script:RepositoryName
        Get-InstalledModule -Name $ContosoServer -RequiredVersion 2.5 | Should Not BeNullOrEmpty
        Get-InstalledModule -Name $ContosoServer -RequiredVersion 1.0 | Should Not BeNullOrEmpty
    }

    It 'Without AllowClobber --- installing an unsigned module with different module with same command: Should fail' {        
        Install-Module -Name $SmallContosoServer -RequiredVersion 1.0 -Repository $Script:RepositoryName
        Get-InstalledModule -Name $SmallContosoServer -RequiredVersion 1.0 | Should Not BeNullOrEmpty

        Install-Module -Name $ContosoServer -RequiredVersion 2.5 -Repository $Script:RepositoryName -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'CommandAlreadyAvailable,Validate-ModuleCommandAlreadyAvailable,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'
        Get-InstalledModule -Name $SmallContosoServer -RequiredVersion 1.0 | Should Not BeNullOrEmpty
    }

    It 'With AllowClobber --- installing an unsigned module with different module with same command: Should work' {        
        Install-Module -Name $SmallContosoServer -RequiredVersion 1.0 -Repository $Script:RepositoryName
        Install-Module -Name $ContosoServer -RequiredVersion 2.5 -Repository $Script:RepositoryName -AllowClobber

        Get-InstalledModule -Name $ContosoServer -RequiredVersion 2.5 | Should Not BeNullOrEmpty
        Get-InstalledModule -Name $SmallContosoServer -RequiredVersion 1.0 | Should Not BeNullOrEmpty
    }

    It 'Install-Module with SkipPublisherCheck --- catalog file is invalid: Should work' {
        Install-Module -Name $TestArchiveModule -RequiredVersion 1.0.1.2 -Repository $Script:RepositoryName -SkipPublisherCheck
        Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.2 -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
    }

    It 'Install-Module with SkipPublisherCheck --- Catalog authenticode signature is missing in the version: Should work' {
        Install-Module -Name $TestArchiveModule -RequiredVersion 1.0.1.4 -Repository $Script:RepositoryName -SkipPublisherCheck
        Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.4 -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
    }

    It 'Install-Module with SkipPublisherCheck --- catalog authenticode signature is invalid: Should work' {
        Install-Module -Name $TestArchiveModule -RequiredVersion 1.0.1.3 -Repository $Script:RepositoryName -SkipPublisherCheck
        Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.3 -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
    }
}

Describe 'Test PowerShellGet\Update-Module cmdlet with catalog signed modules' -tags 'P1','OuterLoop' {

    if(([System.Environment]::OSVersion.Version -le '6.1.7601.65536') -or ($PSVersionTable.PSVersion -lt '5.1.0')) { return }

    BeforeAll {        
        if(([System.Environment]::OSVersion.Version -le '6.1.7601.65536') -or ($PSVersionTable.PSVersion -lt '5.1.0')){ return }

        SuiteSetup

        Install-Module -Name $TestArchiveModule -RequiredVersion 1.0.1.1 -Repository $Script:RepositoryName
    }

    AfterAll {
        Get-InstalledModule -Name $TestArchiveModule -AllVersions -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
    }

    BeforeEach {
        Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.3 -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
        Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.4 -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
        Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.2 -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
        Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.11 -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
    }

    It 'Update a catalog signed module: Should work' {
        Update-Module -Name $TestArchiveModule
        Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.11 | Should Not BeNullOrEmpty
        Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.1 | Should Not BeNullOrEmpty
    }

    It 'Update a catalog signed module without specifying a name: Should work' {
        Update-Module
        Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.11 | Should Not BeNullOrEmpty
        Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.1 | Should Not BeNullOrEmpty
    }

    It 'Update-Module -- Catalog authenticode signature is missing in the version: Should fail' {
        Update-Module -Name $TestArchiveModule -RequiredVersion 1.0.1.4 -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'ModuleIsNotCatalogSigned,Validate-ModuleAuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'
    }

    It 'Update-Module -- catalog authenticode signature is invalid: Should fail' {
        Update-Module -Name $TestArchiveModule -RequiredVersion 1.0.1.3 -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'InvalidAuthenticodeSignature,ValidateAndGet-AuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'
    }

    It 'Update-Module -- catalog file is invalid: Should fail' {
        Update-Module -Name $TestArchiveModule -RequiredVersion 1.0.1.2 -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'InvalidCatalogSignature,ValidateAndGet-AuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'
    }
}

Describe 'Install-Module --- Microsoft signed versions of Microsoft.PowerShell.Archive module' -tags 'BVT','InnerLoop' {

    BeforeAll {        
        # Microsoft.PowerShell.Archive module is an inbox module with PowerShell 5.0 or newer versions
        SuiteSetup
    }

    BeforeEach {
        if($PSVersionTable.PSVersion -lt '5.0.0') {
            # Install a module to the system modules path to mock it as a system module
            Install-Package -ProviderName NuGet `
                            -Source $Script:INTRepoLocation `
                            -Name $MicrosoftPowerShellArchive `
                            -RequiredVersion 1.0.1.0 `
                            -Destination $SystemModulesPath `
                            -ExcludeVersion
        }
    }

    AfterAll {
        Get-InstalledModule -Name $MicrosoftPowerShellArchive -AllVersions -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
        
        if($PSVersionTable.PSVersion -lt '5.0.0') {
            Remove-Item -Path "$SystemModulesPath\$MicrosoftPowerShellArchive" -Recurse -Force
        }
    }

    BeforeEach {
        Get-InstalledModule -Name $MicrosoftPowerShellArchive -AllVersions -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
    }

    It 'Install-Module Microsoft.PowerShell.Archive -- valid catalog signed module version with a previous version under System32 path: Should work' {
        Install-Module -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.1 -Repository $Script:INTRepositoryName -Force
        Get-InstalledModule -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.1 -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
    }

    It 'Install-Module Microsoft.PowerShell.Archive -- Authenticode publisher is different from the previously installed module version: Should fail' {        
        
        if(([System.Environment]::OSVersion.Version -le '6.1.7601.65536') -or ($PSVersionTable.PSVersion -lt '5.1.0') ) { return }

        Install-Module -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.1 -Repository $Script:INTRepositoryName
        Get-InstalledModule -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.1 | Should Not BeNullOrEmpty

        Install-Module -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.5 -Repository $Script:RepositoryName -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'PublishersMismatch,Validate-ModuleAuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'
    }

    It 'Install-Module Microsoft.PowerShell.Archive -- Catalog authenticode signature is missing in the version: Should fail' {

        if(([System.Environment]::OSVersion.Version -le '6.1.7601.65536') -or ($PSVersionTable.PSVersion -lt '5.0.0') ) { return }

        Install-Module -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.4 -Repository $Script:INTRepositoryName -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'ModuleIsNotCatalogSigned,Validate-ModuleAuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'
        Get-InstalledModule -Name $MicrosoftPowerShellArchive -ErrorAction SilentlyContinue | Should BeNullOrEmpty
    }

    It 'Install-Module Microsoft.PowerShell.Archive -- catalog authenticode signature is invalid: Should fail' {
        
        if(([System.Environment]::OSVersion.Version -le '6.1.7601.65536') -or ($PSVersionTable.PSVersion -lt '5.0.0') ) { return }

        Install-Module -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.3 -Repository $Script:INTRepositoryName -ErrorVariable ev -ErrorAction SilentlyContinue -Force
        $ev[0].FullyQualifiedErrorId | Should be 'InvalidAuthenticodeSignature,ValidateAndGet-AuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'
        Get-InstalledModule -Name $MicrosoftPowerShellArchive -ErrorAction SilentlyContinue | Should BeNullOrEmpty
    }

    It 'Install-Module Microsoft.PowerShell.Archive -- catalog file is invalid: Should fail' {
        Install-Module -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.2 -Repository $Script:INTRepositoryName -ErrorVariable ev -ErrorAction SilentlyContinue -Force

        if($PSVersionTable.PSVersion -lt '5.1.0') {
            Get-InstalledModule -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.2 -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
        } else {
            $ev[0].FullyQualifiedErrorId | Should be 'InvalidCatalogSignature,ValidateAndGet-AuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'
            Get-InstalledModule -Name $MicrosoftPowerShellArchive  -ErrorAction SilentlyContinue | Should BeNullOrEmpty
        }
    }

    It 'Install-Module Microsoft.PowerShell.Archive -SkipPublisherCheck -- Catalog authenticode signature is missing in the version: Should work' {
        Install-Module -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.4 -Repository $Script:INTRepositoryName -SkipPublisherCheck -Force
        Get-InstalledModule -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.4 | Should Not BeNullOrEmpty
    }

    It 'Install-Module Microsoft.PowerShell.Archive -SkipPublisherCheck -- catalog authenticode signature is invalid: Should work' {
        Install-Module -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.3 -Repository $Script:INTRepositoryName -SkipPublisherCheck -Force
        Get-InstalledModule -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.3 | Should Not BeNullOrEmpty
    }

    It 'Install-Module Microsoft.PowerShell.Archive -SkipPublisherCheck -- catalog file is invalid: Should work' {
        Install-Module -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.2 -Repository $Script:INTRepositoryName -SkipPublisherCheck -Force
        Get-InstalledModule -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.2 | Should Not BeNullOrEmpty
    }   
}

Describe 'Update-Module --- Microsoft signed versions of Microsoft.PowerShell.Archive module' -tags 'BVT','InnerLoop' {

    BeforeAll {        
        SuiteSetup

        Install-Module -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.1 -Repository $Script:INTRepositoryName
        
        if([System.Environment]::OSVersion.Version -gt '6.1.7601.65536') {
            Install-Module -Name $TestArchiveModule -RequiredVersion 1.0.1.1 -Repository $Script:RepositoryName
        }
    }

    AfterAll {
        Get-InstalledModule -Name $MicrosoftPowerShellArchive -AllVersions -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
        Get-InstalledModule -Name $TestArchiveModule -AllVersions -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
    }

    BeforeEach {
        if($PSVersionTable.PSVersion -lt '5.0.0') {
            Install-Module -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.1 -Repository $Script:INTRepositoryName -Force
        }

        Get-InstalledModule -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.3 -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
        Get-InstalledModule -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.4 -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
        Get-InstalledModule -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.2 -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
        Get-InstalledModule -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.11 -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
        Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.11 -ErrorAction SilentlyContinue | PowerShellGet\Uninstall-Module
    }

    It 'Update-Module Microsoft.PowerShell.Archive -- Update a catalog signed module: Should work' {
        Update-Module -Name $MicrosoftPowerShellArchive
        Get-InstalledModule -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.11 | Should Not BeNullOrEmpty
        
        if($PSVersionTable.PSVersion -ge '5.0.0') {
            Get-InstalledModule -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.1 | Should Not BeNullOrEmpty
        }
    }

    It 'Update-Module Microsoft.PowerShell.Archive -- Update a catalog signed module without specifying a name: Should work' {
        Update-Module
        Get-InstalledModule -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.11 | Should Not BeNullOrEmpty
        
        if($PSVersionTable.PSVersion -ge '5.0.0') {
            Get-InstalledModule -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.1 | Should Not BeNullOrEmpty
        }

        if([System.Environment]::OSVersion.Version -gt '6.1.7601.65536') {
            Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.11 | Should Not BeNullOrEmpty

            if($PSVersionTable.PSVersion -ge '5.0.0') {
                Get-InstalledModule -Name $TestArchiveModule -RequiredVersion 1.0.1.1 | Should Not BeNullOrEmpty
            }
        }
    }

    It 'Update-Module Microsoft.PowerShell.Archive -- Catalog authenticode signature is missing in the version: Should fail' {
        if(([System.Environment]::OSVersion.Version -le '6.1.7601.65536') -or ($PSVersionTable.PSVersion -lt '5.0.0') ) { return }
        Update-Module -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.4 -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'ModuleIsNotCatalogSigned,Validate-ModuleAuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'
    }

    It 'Update-Module Microsoft.PowerShell.Archive -- catalog authenticode signature is invalid: Should fail' {
        if(([System.Environment]::OSVersion.Version -le '6.1.7601.65536') -or ($PSVersionTable.PSVersion -lt '5.0.0') ) { return }
        Update-Module -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.3 -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'InvalidAuthenticodeSignature,ValidateAndGet-AuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'
    }

    It 'Update-Module Microsoft.PowerShell.Archive -- catalog file is invalid: Should fail' {
        Update-Module -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.2 -ErrorVariable ev -ErrorAction SilentlyContinue
        
        if($PSVersionTable.PSVersion -ge '5.1.0') {
            $ev[0].FullyQualifiedErrorId | Should be 'InvalidCatalogSignature,ValidateAndGet-AuthenticodeSignature,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'
        } else {
            Get-InstalledModule -Name $MicrosoftPowerShellArchive -RequiredVersion 1.0.1.2 | Should Not BeNullOrEmpty
        }
    }
}

if($Script:RegisteredLocalRepo)
{
    Get-PSRepository -Name $Script:RepositoryName -ErrorAction SilentlyContinue | Unregister-PSRepository
}

if($Script:RegisteredINTRepo)
{
    Get-PSRepository -Name $Script:INTRepositoryName -ErrorAction SilentlyContinue | Unregister-PSRepository
}
