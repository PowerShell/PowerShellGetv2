#region HEADER
# This must be same name as the root folder, and module manifest.
$script:DSCModuleName = 'DSC'
$script:DSCResourceName = 'MSFT_PSRepository'

# Unit Test Template Version: 1.2.4
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) ) {
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -ResourceType 'Mof' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try {
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockRepositoryName = 'PSTestGallery'
        $mockSourceLocation = 'https://www.poshtestgallery.com/api/v2/'
        $mockPublishLocation = 'https://www.poshtestgallery.com/api/v2/package/'
        $mockScriptSourceLocation = 'https://www.poshtestgallery.com/api/v2/items/psscript/'
        $mockScriptPublishLocation = 'https://www.poshtestgallery.com/api/v2/package/'
        $mockPackageManagementProvider = 'NuGet'
        $mockInstallationPolicy_Trusted = 'Trusted'
        $mockInstallationPolicy_NotTrusted = 'Untrusted'

        $mockRepository = New-Object -TypeName Object |
            Add-Member -Name 'Name' -MemberType NoteProperty -Value $mockRepositoryName -PassThru |
            Add-Member -Name 'SourceLocation' -MemberType NoteProperty -Value $mockSourceLocation -PassThru |
            Add-Member -Name 'ScriptSourceLocation' -MemberType NoteProperty -Value $mockScriptSourceLocation  -PassThru |
            Add-Member -Name 'PublishLocation' -MemberType NoteProperty -Value $mockPublishLocation -PassThru |
            Add-Member -Name 'ScriptPublishLocation' -MemberType NoteProperty -Value $mockScriptPublishLocation -PassThru |
            Add-Member -Name 'InstallationPolicy' -MemberType NoteProperty -Value $mockInstallationPolicy_Trusted -PassThru |
            Add-Member -Name 'PackageManagementProvider' -MemberType NoteProperty -Value $mockPackageManagementProvider -PassThru |
            Add-Member -Name 'Trusted' -MemberType NoteProperty -Value $true -PassThru |
            Add-Member -Name 'Registered' -MemberType NoteProperty -Value $true -PassThru -Force

        $mockGetPSRepository = {
            return @($mockRepository)
        }

        Describe 'MSFT_PSRepository\Get-TargetResource' -Tag 'Get' {
            Context 'When the system is in the desired state' {
                Context 'When the configuration is present' {
                    BeforeAll {
                        Mock -CommandName Get-PSRepository -MockWith $mockGetPSRepository
                    }

                    It 'Should return the same values as passed as parameters' {
                        $getTargetResourceResult = Get-TargetResource -Name $mockRepositoryName
                        $getTargetResourceResult.Name | Should -Be $mockRepositoryName

                        Assert-MockCalled -CommandName Get-PSRepository -Exactly -Times 1 -Scope It
                    }

                    It 'Should return the correct values for the other properties' {
                        $getTargetResourceResult = Get-TargetResource -Name $mockRepositoryName

                        $getTargetResourceResult.Ensure | Should -Be 'Present'
                        $getTargetResourceResult.SourceLocation | Should -Be $mockRepository.SourceLocation
                        $getTargetResourceResult.ScriptSourceLocation | Should -Be $mockRepository.ScriptSourceLocation
                        $getTargetResourceResult.PublishLocation | Should -Be $mockRepository.PublishLocation
                        $getTargetResourceResult.ScriptPublishLocation | Should -Be $mockRepository.ScriptPublishLocation
                        $getTargetResourceResult.InstallationPolicy | Should -Be $mockRepository.InstallationPolicy
                        $getTargetResourceResult.PackageManagementProvider | Should -Be $mockRepository.PackageManagementProvider
                        $getTargetResourceResult.Trusted | Should -Be $true
                        $getTargetResourceResult.Registered | Should -Be $true

                        Assert-MockCalled -CommandName Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration is absent' {
                    BeforeAll {
                        Mock -CommandName Get-PSRepository
                    }

                    It 'Should return the same values as passed as parameters' {
                        $getTargetResourceResult = Get-TargetResource -Name $mockRepositoryName
                        $getTargetResourceResult.Name | Should -Be $mockRepositoryName

                        Assert-MockCalled -CommandName Get-PSRepository -Exactly -Times 1 -Scope It
                    }

                    It 'Should return the correct values for the other properties' {
                        $getTargetResourceResult = Get-TargetResource -Name $mockRepositoryName

                        $getTargetResourceResult.Ensure | Should -Be 'Absent'
                        $getTargetResourceResult.SourceLocation | Should -BeNullOrEmpty
                        $getTargetResourceResult.ScriptSourceLocation | Should -BeNullOrEmpty
                        $getTargetResourceResult.PublishLocation | Should -BeNullOrEmpty
                        $getTargetResourceResult.ScriptPublishLocation | Should -BeNullOrEmpty
                        $getTargetResourceResult.InstallationPolicy | Should -BeNullOrEmpty
                        $getTargetResourceResult.PackageManagementProvider | Should -BeNullOrEmpty
                        $getTargetResourceResult.Trusted | Should -Be $false
                        $getTargetResourceResult.Registered | Should -Be $false

                        Assert-MockCalled -CommandName Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Describe 'MSFT_PSRepository\Set-TargetResource' -Tag 'Set' {
            Context 'When the system is not in the desired state' {
                BeforeAll {
                    Mock -CommandName Register-PSRepository
                    Mock -CommandName Unregister-PSRepository
                    Mock -CommandName Set-PSRepository
                }

                Context 'When the configuration should be present' {
                    Context 'When the repository does not exist' {
                        BeforeEach {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure                    = 'Absent'
                                    Name                      = $mockRepositoryName
                                    SourceLocation            = $null
                                    ScriptSourceLocation      = $null
                                    PublishLocation           = $null
                                    ScriptPublishLocation     = $null
                                    InstallationPolicy        = $null
                                    PackageManagementProvider = $null
                                    Trusted                   = $false
                                    Registered                = $false
                                }
                            }
                        }

                        It 'Should return call the correct mocks' {
                            $setTargetResourceParameters = @{
                                Name                      = $mockRepository.Name
                                SourceLocation            = $mockRepository.SourceLocation
                                ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                                PublishLocation           = $mockRepository.PublishLocation
                                ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                                InstallationPolicy        = $mockRepository.InstallationPolicy
                                PackageManagementProvider = $mockRepository.PackageManagementProvider
                            }

                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Register-PSRepository -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Unregister-PSRepository -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Set-PSRepository -Exactly -Times 0 -Scope It
                        }
                    }

                    Context 'When the repository do exist but with wrong properties' {
                        BeforeEach {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure                    = 'Present'
                                    Name                      = $mockRepository.Name
                                    SourceLocation            = 'https://www.powershellgallery.com/api/v2/'
                                    ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                                    PublishLocation           = $mockRepository.PublishLocation
                                    ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                                    InstallationPolicy        = $mockRepository.InstallationPolicy
                                    PackageManagementProvider = $mockRepository.PackageManagementProvider
                                    Trusted                   = $mockRepository.Trusted
                                    Registered                = $mockRepository.Registered
                                }
                            }
                        }

                        It 'Should return call the correct mocks' {
                            $setTargetResourceParameters = @{
                                Name                      = $mockRepository.Name
                                SourceLocation            = $mockRepository.SourceLocation
                                ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                                PublishLocation           = $mockRepository.PublishLocation
                                ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                                InstallationPolicy        = $mockRepository.InstallationPolicy
                                PackageManagementProvider = $mockRepository.PackageManagementProvider
                            }

                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Register-PSRepository -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Unregister-PSRepository -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Set-PSRepository -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context 'When the configuration should be absent' {
                    Context 'When the repository do exist' {
                        BeforeEach {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure                    = 'Present'
                                    Name                      = $mockRepository.Name
                                    SourceLocation            = $mockRepository.SourceLocation
                                    ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                                    PublishLocation           = $mockRepository.PublishLocation
                                    ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                                    InstallationPolicy        = $mockRepository.InstallationPolicy
                                    PackageManagementProvider = $mockRepository.PackageManagementProvider
                                    Trusted                   = $mockRepository.Trusted
                                    Registered                = $mockRepository.Registered
                                }
                            }
                        }

                        It 'Should return call the correct mocks' {
                            $setTargetResourceParameters = @{
                                Ensure = 'Absent'
                                Name   = $mockRepositoryName
                            }

                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Register-PSRepository -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Unregister-PSRepository -Exactly -Times 1 -Scope It
                            Assert-MockCalled -CommandName Set-PSRepository -Exactly -Times 0 -Scope It
                        }
                    }
                }
            }
        }

        Describe 'MSFT_PSRepository\Test-TargetResource' -Tag 'Test' {
            Context 'When the system is in the desired state' {
                Context 'When the configuration is present' {
                    BeforeEach {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure                    = 'Present'
                                Name                      = $mockRepository.Name
                                SourceLocation            = $mockRepository.SourceLocation
                                ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                                PublishLocation           = $mockRepository.PublishLocation
                                ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                                InstallationPolicy        = $mockRepository.InstallationPolicy
                                PackageManagementProvider = $mockRepository.PackageManagementProvider
                                Trusted                   = $mockRepository.Trusted
                                Registered                = $mockRepository.Registered
                            }
                        }
                    }

                    It 'Should return the state as $true' {
                        $testTargetResourceResult = Test-TargetResource -Name $mockRepositoryName
                        $testTargetResourceResult | Should -Be $true

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration is absent' {
                    BeforeEach {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure                    = 'Absent'
                                Name                      = $mockRepositoryName
                                SourceLocation            = $null
                                ScriptSourceLocation      = $null
                                PublishLocation           = $null
                                ScriptPublishLocation     = $null
                                InstallationPolicy        = $null
                                PackageManagementProvider = $null
                                Trusted                   = $false
                                Registered                = $false
                            }
                        }
                    }

                    It 'Should return the state as $true' {
                        $testTargetResourceResult = Test-TargetResource -Ensure 'Absent' -Name $mockRepositoryName
                        $testTargetResourceResult | Should -Be $true

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the configuration should be present' {
                    BeforeEach {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure                    = 'Absent'
                                Name                      = $mockRepositoryName
                                SourceLocation            = $null
                                ScriptSourceLocation      = $null
                                PublishLocation           = $null
                                ScriptPublishLocation     = $null
                                InstallationPolicy        = $null
                                PackageManagementProvider = $null
                                Trusted                   = $false
                                Registered                = $false
                            }
                        }
                    }

                    It 'Should return the state as $false' {
                        $testTargetResourceParameters = @{
                            Name                      = $mockRepository.Name
                            SourceLocation            = $mockRepository.SourceLocation
                            ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                            PublishLocation           = $mockRepository.PublishLocation
                            ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                            InstallationPolicy        = $mockRepository.InstallationPolicy
                            PackageManagementProvider = $mockRepository.PackageManagementProvider
                        }

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When a property is not in desired state' {
                    BeforeEach {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure                    = 'Present'
                                Name                      = $mockRepository.Name
                                SourceLocation            = $mockRepository.SourceLocation
                                ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                                PublishLocation           = $mockRepository.PublishLocation
                                ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                                InstallationPolicy        = $mockRepository.InstallationPolicy
                                PackageManagementProvider = $mockRepository.PackageManagementProvider
                                Trusted                   = $mockRepository.Trusted
                                Registered                = $mockRepository.Registered
                            }
                        }
                    }

                    $defaultTestCase = @{
                        SourceLocation            = $mockRepository.SourceLocation
                        ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                        PublishLocation           = $mockRepository.PublishLocation
                        ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                        InstallationPolicy        = $mockRepository.InstallationPolicy
                        PackageManagementProvider = $mockRepository.PackageManagementProvider
                    }

                    $testCaseSourceLocationIsMissing = $defaultTestCase.Clone()
                    $testCaseSourceLocationIsMissing['TestName'] = 'SourceLocation is missing'
                    $testCaseSourceLocationIsMissing['SourceLocation'] = 'https://www.powershellgallery.com/api/v2/'

                    $testCaseScriptSourceLocationIsMissing = $defaultTestCase.Clone()
                    $testCaseScriptSourceLocationIsMissing['TestName'] = 'ScriptSourceLocation is missing'
                    $testCaseScriptSourceLocationIsMissing['ScriptSourceLocation'] = 'https://www.powershellgallery.com/api/v2/items/psscript/'

                    $testCasePublishLocationIsMissing = $defaultTestCase.Clone()
                    $testCasePublishLocationIsMissing['TestName'] = 'PublishLocation is missing'
                    $testCasePublishLocationIsMissing['PublishLocation'] = 'https://www.powershellgallery.com/api/v2/package/'

                    $testCaseScriptPublishLocationIsMissing = $defaultTestCase.Clone()
                    $testCaseScriptPublishLocationIsMissing['TestName'] = 'ScriptPublishLocation is missing'
                    $testCaseScriptPublishLocationIsMissing['ScriptPublishLocation'] = 'https://www.powershellgallery.com/api/v2/package/'

                    $testCaseInstallationPolicyIsMissing = $defaultTestCase.Clone()
                    $testCaseInstallationPolicyIsMissing['TestName'] = 'InstallationPolicy is missing'
                    $testCaseInstallationPolicyIsMissing['InstallationPolicy'] = $mockInstallationPolicy_NotTrusted

                    $testCasePackageManagementProviderIsMissing = $defaultTestCase.Clone()
                    $testCasePackageManagementProviderIsMissing['TestName'] = 'PackageManagementProvider is missing'
                    $testCasePackageManagementProviderIsMissing['PackageManagementProvider'] = 'PSGallery'

                    $testCases = @(
                        $testCaseSourceLocationIsMissing
                        $testCaseScriptSourceLocationIsMissing
                        $testCasePublishLocationIsMissing
                        $testCaseScriptPublishLocationIsMissing
                        $testCaseInstallationPolicyIsMissing
                        $testCasePackageManagementProviderIsMissing
                    )

                    It 'Should return the state as $false when the correct <TestName>' -TestCases $testCases {
                        param
                        (
                            $SourceLocation,
                            $ScriptSourceLocation,
                            $PublishLocation,
                            $ScriptPublishLocation,
                            $InstallationPolicy,
                            $PackageManagementProvider
                        )

                        $testTargetResourceParameters = @{
                            Name                      = $mockRepositoryName
                            SourceLocation            = $SourceLocation
                            ScriptSourceLocation      = $ScriptSourceLocation
                            PublishLocation           = $PublishLocation
                            ScriptPublishLocation     = $ScriptPublishLocation
                            InstallationPolicy        = $InstallationPolicy
                            PackageManagementProvider = $PackageManagementProvider
                        }

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -Be $false

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration should be absent' {
                    BeforeEach {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure                    = 'Present'
                                Name                      = $mockRepositoryName
                                SourceLocation            = $mockRepository.SourceLocation
                                ScriptSourceLocation      = $mockRepository.ScriptSourceLocation
                                PublishLocation           = $mockRepository.PublishLocation
                                ScriptPublishLocation     = $mockRepository.ScriptPublishLocation
                                InstallationPolicy        = $mockRepository.InstallationPolicy
                                PackageManagementProvider = $mockRepository.PackageManagementProvider
                                Trusted                   = $mockRepository.Trusted
                                Registered                = $mockRepository.Registered
                            }
                        }
                    }

                    It 'Should return the state as $false' {
                        $testTargetResourceResult = Test-TargetResource -Ensure 'Absent' -Name $mockRepositoryName
                        $testTargetResourceResult | Should -Be $false

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    }
                }
            }
        }
    }
}
finally {
    Invoke-TestCleanup
}
