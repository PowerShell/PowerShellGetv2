#region HEADER
# Integration Test Config Template Version: 1.2.0
#endregion

$configFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, 'json')
if (Test-Path -Path $configFile)
{
    <#
        Allows reading the configuration data from a JSON file
        for real testing scenarios outside of the CI.
    #>
    $ConfigurationData = Get-Content -Path $configFile | ConvertFrom-Json
}
else
{
    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName                  = 'localhost'
                CertificateFile           = $env:DscPublicCertificatePath

                Name                      = 'PSTestGallery'

                TestSourceLocation        = 'https://www.poshtestgallery.com/api/v2/'
                TestPublishLocation       = 'https://www.poshtestgallery.com/api/v2/package/'
                TestScriptSourceLocation  = 'https://www.poshtestgallery.com/api/v2/items/psscript/'
                TestScriptPublishLocation = 'https://www.poshtestgallery.com/api/v2/package/'

                # Using these URI's to get a stable and accessible site, not to test a real scenario.
                SourceLocation            = 'https://www.nuget.org/api/v2'
                PublishLocation           = 'https://www.nuget.org/api/v2/package'
                ScriptSourceLocation      = 'https://www.nuget.org/api/v2/items/psscript/'
                ScriptPublishLocation     = 'https://www.nuget.org/api/v2/package'

                <#
                    Currently there are no default package management providers
                    that supports the feature 'supports-powershell-modules', so
                    it is not possible to test switching to another provider.
                    Note: PowerShellGet provider is not
                #>
                PackageManagementProvider = 'NuGet'

                TestModuleName            = 'ContosoServer'
            }
        )
    }
}

<#
    .SYNOPSIS
        Adds a repository.
#>
Configuration MSFT_PSRepository_AddRepository_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSRepository 'Integration_Test'
        {
            Name                  = $Node.Name
            SourceLocation        = $Node.TestSourceLocation
            PublishLocation       = $Node.TestPublishLocation
            ScriptSourceLocation  = $Node.TestScriptSourceLocation
            ScriptPublishLocation = $Node.TestScriptPublishLocation
            InstallationPolicy    = 'Trusted'
        }
    }
}

<#
    .SYNOPSIS
        Installs a module with default parameters from the new repository.
#>
Configuration MSFT_PSRepository_InstallTestModule_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Name       = $Node.TestModuleName
            Repository = $Node.Name
        }
    }
}

<#
    .SYNOPSIS
        Changes the properties of the repository.
#>
Configuration MSFT_PSRepository_ChangeRepository_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSRepository 'Integration_Test'
        {
            Name                      = $Node.Name
            SourceLocation            = $Node.SourceLocation
            PublishLocation           = $Node.PublishLocation
            ScriptSourceLocation      = $Node.ScriptSourceLocation
            ScriptPublishLocation     = $Node.ScriptPublishLocation
            PackageManagementProvider = $Node.PackageManagementProvider
            InstallationPolicy        = 'Untrusted'
        }
    }
}

<#
    .SYNOPSIS
        Removes the repository.
#>
Configuration MSFT_PSRepository_RemoveRepository_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSRepository 'Integration_Test'
        {
            Ensure = 'Absent'
            Name   = $Node.Name
        }
    }
}
