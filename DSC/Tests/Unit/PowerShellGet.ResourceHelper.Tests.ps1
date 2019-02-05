<#
    .SYNOPSIS
        Automated unit test for helper functions in module PowerShellGet.ResourceHelper.
#>


$script:helperModuleName = 'PowerShellGet.ResourceHelper'

Describe "$script:helperModuleName Unit Tests" {
    BeforeAll {
        $resourceModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        $dscResourcesFolderFilePath = Join-Path -Path (Join-Path -Path $resourceModuleRoot -ChildPath 'Modules') `
            -ChildPath $script:helperModuleName

        Import-Module -Name (Join-Path -Path $dscResourcesFolderFilePath `
                -ChildPath "$script:helperModuleName.psm1") -Force
    }

    InModuleScope $script:helperModuleName {
        Describe 'ExtractArguments' {
            Context 'When specific parameters should be returned' {
                It 'Should return a hashtable with the correct values' {
                    $mockPSBoundParameters = @{
                        Property1 = '1'
                        Property2 = '2'
                        Property3 = '3'
                        Property4 = '4'
                    }

                    $extractArgumentsResult = ExtractArguments `
                        -FunctionBoundParameters $mockPSBoundParameters `
                        -ArgumentNames @('Property2', 'Property3')

                    $extractArgumentsResult | Should -BeOfType [System.Collections.Hashtable]
                    $extractArgumentsResult.Count | Should -Be 2
                    $extractArgumentsResult.ContainsKey('Property2') | Should -BeTrue
                    $extractArgumentsResult.ContainsKey('Property3') | Should -BeTrue
                    $extractArgumentsResult.Property2 | Should -Be '2'
                    $extractArgumentsResult.Property3 | Should -Be '3'
                }
            }

            Context 'When the specific parameters to be returned does not exist' {
                It 'Should return an empty hashtable' {
                    $mockPSBoundParameters = @{
                        Property1 = '1'
                    }

                    $extractArgumentsResult = ExtractArguments `
                        -FunctionBoundParameters $mockPSBoundParameters `
                        -ArgumentNames @('Property2', 'Property3')

                    $extractArgumentsResult | Should -BeOfType [System.Collections.Hashtable]
                    $extractArgumentsResult.Count | Should -Be 0
                }
            }

            Context 'When and empty hashtable is passed in the parameter FunctionBoundParameters' {
                It 'Should return an empty hashtable' {
                    $mockPSBoundParameters = @{
                    }

                    $extractArgumentsResult = ExtractArguments `
                        -FunctionBoundParameters $mockPSBoundParameters `
                        -ArgumentNames @('Property2', 'Property3')

                    $extractArgumentsResult | Should -BeOfType [System.Collections.Hashtable]
                    $extractArgumentsResult.Count | Should -Be 0
                }
            }
        }

        Describe 'ThrowError' {
            It 'Should throw the correct error' {
                {
                    $mockedErrorMessage = 'mocked error'
                    $mockErrorId = 'MockedError'
                    $mockExceptionName = 'InvalidOperationException'

                    ThrowError `
                        -ExceptionName $mockExceptionName `
                        -ExceptionMessage $mockedErrorMessage `
                        -ErrorId $mockErrorId `
                        -ErrorCategory 'InvalidOperation'
                } | Should -Throw $mockedErrorMessage
            }
        }

        Describe 'ValidateArgument' {
            BeforeAll {
                $mockProviderName = 'PowerShellGet'
            }

            Context 'When passing a correct uri as ''Argument'' and type is ''SourceUri''' {
                It 'Should not throw an error' {
                    {
                        ValidateArgument `
                            -Argument 'https://mocked.uri' `
                            -Type 'SourceUri' `
                            -ProviderName $mockProviderName
                    } | Should -Not -Throw
                }
            }

            Context 'When passing an invalid uri as ''Argument'' and type is ''SourceUri''' {
                It 'Should throw the correct error' {
                    $mockArgument = 'mocked.uri'

                    {
                        ValidateArgument `
                            -Argument $mockArgument `
                            -Type 'SourceUri' `
                            -ProviderName $mockProviderName
                    } | Should -Throw ($LocalizedData.InValidUri -f $mockArgument)
                }
            }

            Context 'When passing a correct path as ''Argument'' and type is ''DestinationPath''' {
                It 'Should not throw an error' {
                    {
                        ValidateArgument `
                            -Argument 'TestDrive:\' `
                            -Type 'DestinationPath' `
                            -ProviderName $mockProviderName
                    } | Should -Not -Throw
                }
            }

            Context 'When passing an invalid path as ''Argument'' and type is ''DestinationPath''' {
                It 'Should throw the correct error' {
                    $mockArgument = 'TestDrive:\NonExistentPath'

                    {
                        ValidateArgument `
                            -Argument $mockArgument `
                            -Type 'DestinationPath' `
                            -ProviderName $mockProviderName
                    } | Should -Throw ($LocalizedData.PathDoesNotExist -f $mockArgument)
                }
            }

            Context 'When passing a correct uri as ''Argument'' and type is ''PackageSource''' {
                It 'Should not throw an error' {
                    {
                        ValidateArgument `
                            -Argument 'https://mocked.uri' `
                            -Type 'PackageSource' `
                            -ProviderName $mockProviderName
                    } | Should -Not -Throw
                }
            }

            Context 'When passing an correct package source as ''Argument'' and type is ''PackageSource''' {
                BeforeAll {
                    $mockArgument = 'PSGallery'

                    Mock -CommandName Get-PackageSource -MockWith {
                        return New-Object -TypeName Object |
                            Add-Member -Name 'Name' -MemberType NoteProperty -Value $mockArgument -PassThru |
                            Add-Member -Name 'ProviderName' -MemberType NoteProperty -Value $mockProviderName -PassThru -Force
                    }
                }

                It 'Should not throw an error' {
                    {
                        ValidateArgument `
                            -Argument $mockArgument `
                            -Type 'PackageSource' `
                            -ProviderName $mockProviderName
                    } | Should -Not -Throw

                    Assert-MockCalled -CommandName Get-PackageSource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When passing type is ''PackageSource'' and passing a package source that does not exist' {
                BeforeAll {
                    $mockArgument = 'PSGallery'

                    Mock -CommandName Get-PackageSource
                }

                It 'Should not throw an error' {
                    {
                        ValidateArgument `
                            -Argument $mockArgument `
                            -Type 'PackageSource' `
                            -ProviderName $mockProviderName
                    } | Should -Not -Throw

                    Assert-MockCalled -CommandName Get-PackageSource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When passing invalid type in parameter ''Type''' {
                BeforeAll {
                    $mockType = 'UnknownType'
                }

                It 'Should throw the correct error' {
                    {
                        ValidateArgument `
                            -Argument 'AnyArgument' `
                            -Type $mockType `
                            -ProviderName $mockProviderName
                    } | Should -Throw ($LocalizedData.UnexpectedArgument -f $mockType)
                }
            }
        }

        Describe 'ValidateVersionArgument' {
            Context 'When not passing in any parameters (using default values)' {
                It 'Should return true' {
                    ValidateVersionArgument | Should -BeTrue
                }
            }

            Context 'When only ''RequiredVersion'' are passed' {
                It 'Should return true' {
                    ValidateVersionArgument -RequiredVersion '3.0.0.0' | Should -BeTrue
                }
            }

            Context 'When ''MinimumVersion'' has a lower version than ''MaximumVersion''' {
                It 'Should throw the correct error' {
                    {
                        ValidateVersionArgument `
                            -MinimumVersion '2.0.0.0' `
                            -MaximumVersion '1.0.0.0'
                    } | Should -Throw $LocalizedData.VersionError
                }
            }

            Context 'When ''MinimumVersion'' has a lower version than ''MaximumVersion''' {
                It 'Should throw the correct error' {
                    {
                        ValidateVersionArgument `
                            -MinimumVersion '2.0.0.0' `
                            -MaximumVersion '1.0.0.0'
                    } | Should -Throw $LocalizedData.VersionError
                }
            }

            Context 'When ''RequiredVersion'', ''MinimumVersion'', and ''MaximumVersion'' are passed' {
                It 'Should throw the correct error' {
                    {
                        ValidateVersionArgument `
                            -RequiredVersion '3.0.0.0' `
                            -MinimumVersion '2.0.0.0' `
                            -MaximumVersion '1.0.0.0'
                    } | Should -Throw $LocalizedData.VersionError
                }
            }
        }

        Describe 'Get-InstallationPolicy' {
            Context 'When the package source exist, and is trusted' {
                BeforeAll {
                    Mock -CommandName Get-PackageSource -MockWith {
                        return New-Object -TypeName Object |
                            Add-Member -Name 'IsTrusted' -MemberType NoteProperty -Value $true -PassThru -Force
                    }
                }

                It 'Should return true' {
                    Get-InstallationPolicy -RepositoryName 'PSGallery' | Should -BeTrue

                    Assert-MockCalled -CommandName Get-PackageSource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the package source exist, and is not trusted' {
                BeforeAll {
                    Mock -CommandName Get-PackageSource -MockWith {
                        return New-Object -TypeName Object |
                            Add-Member -Name 'IsTrusted' -MemberType NoteProperty -Value $false -PassThru -Force
                    }
                }

                It 'Should return false' {


                    Get-InstallationPolicy -RepositoryName 'PSGallery' | Should -BeFalse

                    Assert-MockCalled -CommandName Get-PackageSource -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the package source does not exist' {
                BeforeAll {
                    Mock -CommandName Get-PackageSource
                }

                It 'Should return $null' {
                    Get-InstallationPolicy -RepositoryName 'Unknown' | Should -BeNullOrEmpty

                    Assert-MockCalled -CommandName Get-PackageSource -Exactly -Times 1 -Scope It
                }
            }
        }
    }
}
