#######################
### Save-PSResource ###
#######################
### Saving Modules ###
# Should save the module 'TestModule'
Save-PSResource 'TestModule'

# Should save the module 'TestModule'
Save-PSResource -name 'TestModule'

# Should save the module 'TestModule'
Save-PSResource 'TestModule' -Type 'Module'

# Should save the module 'TestModule'
Save-PSResource 'TestModule' -Type 'Module', 'Script', 'Library'

# Should save the modules 'TestModule1', 'TestModule2', 'TestModule3'
Save-PSResource 'TestModule1', 'TestModule2', 'TestModule3'

# Should save the latest, non-prerelease version of the module 'TestModule' that is at least 1.5.0
Save-PSResource 'TestModule' -MinimumVersion '1.5.0'

# Should save the latest, non-prerelease version of the module 'TestModule' that is at most 1.5.0
Save-PSResource 'TestModule' -MaximumVersion '1.5.0'

# Should save the latest, non-prerelease version of the module 'TestModule' that is at least version 1.0.0 and at most 2.0.0
Save-PSResource 'TestModule' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'

# Should save version 1.5.0 (non-prerelease) of the module 'TestModule'
Save-PSResource 'TestModule' -RequiredVersion '1.5.0'

# Should save the latest verison of 'TestModule', including prerelease versions
Save-PSResource 'TestModule' -Prerelease

# Should save 'TestModule' from one of the specified repositories (based on repo priority)
Save-PSResource 'TestModule' -Repository 'Repository1', 'Repository2'

# Should save the module 'TestModule' to the specified directory
Save-PSResource 'TestModule' -Path '.\*\somepath'

# Should save the module 'TestModule' to the specified directory
Save-PSResource 'TestModule' -LiteralPath '.'

# Should save the module 'TestModule' without prompting user for confirmation
Save-PSResource 'TestModule' -Force

#Should save the module 'TestModule' and automatically accept license agreement
Save-PSResource 'TestModule' -AcceptLicense

#Should save the module 'TestModule' from the input object
Find-PSResource 'TestModule' | Save-PSresource



### Saving Scripts ###
# Should save the script 'TestScript'
Save-PSResource 'TestScript'

# Should save the script 'TestScript'
Save-PSResource -name 'TestScript'

# Should save the module 'TestScript'
Save-PSResource 'TestScript' -Type 'Script'

# Should save the module 'TestScript'
Save-PSResource 'TestScript' -Type 'Module', 'Script', 'Library'

# Should save the scripts 'TestScript1', 'TestScript2', 'TestScript3'
Save-PSResource 'TestScript1', 'TestScript2', 'TestScript3'

# Should save the latest, non-prerelease version of the script 'TestScript' that is at least 1.5.0
Save-PSResource 'TestScript' -MinimumVersion '1.5.0'

# Should save the latest, non-prerelease version of the script 'TestScript' that is at most 1.5.0
Save-PSResource 'TestScript' -MaximumVersion '1.5.0'

# Should save the latest, non-prerelease version of the script 'TestScript' that is at least version 1.0.0 and at most 2.0.0
Save-PSResource 'TestScript' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'

# Should save version 1.5.0 (non-prerelease) of the script 'TestScript'
Save-PSResource 'TestScript' -RequiredVersion '1.5.0'

# Should save the latest verison of 'TestScript', including prerelease versions
Save-PSResource 'TestScript' -Prerelease

# Should save 'TestScript' from one of the specified repositories (based on repo priority)
Save-PSResource 'TestScript' -Repository 'Repository1', 'Repository2'

# Should save the script 'TestScript' to the specified directory
Save-PSResource 'TestModule' -Path '.\*\somepath'

# Should save the script 'TestScript' to the specified directory
Save-PSResource 'TestModule' -LiteralPath '.'

# Should save the script 'TestScript' without prompting message regarding untrusted sources
Save-PSResource 'TestScript' -Force

#Should save the script 'TestScript' and automatically accept license agreement
Save-PSResource 'TestScript' -AcceptLicense

#Should save the script 'TestScript' from the input object
Find-PSResource 'TestScript' | Save-PSresource


### Saving Nupkgs ###
# Should save the nupkg 'TestNupkg'
Save-PSResource 'TestNupkg'

# Should save the nupkg 'TestNupkg'
Save-PSResource 'TestNupkg' -Type 'Library'

# Should save the nupkg 'TestNupkg'
Save-PSResource 'TestNupkg' -Type 'Module', 'Script', 'Library'

# Should save the nupkgs 'TestNupkg1', 'TestNupkg2', 'TestNupkg3'
Save-PSResource 'TestNupkg1', 'TestNupkg2', 'TestNupkg3'

# Should save the latest, non-prerelease version of the nupkg 'TestNupkg' that is at least 1.5.0
Save-PSResource 'TestNupkg' -MinimumVersion '1.5.0'

# Should save the latest, non-prerelease version of the nupkg 'TestNupkg' that is at most 1.5.0
Save-PSResource 'TestNupkg' -MaximumVersion '1.5.0'

# Should save the latest, non-prerelease version of the nupkg 'TestNupkg' that is at least version 1.0.0 and at most 2.0.0
Save-PSResource 'TestNupkg' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'

# Should save version 1.5.0 (non-prerelease) of the nupkg 'TestNupkg'
Save-PSResource 'TestNupkg' -RequiredVersion '1.5.0'

# Should save the latest verison of 'TestNupkg', including prerelease versions
Save-PSResource 'TestNupkg' -Prerelease

# Should save the nupkg 'TestNupkg' from one of the specified repositories (based on repo priority)
Save-PSResource 'TestNupkg' -Repository 'Repository1', 'Repository2'

# Should save the script 'TestScript' to the specified directory
Save-PSResource 'TestModule' -Path '.\*\somepath'

# Should save the script 'TestScript' to the specified directory
Save-PSResource 'TestModule' -LiteralPath '.'

# Should save the nupkg 'TestNupkg' without prompting user for confirmation
Save-PSResource 'TestNupkg' -Force

#Should save the nupkg 'TestNupkg' and automatically accept license agreement
Save-PSResource 'TestNupkg' -AcceptLicense

#Should save the nupkg 'TestNupkg' as a nupkg (if it was originally nupkg) instead of expanding it into a folder
Save-PSResource 'TestNupkg' -AsNupkg

#Should save the nupkg 'TestNupkg' and retain the runtimes directory hierarchy within the nupkg to the root of the destination
Save-PSResource 'TestNupkg' -IncludeAllRuntimes
