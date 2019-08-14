##########################
### Update-PSResource ###
##########################

### Updating Modules ###

# Should update the module 'TestModule'
Update-PSResource 'TestModule'

# Should update the module 'TestModule'
Update-PSResource -name 'TestModule'

# Should update the modules 'TestModule1', 'TestModule2', 'TestModule3'
Update-PSResource 'TestModule1', 'TestModule2', 'TestModule3'

# Should update to the latest, non-prerelease version of the module 'TestModule' that is at most 1.5.0
Update-PSResource 'TestModule' -MaximumVersion '1.5.0'

# Should update to version 1.5.0 (non-prerelease) of the module 'TestModule'
Update-PSResource 'TestModule' -RequiredVersion '1.5.0'

# Should update to the latest patch version verison of 'TestModule'
Update-PSResource 'TestModule' -UpdateTo 'PatchVersion'

# Should update to the latest version verison of 'TestModule'
Update-PSResource 'TestModule' -UpdateTo 'MinorVersion'

# Should update to the latest major verison of 'TestModule'
Update-PSResource 'TestModule' -UpdateTo 'MinorVersion'

# Should update to the latest verison of 'TestModule', including prerelease versions
Update-PSResource 'TestModule' -Prerelease

# Should update the module 'TestModule' to the CurrentUser scope
Update-PSResource 'TestModule' -Scope 'CurrentUser'

# Should update the module 'TestModule' to the AllUsers scope
Update-PSResource 'TestModule' -Scope 'AllUsers'

# Should update the module 'TestModule' without asking for user confirmation.
Update-PSResource 'TestModule' -Force

#Should update the module 'TestModule' and automatically accept license agreement
Update-PSResource 'TestModule' -AcceptLicense

#Should update the module 'TestModule' and return the module as an object to the console
Update-PSResource 'TestModule' -PassThru



### Updating Scripts ###

# Should install the script 'TestScript'
Install-PSResource 'TestScript'

# Should update the script 'TestScript'
Update-PSResource 'TestScript'

# Should update the script 'TestScript'
Update-PSResource -name 'TestScript'

# Should update the scripts 'TestScript1', 'TestScript2', 'TestScript3'
Update-PSResource 'TestScript1', 'TestScript2', 'TestScript3'

# Should update to the latest, non-prerelease version of the script 'TestScript' that is at most 1.5.0
Update-PSResource 'TestScript' -MaximumVersion '1.5.0'

# Should update to version 1.5.0 (non-prerelease) of the script 'TestScript'
Update-PSResource 'TestScript' -RequiredVersion '1.5.0'

# Should update to the latest patch version verison of 'TestScript'
Update-PSResource 'TestScript' -UpdateTo 'PatchVersion'

# Should update to the latest version verison of 'TestScript'
Update-PSResource 'TestScript' -UpdateTo 'MinorVersion'

# Should update to the latest major verison of 'TestScript'
Update-PSResource 'TestScript' -UpdateTo 'MinorVersion'

# Should update to the latest verison of 'TestScript', including prerelease versions
Update-PSResource 'TestScript' -Prerelease

# Should update the script 'TestScript' to the CurrentUser scope
Update-PSResource 'TestScript' -Scope 'CurrentUser'

# Should update the script 'TestScript' to the AllUsers scope
Update-PSResource 'TestScript' -Scope 'AllUsers'

# Should update the script 'TestScript' without asking for user confirmation.
Update-PSResource 'TestScript' -Force

#Should update the script 'TestScript' and automatically accept license agreement
Update-PSResource 'TestScript' -AcceptLicense
