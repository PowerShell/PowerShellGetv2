#######################
### Get-PSResource ###
#######################
### Getting Installed Modules ###
# Should get the module 'TestModule'
Get-PSResource 'TestModule'

# Should get the module 'TestModule'
Get-PSResource -name 'TestModule'

# Should get the module 'TestModule'
Get-PSResource 'TestModule' -Type 'Module'

# Should get the module 'TestModule'
Get-PSResource 'TestModule' -Type 'Module', 'Script', 'Library'

# Should get the modules 'TestModule1', 'TestModule2', 'TestModule3'
Get-PSResource 'TestModule1', 'TestModule2', 'TestModule3'

# Should get the latest, non-prerelease version of the module 'TestModule' that is at least 1.5.0
Get-PSResource 'TestModule' -MinimumVersion '1.5.0'

# Should get the latest, non-prerelease version of the module 'TestModule' that is at most 1.5.0
Get-PSResource 'TestModule' -MaximumVersion '1.5.0'

# Should get the latest, non-prerelease version of the module 'TestModule' that is at least version 1.0.0 and at most 2.0.0
Get-PSResource 'TestModule' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'

# Should get version 1.5.0 (non-prerelease) of the module 'TestModule'
Get-PSResource 'TestModule' -RequiredVersion '1.5.0'

# Should find all non-prerelease versions of the module 'TestModule'
Get-PSResource 'TestModule' -AllVersions

# Should get the latest verison of 'TestModule', including prerelease versions
Get-PSResource 'TestModule' -Prerelease



### Getting Installed Scripts ###
# Should get the script 'TestScript'
Get-PSResource 'TestScript'

# Should get the script 'TestScript'
Get-PSResource -name 'TestScript'

# Should get the module 'TestScript'
Get-PSResource 'TestScript' -Type 'Script'

# Should get the module 'TestScript'
Get-PSResource 'TestScript' -Type 'Module', 'Script', 'Library'

# Should get the scripts 'TestScript1', 'TestScript2', 'TestScript3'
Get-PSResource 'TestScript1', 'TestScript2', 'TestScript3'

# Should get the latest, non-prerelease version of the script 'TestScript' that is at least 1.5.0
Get-PSResource 'TestScript' -MinimumVersion '1.5.0'

# Should get the latest, non-prerelease version of the script 'TestScript' that is at most 1.5.0
Get-PSResource 'TestScript' -MaximumVersion '1.5.0'

# Should get the latest, non-prerelease version of the script 'TestScript' that is at least version 1.0.0 and at most 2.0.0
Get-PSResource 'TestScript' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'

# Should get version 1.5.0 (non-prerelease) of the script 'TestScript'
Get-PSResource 'TestScript' -RequiredVersion '1.5.0'

# Should find all non-prerelease versions of the module 'TestModule'
Get-PSResource 'TestModule' -AllVersions

# Should get the latest verison of 'TestScript', including prerelease versions
Get-PSResource 'TestScript' -Prerelease


### Getting Installed Nupkgs ###
# Should get the nupkg 'TestNupkg'
Get-PSResource 'TestNupkg'

# Should get the nupkg 'TestNupkg'
Get-PSResource 'TestNupkg' -Type 'Library'

# Should get the nupkg 'TestNupkg'
Get-PSResource 'TestNupkg' -Type 'Module', 'Script', 'Library'

# Should get the nupkgs 'TestNupkg1', 'TestNupkg2', 'TestNupkg3'
Get-PSResource 'TestNupkg1', 'TestNupkg2', 'TestNupkg3'

# Should get the latest, non-prerelease version of the nupkg 'TestNupkg' that is at least 1.5.0
Get-PSResource 'TestNupkg' -MinimumVersion '1.5.0'

# Should get the latest, non-prerelease version of the nupkg 'TestNupkg' that is at most 1.5.0
Get-PSResource 'TestNupkg' -MaximumVersion '1.5.0'

# Should get the latest, non-prerelease version of the nupkg 'TestNupkg' that is at least version 1.0.0 and at most 2.0.0
Get-PSResource 'TestNupkg' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'

# Should get version 1.5.0 (non-prerelease) of the nupkg 'TestNupkg'
Get-PSResource 'TestNupkg' -RequiredVersion '1.5.0'

# Should find all non-prerelease versions of the module 'TestModule'
Get-PSResource 'TestModule' -AllVersions

# Should get the latest verison of 'TestNupkg', including prerelease versions
Get-PSResource 'TestNupkg' -Prerelease
