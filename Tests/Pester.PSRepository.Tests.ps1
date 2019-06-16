# This is a Pester test suite to validate Get-PSRepository, Set-PSRepository, Register-PSRepository and UnRegister-PSRepository
#
# Copyright (c) Microsoft Corporation, 2016

Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue

$RepositoryName = 'PSGallery'
$SourceLocation = 'https://www.poshtestgallery.com/api/v2'
$SourceLocation2 = 'https://www.poshtestgallery.com/api/v2/'
$PublishLocation = 'https://www.poshtestgallery.com/api/v2/package'
$ScriptSourceLocation = 'https://www.poshtestgallery.com/api/v2/items/psscript'
$ScriptPublishLocation = 'https://www.poshtestgallery.com/api/v2/package'
$TestRepositoryName = 'PSTestGallery'

Describe 'Test Register-PSRepository and Register-PackageSource for PSGallery repository' -tags 'BVT', 'InnerLoop' {

    BeforeAll {
        Install-NuGetBinaries
        Get-PSRepository |
        Where-Object -Property SourceLocation -eq $SourceLocation2 |
        Unregister-PSRepository

        $nugetCmd = Microsoft.PowerShell.Core\Get-Command -Name 'NuGet.exe' `
            -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }

    AfterAll {
        if (Get-PSRepository -Name $RepositoryName -ErrorAction SilentlyContinue) {
            Set-PSRepository -Name $RepositoryName -InstallationPolicy Trusted
        }
        else {
            Register-PSRepository -Default -InstallationPolicy Trusted
        }
    }

    BeforeEach {
        Unregister-PSRepository -Name $RepositoryName -ErrorAction SilentlyContinue
    }

    It 'Should add and remove nuget source when -PackageMangementProvider is set to Nuget' {
        Register-PSRepository -Name $TestRepositoryName -SourceLocation $SourceLocation -PackageManagementProvider Nuget
        $nugetSourceExists = nuget sources list | where-object { $_.Trim() -in $SourceLocation }
        $nugetSourceExists | should be $true

        unregister-PSRepository -Name $TestRepositoryName
        $nugetSourceExists = nuget sources list | where-object { $_.Trim() -in $SourceLocation }
        $nugetSourceExists | should be $null
    } -Skip:$(!$nugetCmd)

    It 'Should pipe from Get-PSRepository to Set' {
        Register-PSRepository -Default

        Get-PSRepository $RepositoryName | Set-PSRepository -InstallationPolicy Trusted

        $repo = Get-PSRepository $RepositoryName
        $repo.Name | should be $RepositoryName
        $repo.Trusted | should be $true
    }

    It 'Register-PSRepository -Default: Should work' {
        Register-PSRepository -Default
        $repo = Get-PSRepository $RepositoryName
        $repo.Name | should be $RepositoryName
        $repo.Trusted | should be $false
    }

    It 'Register-PSRepository -Default-InstallationPolicy Untrusted : Should work' {
        Register-PSRepository -Default -InstallationPolicy Untrusted
        $repo = Get-PSRepository $RepositoryName
        $repo.Name | should be $RepositoryName
        $repo.Trusted | should be $false
    }

    It 'Register-PSRepository -Default -InstallationPolicy Trusted : Should work' {
        Register-PSRepository -Default -InstallationPolicy Trusted
        $repo = Get-PSRepository $RepositoryName
        $repo.Name | should be $RepositoryName
        $repo.Trusted | should be $true
    }

    It 'Register-PSRepository File system location with special chars' {
        $tmpdir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'ps repo testing [$!@^&test(;)]'
        if (-not (Test-Path -LiteralPath $tmpdir)) {
            New-Item -Path $tmpdir -ItemType Directory > $null
        }
        try {
            Register-PSRepository -Name 'Test Repo' -SourceLocation $tmpdir
            try {
                $repo = Get-PSRepository -Name 'Test Repo'
                $repo.Name | should be 'Test Repo'
                $repo.SourceLocation | should be $tmpdir
            }
            finally {
                Unregister-PSRepository -Name 'Test Repo' -ErrorAction SilentlyContinue
            }
        }
        finally {
            Remove-Item -LiteralPath $tmpdir -Force -Recurse
        }
    }

    It 'Reregister PSGallery again: Should fail' {
        Register-PSRepository -Default
        Register-PSRepository -Default -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'PackageSourceExists,Microsoft.PowerShell.PackageManagement.Cmdlets.RegisterPackageSource'
    } `
        -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    It 'Register-PSRepository -Default:$false : Should not register' {
        Register-PSRepository -Default:$false
        Get-PSRepository PSGallery -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'SourceNotFound,Microsoft.PowerShell.PackageManagement.Cmdlets.GetPackageSource'
    } `
        -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    It 'Register-PSRepository -Name PSGallery -SourceLocation $SourceLocation : Should fail' {
        { Register-PSRepository $RepositoryName $SourceLocation -ErrorVariable ev -ErrorAction SilentlyContinue } | Should Throw
    }

    It 'Register-PSRepository -Name PSGallery -SourceLocation $SourceLocation -PublishLocation $PublishLocation : Should fail' {
        { Register-PSRepository $RepositoryName $SourceLocation -PublishLocation $PublishLocation -ErrorVariable ev  -ErrorAction SilentlyContinue } | Should Throw
    }

    It 'Register-PSRepository -Name PSGallery -SourceLocation $SourceLocation -ScriptPublishLocation $ScriptPublishLocation : Should fail' {
        { Register-PSRepository -Name $RepositoryName $SourceLocation -ScriptPublishLocation $ScriptPublishLocation -ErrorVariable ev  -ErrorAction SilentlyContinue } | Should Throw
    }

    It 'Register-PSRepository -Name PSGallery -SourceLocation $SourceLocation -ScriptSourceLocation $ScriptSourceLocation : Should fail' {
        { Register-PSRepository $RepositoryName -SourceLocation $SourceLocation -ScriptSourceLocation $ScriptSourceLocation -ErrorVariable ev  -ErrorAction SilentlyContinue } | Should Throw
    }

    It 'Register-PackageSource -ProviderName PowerShellGet -Name PSGallery : Should work, default installation policy should be untrusted' {
        Register-PackageSource -ProviderName PowerShellGet -Name $RepositoryName
        $source = Get-PackageSource -name $RepositoryName
        $source.Name | should be $RepositoryName
        $source.IsTrusted | should be $false
    }

    It 'Register-PackageSource -ProviderName PowerShellGet -Name PSGallery -Trusted : Should work' {
        Register-PackageSource -ProviderName PowerShellGet -Name $RepositoryName -Trusted
        $source = Get-PackageSource -name $RepositoryName
        $source.Name | should be $RepositoryName
        $source.IsTrusted | should be $true
    }

    It 'Register-PackageSource -ProviderName PowerShellGet -Name PSGallery -Location $SourceLocation : Should fail' {
        Register-PackageSource -ProviderName PowerShellGet -Name $RepositoryName -Location $SourceLocation -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'ParameterIsNotAllowedWithPSGallery,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.RegisterPackageSource'
    } `
        -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    It 'Register-PackageSource -ProviderName PowerShellGet -Name PSGallery -PublishLocation $PublishLocation : Should fail' {
        Register-PackageSource -ProviderName PowerShellGet -Name $RepositoryName -PublishLocation $PublishLocation -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'ParameterIsNotAllowedWithPSGallery,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.RegisterPackageSource'
    } `
        -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    It 'Register-PackageSource -ProviderName PowerShellGet -Name PSGallery -ScriptPublishLocation $ScriptPublishLocation : should fail' {
        Register-PackageSource -ProviderName PowerShellGet -Name $RepositoryName -ScriptPublishLocation $ScriptPublishLocation -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'ParameterIsNotAllowedWithPSGallery,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.RegisterPackageSource'
    } `
        -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    It 'Register-PackageSource -ProviderName PowerShellGet -Name PSGallery -ScriptSourceLocation $ScriptSourceLocation : should fail' {
        Register-PackageSource -ProviderName PowerShellGet -Name PSGallery -ScriptSourceLocation $ScriptSourceLocation -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'ParameterIsNotAllowedWithPSGallery,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.RegisterPackageSource'
    } `
        -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')
}

Describe 'Test Set-PSRepository and Set-PackageSource for PSGallery repository' -tags 'BVT', 'InnerLoop' {

    BeforeAll {
        Install-NuGetBinaries
    }

    AfterAll {
        if (Get-PSRepository -Name $RepositoryName -ErrorAction SilentlyContinue) {
            Set-PSRepository -Name $RepositoryName -InstallationPolicy Trusted
        }
        else {
            Register-PSRepository -Default -InstallationPolicy Trusted
        }
    }

    BeforeEach {
        if (Get-PSRepository -Name $RepositoryName -ErrorAction SilentlyContinue) {
            Set-PSRepository -Name $RepositoryName -InstallationPolicy Untrusted
        }
        else {
            Register-PSRepository -Default -InstallationPolicy Untrusted
        }
    }

    It 'Set-PSRepository -Name PSGallery -InstallationPolicy Trusted : should work' {
        Set-PSRepository $RepositoryName -InstallationPolicy Trusted
        $repo = Get-PSRepository $RepositoryName
        $repo.Name | should be $RepositoryName
        $repo.Trusted | should be $true
    }

    It 'Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted : should work' {
        Set-PSRepository -Name $RepositoryName -InstallationPolicy Trusted
        Set-PSRepository -Name $RepositoryName -InstallationPolicy Untrusted
        $repo = Get-PSRepository $RepositoryName
        $repo.Name | should be $RepositoryName
        $repo.Trusted | should be $false
    }

    It 'Set-PSRepository -Name PSGallery -SourceLocation $SourceLocation : should fail' {
        Set-PSRepository $RepositoryName $SourceLocation -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'ParameterIsNotAllowedWithPSGallery,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.SetPackageSource'
    } `
        -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    It 'Set-PSRepository -Name PSGallery -PublishLocation $PublishLocation : should fail' {
        Set-PSRepository $RepositoryName -PublishLocation $PublishLocation -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'ParameterIsNotAllowedWithPSGallery,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.SetPackageSource'
    } `
        -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    It 'Set-PSRepository -Name PSGallery -ScriptPublishLocation $ScriptPublishLocation : should fail' {
        Set-PSRepository $RepositoryName -ScriptPublishLocation $ScriptPublishLocation -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'ParameterIsNotAllowedWithPSGallery,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.SetPackageSource'
    } `
        -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    It 'Set-PSRepository -Name PSGallery -ScriptSourceLocation $ScriptSourceLocation : should fail' {
        Set-PSRepository -Name $RepositoryName -ScriptSourceLocation $ScriptSourceLocation -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'ParameterIsNotAllowedWithPSGallery,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.SetPackageSource'
    } `
        -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    It 'Set-PackageSource -ProviderName PowerShellGet -Name PSGallery : should work actually this is a no-op. Installation policy should not be changed' {
        Set-PackageSource -ProviderName PowerShellGet -Name $RepositoryName
        $source = Get-PackageSource -name $RepositoryName
        $source.Name | should be $RepositoryName
        $source.IsTrusted | should be $false
    }

    It 'Set-PackageSource -ProviderName PowerShellGet -Name PSGallery -Trusted : should work' {
        Set-PackageSource -ProviderName PowerShellGet -Name $RepositoryName -Trusted
        $source = Get-PackageSource -name $RepositoryName
        $source.Name | should be $RepositoryName
        $source.IsTrusted | should be $true
    }

    It 'Set-PackageSource -ProviderName PowerShellGet -Name PSGallery -SourceLocation $SourceLocation : should fail' {
        Set-PackageSource -ProviderName PowerShellGet -Name $RepositoryName -NewLocation $SourceLocation -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'ParameterIsNotAllowedWithPSGallery,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.SetPackageSource'
    } `
        -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    It 'Set-PackageSource -ProviderName PowerShellGet -Name PSGallery -PublishLocation $PublishLocation : should fail' {
        Set-PackageSource -ProviderName PowerShellGet -Name $RepositoryName -PublishLocation $PublishLocation -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'ParameterIsNotAllowedWithPSGallery,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.SetPackageSource'
    } `
        -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    It 'Set-PackageSource -ProviderName PowerShellGet -Name PSGallery -ScriptPublishLocation $ScriptPublishLocation : should fail' {
        Set-PackageSource -ProviderName PowerShellGet -Name $RepositoryName -ScriptPublishLocation $ScriptPublishLocation -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'ParameterIsNotAllowedWithPSGallery,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.SetPackageSource'
    } `
        -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    It 'Set-PackageSource -ProviderName PowerShellGet -Name PSGallery -ScriptSourceLocation $ScriptSourceLocation : should fail' {
        Set-PackageSource -ProviderName PowerShellGet -Name $RepositoryName -ScriptSourceLocation $ScriptSourceLocation -ErrorVariable ev -ErrorAction SilentlyContinue
        $ev[0].FullyQualifiedErrorId | Should be 'ParameterIsNotAllowedWithPSGallery,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.SetPackageSource'
    } `
        -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')
}

Describe 'Test Register-PSRepository for PSTestGallery repository' -tags 'BVT', 'InnerLoop' {

    BeforeAll {
        Install-NuGetBinaries
        Get-PSRepository |
        Where-Object -Property SourceLocation -eq $SourceLocation |
        Unregister-PSRepository
    }

    BeforeEach {
        Unregister-PSRepository -Name $TestRepositoryName -ErrorAction SilentlyContinue
    }

    BeforeAll {
        Unregister-PSRepository -Name $TestRepositoryName -ErrorAction SilentlyContinue
    }

    It 'Register-PSRepository -Name $TestRepositoryName -SourceLocation $SourceLocation -ScriptSourceLocation $SourceLocation -PublishLocation $SourceLocation -ScriptPublishLocation $SourceLocation : Should work' {
        $paramRegisterPSRepository = @{
            Name                  = $TestRepositoryName
            SourceLocation        = $SourceLocation
            PublishLocation       = $PublishLocation
            ScriptSourceLocation  = $ScriptSourceLocation
            ScriptPublishLocation = $ScriptPublishLocation
        }

        { Register-PSRepository @paramRegisterPSRepository } | Should not Throw
        $repo = Get-PSRepository -Name $TestRepositoryName
        $repo.SourceLocation | Should be $SourceLocation
        $repo.ScriptSourceLocation | Should be $ScriptSourceLocation
        $repo.PublishLocation | Should be $PublishLocation
        $repo.ScriptPublishLocation | Should be $ScriptPublishLocation
    }
}

Describe 'Test Set-PSRepository for PSTestGallery repository' -tags 'BVT', 'InnerLoop' {

    BeforeAll {
        Install-NuGetBinaries
        Get-PSRepository |
        Where-Object -Property SourceLocation -eq $SourceLocation |
        Unregister-PSRepository
    }

    BeforeEach {
        Unregister-PSRepository -Name $TestRepositoryName -ErrorAction SilentlyContinue
    }

    BeforeAll {
        Unregister-PSRepository -Name $TestRepositoryName -ErrorAction SilentlyContinue
    }

    It 'Set-PSRepository -Name $TestRepositoryName -SourceLocation $SourceLocation -ScriptSourceLocation $SourceLocation -PublishLocation $SourceLocation -ScriptPublishLocation $SourceLocation : Should work' {
        $paramRegisterPSRepository = @{
            Name                  = $TestRepositoryName
            SourceLocation        = $SourceLocation
            PublishLocation       = $PublishLocation
            ScriptSourceLocation  = $ScriptSourceLocation
            ScriptPublishLocation = $ScriptPublishLocation
        }

        Register-PSRepository @paramRegisterPSRepository -ErrorAction SilentlyContinue

        $paramSetPSRepository = @{
            Name                  = $TestRepositoryName
            SourceLocation        = $SourceLocation
            PublishLocation       = $PublishLocation
            ScriptSourceLocation  = $ScriptSourceLocation
            ScriptPublishLocation = $ScriptPublishLocation
        }

        { Set-PSRepository @paramSetPSRepository } | Should not Throw

        $repo = Get-PSRepository -Name $TestRepositoryName
        $repo.SourceLocation | Should be $SourceLocation
        $repo.ScriptSourceLocation | Should be $ScriptSourceLocation
        $repo.PublishLocation | Should be $PublishLocation
        $repo.ScriptPublishLocation | Should be $ScriptPublishLocation
    }
}
