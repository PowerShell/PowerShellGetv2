##########################
### Install-PSResource ###
##########################

### Installing Modules ###

# Should install the module 'TestModule'
Install-PSResource 'TestModule'

# Should install the module 'TestModule'
Install-PSResource -name 'TestModule'

# Should install the modules 'TestModule1', 'TestModule2', 'TestModule3'
Install-PSResource 'TestModule1', 'TestModule2', 'TestModule3'

# Should install the latest, non-prerelease version of the module 'TestModule' that is at least 1.5.0
Install-PSResource 'TestModule' -MinimumVersion '1.5.0'

# Should install the latest, non-prerelease version of the module 'TestModule' that is at most 1.5.0
Install-PSResource 'TestModule' -MaximumVersion '1.5.0'

# Should install the latest, non-prerelease version of the module 'TestModule' that is at least version 1.0.0 and at most 2.0.0
Install-PSResource 'TestModule' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'

# Should install version 1.5.0 (non-prerelease) of the module 'TestModule'
Install-PSResource 'TestModule' -RequiredVersion '1.5.0'

# Should install the latest verison of 'TestModule', including prerelease versions
Install-PSResource 'TestModule' -Prerelease

# Should install 'TestModule' from one of the specified repositories (based on repo priority)
Install-PSResource 'TestModule' -Repository 'Repository1', 'Repository2'

# Should install the module Pester
Install-PSResource -RequiredResources @{
    'Configuration' = '[1.3.1,2.0)'
    'Pester'        = @{
        version    = '[4.4.2,4.7.0]'
        repository = 'https://www.powershellgallery.com'
    }
}

# Should install the module Pester
Install-PSResource -RequiredResources ConvertTo-Json (
    @{
        'Configuration' = '[1.3.1,2.0)'
        'Pester'        = @{
            version    = '[4.4.2,4.7.0]'
            repository = 'https://www.powershellgallery.com'
        }
    }
)

# Should install the required resources in RequiredResource.psd1
Install-PSResource -RequiredResourcesFile 'RequiredResource.psd1'

# Should install the required resources in RequiredResource.json
Install-PSResource -RequiredResourcesFile 'RequiredResource.json'

# Should install the module 'TestModule' to the CurrentUser scope
Install-PSResource 'TestModule' -Scope 'CurrentUser'

# Should install the module 'TestModule' to the AllUsers scope
Install-PSResource 'TestModule' -Scope 'AllUsers'

# Should install the module 'TestModule' without prompting warning message regarding installation conflicts
Install-PSResource 'TestModule' -NoClobber

# Should install the module 'TestModule' without prompting message regarding publisher mismatch
Install-PSResource 'TestModule' -IgnoreDifferentPublisher

# Should install the module 'TestModule' without prompting message regarding untrusted sources
Install-PSResource 'TestModule' -TrustRepository

# Should install the module 'TestModule' without prompting message regarding untrusted sources
Install-PSResource 'TestModule' -Force

# Should reinstall the module 'TestModule'
Install-PSResource 'TestModule' -Reinstall

#Should install the module 'TestModule' without displaying progress information
Install-PSResource 'TestModule' -Quiet

#Should install the module 'TestModule' and automatically accept license agreement
Install-PSResource 'TestModule' -AcceptLicense

#Should install the module 'TestModule' and return the module as an object to the console
Install-PSResource 'TestModule' -PassThru



### Installing Scripts ###

# Should install the script 'TestScript'
Install-PSResource 'TestScript'

# Should install the script 'TestScript'
Install-PSResource -name 'TestScript'

# Should install the scripts 'TestScript1', 'TestScript2', 'TestScript3'
Install-PSResource 'TestScript1', 'TestScript2', 'TestScript3'

# Should install the latest, non-prerelease version of the script 'TestScript' that is at least 1.5.0
Install-PSResource 'TestScript' -MinimumVersion '1.5.0'

# Should install the latest, non-prerelease version of the script 'TestScript' that is at most 1.5.0
Install-PSResource 'TestScript' -MaximumVersion '1.5.0'

# Should install the latest, non-prerelease version of the script 'TestScript' that is at least version 1.0.0 and at most 2.0.0
Install-PSResource 'TestScript' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'

# Should install version 1.5.0 (non-prerelease) of the script 'TestScript'
Install-PSResource 'TestScript' -RequiredVersion '1.5.0'

# Should install the latest verison of 'TestScript', including prerelease versions
Install-PSResource 'TestScript' -Prerelease

# Should install 'TestScript' from one of the specified repositories (based on repo priority)
Install-PSResource 'TestScript' -Repository 'Repository1', 'Repository2'

# Should install the script TestScript
Install-PSResource -RequiredResources @{
    'Configuration' = '[1.3.1,2.0)'
    'TestScript'    = @{
        version    = '[4.4.2,4.7.0]'
        repository = 'https://www.powershellgallery.com'
    }
}

# Should install the script TestScript
Install-PSResource -RequiredResources ConvertTo-Json (
    @{
        'Configuration' = '[1.3.1,2.0)'
        'TestScript'    = @{
            version    = '[4.4.2,4.7.0]'
            repository = 'https://www.powershellgallery.com'
        }
    }
)

# Should install the required resources in RequiredResource.psd1
Install-PSResource -RequiredResourcesFile 'RequiredResource.psd1'

# Should install the required resources in RequiredResource.json
Install-PSResource -RequiredResourcesFile 'RequiredResource.json'

# Should install the script 'TestScript' to the CurrentUser scope
Install-PSResource 'TestScript' -Scope 'CurrentUser'

# Should install the script 'TestScript' to the AllUsers scope
Install-PSResource 'TestScript' -Scope 'AllUsers'

# Should install the module 'TestModule' without prompting warning message regarding installation conflicts
Install-PSResource 'TestModule' -NoClobber

# Should install the script 'TestScript' without prompting message regarding publisher mismatch
Install-PSResource 'TestScript' -IgnoreDifferentPublisher

# Should install the script 'TestScript' without prompting message regarding untrusted sources
Install-PSResource 'TestScript' -TrustRepository

# Should install the script 'TestScript' without prompting message regarding untrusted sources
Install-PSResource 'TestScript' -Force

# Should reinstall the script 'TestScript'
Install-PSResource 'TestScript' -Reinstall

#Should install the script 'TestScript' without displaying progress information
Install-PSResource 'TestScript' -Quiet

#Should install the script 'TestScript' and automatically accept license agreement
Install-PSResource 'TestScript' -AcceptLicense

#Should install the script 'TestScript' and return the script as an object to the console
Install-PSResource 'TestScript' -PassThru
