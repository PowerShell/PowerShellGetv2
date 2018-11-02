# This is a Pester test suite to validate Get-PSRepository, Set-PSRepository, Register-PSRepository and UnRegister-PSRepository
#
# Copyright (c) Microsoft Corporation, 2016

Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue

$RepositoryName = 'PSGallery'
$SourceLocation = 'https://www.poshtestgallery.com/api/v2/'
$PublishLocation= 'https://www.poshtestgallery.com/api/v2/package/'
$ScriptSourceLocation= 'https://www.poshtestgallery.com/api/v2/items/psscript/'
$ScriptPublishLocation= 'https://www.poshtestgallery.com/api/v2/package/'

Describe 'Test Register-PSRepository and Register-PackageSource for PSGallery repository' -tags 'BVT','InnerLoop' {

    BeforeAll {        
	    Install-NuGetBinaries
    }

    AfterAll {
        if(Get-PSRepository -Name $RepositoryName -ErrorAction SilentlyContinue)
        {
            Set-PSRepository -Name $RepositoryName -InstallationPolicy Trusted
        }
        else
        {
            Register-PSRepository -Default -InstallationPolicy Trusted
        }
    }

    BeforeEach {
        Unregister-PSRepository -Name $RepositoryName -ErrorAction SilentlyContinue
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
        { Register-PSRepository $RepositoryName $SourceLocation -PublishLocation $PublishLocation -ErrorVariable ev  -ErrorAction SilentlyContinue  } | Should Throw
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

Describe 'Test Set-PSRepository and Set-PackageSource for PSGallery repository' -tags 'BVT','InnerLoop' {

    BeforeAll {        
	    Install-NuGetBinaries
    }

    AfterAll {
        if(Get-PSRepository -Name $RepositoryName -ErrorAction SilentlyContinue)
        {
            Set-PSRepository -Name $RepositoryName -InstallationPolicy Trusted
        }
        else
        {
            Register-PSRepository -Default -InstallationPolicy Trusted
        }
    }

    BeforeEach {
        if(Get-PSRepository -Name $RepositoryName -ErrorAction SilentlyContinue)
        {
            Set-PSRepository -Name $RepositoryName -InstallationPolicy Untrusted
        }
        else
        {
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

Describe 'Managing repositories' -Tag BVT {
    BeforeAll {        
	    Install-NuGetBinaries
    }

    AfterAll {    
            
    }

    BeforeEach {
        Unregister-PSRepository NewRepo -ErrorAction SilentlyContinue
        Unregister-PSRepository NewRepoSlash -ErrorAction SilentlyContinue
    }

    AfterEach {
        Unregister-PSRepository NewRepo -ErrorAction SilentlyContinue
        Unregister-PSRepository NewRepoSlash -ErrorAction SilentlyContinue
    }

    It "Should let you register an unreachable repository but produce a warning" {
        # microsoft.com exists but doesn't host a nuget repo
        Register-PSRepository -Name NewRepo -SourceLocation "https://microsoft.com/api/v2" -WarningVariable warning -WarningAction SilentlyContinue
	    if($psversiontable.PSVersion -ge '5.0.0') { # -warningvariable doesn't seem to work in ps4?
            $warning -join "" | Should BeLike "*Unable to reach URL*"
        }
    }
    
    It "Should let you change a repo to an unreachable location but produce a warning" {
        Register-PSRepository -Name NewRepo -SourceLocation "https://www.microsoft.com/api/v2"-WarningAction SilentlyContinue
        Set-PSRepository -Name NewRepo -SourceLocation "https://docs.microsoft.com/api/v2" -WarningVariable warning -WarningAction SilentlyContinue
        if($psversiontable.PSVersion -ge '5.0.0') { # -warningvariable doesn't seem to work in ps4?
            $warning -join "" | Should BeLike "*Unable to reach URL 'https://docs*"
        }
    }

    It "Should let you add a package source but produce a warning" {
        Register-PackageSource NewRepo -Location https://microsoft.com/api/v2 -ProviderName powershellget -WarningVariable warning -WarningAction SilentlyContinue
        $warning -join "" | Should BeLike "*Unable to reach URL*"
    }

    It "Should let you update a package source but produce a warning" {
        Register-PackageSource NewRepo -Location https://microsoft.com/api/v2 -ProviderName powershellget -WarningAction SilentlyContinue
        Set-PackageSource -Name NewRepo -Location https://microsoft.com/api/v2 -NewLocation https://docs.microsoft.com/api/v2 -ProviderName powershellget  -WarningVariable warning -WarningAction SilentlyContinue
        $warning -join "" | Should BeLike "*Unable to reach URL 'https://docs*"
    }

    It "Should not let you register 2 repositories which differ only by /" {
        Register-PSRepository -Name NewRepo -SourceLocation "https://nowhere.com/api/v2" -WarningAction SilentlyContinue
        { Register-PSRepository -Name NewRepoSlash -SourceLocation "https://nowhere.com/api/v2/" -WarningAction SilentlyContinue } | Should -Throw
    } -Skip
}

Describe "Managing galleries while offline" -Tag BVT {
    BeforeAll {
        if(-not (Get-PSRepository PSGallery -ErrorAction SilentlyContinue)) {
            Register-PSRepository -Default
        }
    }

    AfterAll {
        if(-not (Get-PSRepository PSGallery -ErrorAction SilentlyContinue)) {
            Register-PSRepository -Default
        }
    }

    Context "Mock network failures" {
        # Pinging any endpoint results in no response. However this only affects the front-end of powershellget,
        # not code running in the package provider, so it is not truly blocking all network access.
        Mock Ping-EndPoint -ModuleName powershellget {}

        It "Should let you unregister and reregister PSGallery" {
            Unregister-PSRepository PSGallery -WarningVariable unregisterWarning -WarningAction SilentlyContinue
            $unregisterWarning | Should Be $null

            Register-PSRepository -Default -WarningAction SilentlyContinue
            $defaultRepo = Get-PSRepository -Name PSGallery
            $DefaultRepo.SourceLocation | Should Be "https://www.powershellgallery.com/api/v2"
        }

        It "Should let you trust the gallery even when it is unavailable" {
            Set-PSRepository PSGallery -InstallationPolicy Trusted
        }
    }
}