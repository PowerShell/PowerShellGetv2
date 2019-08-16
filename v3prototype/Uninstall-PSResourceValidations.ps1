############################
### Uninstall-PSResource ###
############################

### Uninstalling Modules ###
# Should uninstall the module 'TestModule'
Uninstall-PSResource 'TestModule'

# Should uninstall the module 'TestModule'
Uninstall-PSResource -name 'TestModule'

# Should uninstall the modules 'TestModule1', 'TestModule2', 'TestModule3'
Uninstall-PSResource 'TestModule1', 'TestModule2', 'TestModule3'

# Should uninstall the latest, non-prerelease version of the module 'TestModule' that is at least 1.5.0
Uninstall-PSResource 'TestModule' -MinimumVersion '1.5.0'

# Should uninstall the latest, non-prerelease version of the module 'TestModule' that is at most 1.5.0
Uninstall-PSResource 'TestModule' -MaximumVersion '1.5.0'

# Should uninstall the latest, non-prerelease version of the module 'TestModule' that is at least version 1.0.0 and at most 2.0.0
Uninstall-PSResource 'TestModule' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'

# Should uninstall version 1.5.0 (non-prerelease) of the module 'TestModule'
Uninstall-PSResource 'TestModule' -RequiredVersion '1.5.0'

# Should uninstall all non-prerelease versions of the module 'TestModule'
Uninstall-PSResource 'TestModule' -AllVersions '1.5.0'

# Should uninstall the latest verison of 'TestModule', including prerelease versions
Uninstall-PSResource 'TestModule' -Prerelease

# Should uninstall the module 'TestModule' without asking for user confirmation
Uninstall-PSResource 'TestModule' -Force



### Uninstalling Scripts ###
# Should uninstall the module 'TestScript'
Uninstall-PSResource 'TestScript'

# Should uninstall the module 'TestScript'
Uninstall-PSResource -name 'TestScript'

# Should uninstall the modules 'TestScript1', 'TestScript2', 'TestScript3'
Uninstall-PSResource 'TestScript1', 'TestScript2', 'TestScript3'

# Should uninstall the latest, non-prerelease version of the module 'TestScript' that is at least 1.5.0
Uninstall-PSResource 'TestScript' -MinimumVersion '1.5.0'

# Should uninstall the latest, non-prerelease version of the module 'TestScript' that is at most 1.5.0
Uninstall-PSResource 'TestScript' -MaximumVersion '1.5.0'

# Should uninstall the latest, non-prerelease version of the module 'TestScript' that is at least version 1.0.0 and at most 2.0.0
Uninstall-PSResource 'TestScript' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'

# Should uninstall version 1.5.0 (non-prerelease) of the module 'TestScript'
Uninstall-PSResource 'TestScript' -RequiredVersion '1.5.0'

# Should uninstall all non-prerelease versions of the module 'TestScript'
Uninstall-PSResource 'TestScript' -AllVersions '1.5.0'

# Should uninstall the latest verison of 'TestScript', including prerelease versions
Uninstall-PSResource 'TestScript' -Prerelease

# Should uninstall the module 'TestScript' without asking for user confirmation
Uninstall-PSResource 'TestScript' -Force
