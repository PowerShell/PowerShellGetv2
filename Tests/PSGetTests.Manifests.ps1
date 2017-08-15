function Get-FindModuleWithSourcesTestManifest {
    ConvertFrom-Json -InputObject "{
        TestCaseManifest: {
            parameters: {
                Variations: [
                    {
                        Name: '',
                        Source: '',
                        PositiveCase: 'true',
                        FullyQualifiedErrorID: '',
                        ExpectedModuleCount:60
                    },
                    {
                        Name: '',
                        Source: 'PSGetTestModuleSource',
                        PositiveCase: 'true',
                        FullyQualifiedErrorID: '',
                        ExpectedModuleCount:3
                    },
                    {
                        Name: '',
                        Source: 'PSGallery',
                        PositiveCase: 'true',
                        FullyQualifiedErrorID: '',
                        ExpectedModuleCount:60
                    },
                    {
                        Name: '',
                        Source: 'http://localhost:8765/api/v2/',
                        PositiveCase: 'true',
                        FullyQualifiedErrorID: '',
                        ExpectedModuleCount:3
                    },
                    {
                        Name: '',
                        Source: ['PSGallery','PSGetTestModuleSource'],
                        PositiveCase: 'true',
                        FullyQualifiedErrorID: '',
                        ExpectedModuleCount:60
                    },
                    {
                        Name: '',
                        Source: ['http://localhost:8765/api/v2/','PSGallery'],
                        PositiveCase: 'true',
                        FullyQualifiedErrorID: '',
                        ExpectedModuleCount:60
                    },
                    {
                        Name: '',
                        Source: 'https://nonexistingmachine/psGallery/api/v2/',
                        PositiveCase: 'false',
                        FullyQualifiedErrorID: 'InvalidWebUri,Get-ValidModuleLocation',
                        ExpectedModuleCount:0
                    },
                    {
                        Name: '',
                        Source: ['https://nonexistingmachine/psGallery/api/v2/','PSGallery','PSGetTestModuleSource'],
                        PositiveCase: 'false',
                        FullyQualifiedErrorID: 'InvalidWebUri,Get-ValidModuleLocation',
                        ExpectedModuleCount:0
                    },


                    {
                        Name: 'Contoso',
                        Source: '',
                        PositiveCase: 'true',
                        FullyQualifiedErrorID: '',
                        ExpectedModuleCount: 1
                    },
                    {
                        Name: 'Contoso',
                        Source: 'PSGetTestModuleSource',
                        PositiveCase: 'true',
                        FullyQualifiedErrorID: '',
                        ExpectedModuleCount:1
                    },
                    {
                        Name: 'PSReadLine',
                        Source: 'PSGallery',
                        PositiveCase: 'true',
                        FullyQualifiedErrorID: '',
                        ExpectedModuleCount:1
                    },
                    {
                        Name: 'Contoso',
                        Source: 'http://localhost:8765/api/v2/',
                        PositiveCase: 'true',
                        FullyQualifiedErrorID: '',
                        ExpectedModuleCount:1
                    },
                    {
                        Name: 'Contoso',
                        Source: ['PSGallery','PSGetTestModuleSource'],
                        PositiveCase: 'true',
                        FullyQualifiedErrorID: '',
                        ExpectedModuleCount:1
                    },
                    {
                        Name: 'Contoso',
                        Source: ['http://localhost:8765/api/v2/','PSGallery'],
                        PositiveCase: 'true',
                        FullyQualifiedErrorID: '',
                        ExpectedModuleCount:1
                    },
                    {
                        Name: 'PSReadLine',
                        Source: 'https://nonexistingmachine/psGallery/api/v2/',
                        PositiveCase: 'false',
                        FullyQualifiedErrorID: 'InvalidWebUri,Get-ValidModuleLocation',
                        ExpectedModuleCount:0
                    },
                    {
                        Name: 'PSReadLine',
                        Source: ['https://nonexistingmachine/psGallery/api/v2/','PSGallery','PSGetTestModuleSource'],
                        PositiveCase: 'false',
                        FullyQualifiedErrorID: 'InvalidWebUri,Get-ValidModuleLocation',
                        ExpectedModuleCount:0
                    }
                ]
            }
       }
    }"
}

function Get-InstallModuleWithSourcesTestManifest {
    ConvertFrom-Json -InputObject "{
        TestCaseManifest: {
            parameters: {
                Variations: [
                    {
                        Name: 'ContosoServer',
                        Source: '',
                        PositiveCase: 'false',
                        FullyQualifiedErrorID: 'DisambiguateForInstall,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'
                    },
                    {
                        Name: 'ContosoServer',
                        Source: 'PSGetTestModuleSource',
                        PositiveCase: 'true',
                        FullyQualifiedErrorID: ''
                    },
                    {
                        Name: 'ContosoServer',
                        Source: 'http://localhost:8765/api/v2/',
                        PositiveCase: 'true',
                        FullyQualifiedErrorID: ''
                    },
                    {
                        Name: 'ContosoServer',
                        Source: ['PSGallery','PSGetTestModuleSource'],
                        PositiveCase: 'true',
                        FullyQualifiedErrorID: ''
                    },
                    {
                        Name: 'ContosoServer',
                        Source: ['http://localhost:8765/api/v2/','PSGallery'],
                        PositiveCase: 'true',
                        FullyQualifiedErrorID: ''
                    },
                    {
                        Name: 'PSReadLine',
                        Source: 'https://nonexistingmachine/psGallery/api/v2/',
                        PositiveCase: 'false',
                        FullyQualifiedErrorID: 'InvalidWebUri,Get-ValidModuleLocation'
                    },
                    {
                        Name: 'PSReadLine',
                        Source: ['https://nonexistingmachine/psGallery/api/v2/','PSGallery','PSGetTestModuleSource'],
                        PositiveCase: 'false',
                        FullyQualifiedErrorID: 'InvalidWebUri,Get-ValidModuleLocation'
                    }
                ]
            }
       }
    }"
}
