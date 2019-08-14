#######################
### Find-PSResource ###
#######################

### Find command ###
# Should find the command 'TestCommand'
Find-PSResource -name 'TestCommand'

# Should find the command 'TestCommand'
Find-PSResource 'TestCommand'

# Should find the command 'TestCommand'
Find-PSResource 'TestCommand' -Type 'Command'

# Should find the command 'TestCommand'
Find-PSResource 'TestCommand' -Type 'Command', 'DscResource', 'RoleCapability', 'Module', 'Script'

# Should find the command 'TestCommand' from the module 'TestCommandModuleName'
Find-PSResource 'TestCommand' -ModuleName 'TestCommandModuleName'

# Should find the command 'TestCommand' from the latest, non-prerelease module 'TestCommandModuleName' that has a minimum version 1.5.0
Find-PSResource 'TestCommand' -ModuleName 'TestCommandModuleName' -MinimumVersion '1.5.0'

# Should find the command 'TestCommand' from the latest, non-prerelease module 'TestCommandModuleName' that has a maximum version of 1.5.0
Find-PSResource 'TestCommand' -ModuleName 'TestCommandModuleName' -MaximumVersion '1.5.0'

# Should find the command 'TestCommand' from the latest, non-prerelease module 'TestCommandModuleName' that has a minimum version of 1.0.0 and a maximum version of 2.0.0
Find-PSResource 'TestCommand' -ModuleName 'TestCommandModuleName' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'

# Should find the command 'TestCommand' from the module 'TestCommandModuleName' that is exactly version 1.5.0 (non-prerelease)
Find-PSResource 'TestCommand' -ModuleName 'TestCommandModuleName' -RequiredVersion '1.5.0'

# Should find the command 'TestCommand' from all non-prerelease versions of the module 'TestCommandModuleName'
Find-PSResource 'TestCommand' -ModuleName 'TestCommandModuleName' -AllVersions

# Should find the command 'TestCommand' from the latest verions of the module 'TestCommandModuleName', including prerelease versions
Find-PSResource 'TestCommand' -ModuleName 'TestCommandModuleName' -Prerelease

# Should find the command 'TestCommand' from a resource with the tags 'Tag1', 'Tag2', 'Tag3'
Find-PSResource 'TestCommand' -Tag 'Tag1', 'Tag2', 'Tag3'

# Should find the command 'TestCommand' from a resource that has 'Test' in either the module name or description
Find-PSResource 'TestCommand' -Filter 'Test'

# Should find the command 'TestCommand' from one of the specified repositories
Find-PSResource 'TestCommand' -Repository 'Repository1', 'Repository2'

# Should NOT find the command 'TestCommand'
Find-PSResource 'TestCommand' -Type 'TestDscResource'



### Find DSC resource ###
# Should find the DSC resource 'TestDscResource'
Find-PSResource -name 'TestDscResource'

# Should find the DSC resource 'TestDscResource'
Find-PSResource 'TestDscResource'

# Should find the DSC resource 'TestDscResource'
Find-PSResource 'TestDscResource' -Type 'DscResource'

# Should find the DSC resource 'TestDscResource'
Find-PSResource 'TestDscResource' -Type 'Command', 'DscResource', 'RoleCapability', 'Module', 'Script'

# Should find the DSC resource 'TestDscResource' that is contained within the module 'TestDscResourceModuleName'
Find-PSResource  'TestDscResource' -ModuleName 'TestDscResourceModuleName'

# Should find the DSC resource 'TestDscResource' from the latest, non-prerelease module 'TestDscResourceModuleName' that has a minimum version 1.5.0
Find-PSResource 'TestDscResource' -ModuleName 'TestDscResourceModuleName' -MinimumVersion '1.5.0'

# Should find the DSC resource 'TestDscResource' from the latest, non-prerelease module 'TestDscResourceModuleName' that has a maximum version of 1.5.0
Find-PSResource 'TestDscResource' -ModuleName 'TestDscResourceModuleName' -MaximumVersion '1.5.0'

# Should find the DSC resource 'TestDscResource' from the latest, non-prelease module 'TestDscResourceModuleName' that has a minimum version of 1.0.0 and a maximum version of 2.0.0
Find-PSResource 'TestDscResource' -ModuleName 'TestDscResourceModuleName' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'

# Should find the DSC resource 'TestDscResource' from the module 'TestDscResourceModuleName' that has a required version of 1.5.0 (non-prerelease)
Find-PSResource 'TestDscResource' -ModuleName 'TestDscResourceModuleName' -RequiredVersion '1.5.0'

# Should find the DSC resource 'TestDscResource' from all non-prerelease versions of the module 'TestDscResourceModuleName'
Find-PSResource 'TestDscResource' -ModuleName 'TestDscResourceModuleName' -AllVersions

# Should find the DSC resource 'TestDscResource' from the latest module 'TestDscResourceModuleName', including prerelease versions
Find-PSResource 'TestDscResource' -ModuleName 'TestDscResourceModuleName' -Prerelease

# Should find the DSC resource 'TestDscResource' from a resource with the tags 'Tag1', 'Tag2', 'Tag3'
Find-PSResource 'TestDscResource' -Tag 'Tag1', 'Tag2', 'Tag3'

# Should find the DSC resource 'TestDscResource' from a resource that has 'Test' in either the module name or description
Find-PSResource 'TestDscResource' -Filter 'Test'

# Should find the DSC resource 'TestDscResource' from one of the specified repositories
Find-PSResource 'TestDscResource' -Repository 'Repository1', 'Repository2'

# Should NOT find the DSC resource 'TestDscResource'
Find-PSResource 'TestDscResource' -Type 'DscResource'



### Find role capability ###
# Should find the role capability 'TestRoleCapability'
Find-PSResource -name 'TestRoleCapability'

# Should find the role capability 'TestRoleCapability'
Find-PSResource 'TestRoleCapability'

# Should find the role capability 'TestRoleCapability'
Find-PSResource 'TestRoleCapability' -Type 'DscResource'

# Should find the role capability 'TestRoleCapability'
Find-PSResource 'TestRoleCapability' -Type 'Command', 'DscResource', 'RoleCapability', 'Module', 'Script'

# Should find the role capability 'TestRoleCapability' from the module
Find-PSResource 'TestRoleCapability' -ModuleName 'TestDscResourceModuleName'

# Should find the role capability 'TestRoleCapability' from the latest, non-prerelease module 'TestDscResourceModuleName' that has a minimum version 1.5.0
Find-PSResource 'TestRoleCapability' -ModuleName 'TestDscResourceModuleName' -MinimumVersion '1.5.0'

# Should find the role capability 'TestRoleCapability' from the latest, non-prerelease modules with name 'TestDscResourceModuleName' that has a maximum version of 1.5.0
Find-PSResource 'TestRoleCapability' -ModuleName 'TestDscResourceModuleName' -MaximumVersion '1.5.0'

# Should find the command 'TestRoleCapability' from the latest, non-prerelease module with name 'TestDscResourceModuleName' that has a minimum version of 1.0.0 and a maximum version of 2.0.0
Find-PSResource 'TestRoleCapability' -ModuleName 'TestDscResourceModuleName' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'

# Should find the role capability 'TestRoleCapability' from the module 'TestDscResourceModuleName' that has a required version of 1.5.0 (non-prerelease)
Find-PSResource 'TestRoleCapability' -ModuleName 'TestDscResourceModuleName' -RequiredVersion '1.5.0'

# Should find the role capability 'TestRoleCapability' from all non-prerelease versions of the module 'TestDscResourceModuleName'
Find-PSResource 'TestRoleCapability' -ModuleName 'TestDscResourceModuleName' -AllVersions

# Should find the role capability 'TestRoleCapability' from the module 'TestDscresourceModuleName', including prerelease versions
Find-PSResource 'TestRoleCapability' -ModuleName 'TestDscResourceModuleName' -Prerelease

# Should find the role capability 'TestRoleCapability' from a resource with the tags 'Tag1', 'Tag2', 'Tag3'
Find-PSResource 'TestRoleCapability' -Tag 'Tag1', 'Tag2', 'Tag3'

# Should find the role capability 'TestRoleCapability' from a resource that has 'Test' in either the module name or description
Find-PSResource 'TestRoleCapability' -Filter 'Test'

# Should find the role capability 'TestRoleCapability' from one of the specified repositories
Find-PSResource 'TestRoleCapability' -Repository 'Repository1', 'Repository2'

# Should NOT find the role capability 'TestRoleCapability'
Find-PSResource 'TestRoleCapability' -Type 'TestDscResource'



### Find module ###
# Should find the module 'TestModule'
Find-PSResource -name 'TestModule'

# Should find the module 'TestModule'
Find-PSResource 'TestModule'

# Should find the module 'TestModule'
Find-PSResource 'TestModule' -Type 'Module'

# Should find the module 'TestModule'
Find-PSResource 'TestModule' -Type 'Command', 'DscResource', 'RoleCapability', 'Module', 'Script'

# Should find the non-prerelase module 'TestModule' that has a minimum version of 1.5.0
Find-PSResource 'TestModule' -MinimumVersion '1.5.0'

# Should find the non-prerelease module 'TestModule' that has a maximum version of 1.5.0
Find-PSResource 'TestModule' -MaximumVersion '1.5.0'

# Should find the non-prerelease module 'TestModule' that has a minimum version of 1.0.0 and a maximum version of 1.5.0
Find-PSResource 'TestModule' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'

# Should find the latest, non-prerelease scripts 'TestModule' that is exactly version 1.5.0
Find-PSResource 'TestModule' -RequiredVersion '1.5.0'

# Should find all versions of all non-prerelease versions of the module 'TestModule'
Find-PSResource 'TestModule' -AllVersions

# Should find the lastest, non-prerelease version of the module 'TestModule', including prerelease versions
Find-PSResource 'TestModule' -Prerelease

# Should find the module 'TestModule' with the tags 'Tag1', 'Tag2', 'Tag3'
Find-PSResource 'TestModule' -Tag 'Tag1', 'Tag2', 'Tag3'

# Should find the module 'TestModule' that has 'Test' in either the module name or description
Find-PSResource 'TestModule' -Filter 'Test'

# Should find the module 'TestModule' from all of the specified repositories
Find-PSResource 'TestModule' -Repository 'Repository1', 'Repository2'

# Should find the module 'TestModule' and all modules that are dependent upon 'TestModule'
Find-PSResource 'TestModule' -IncludeDependencies

# Should find the module 'TestModule' that has DSC resources
Find-PSResource 'TestModule' -Includes 'DscResource'

# Should find the module 'TestModule' that has DSC resources named 'TestDscResource'
Find-PSResource 'TestModule' -DSCResource 'TestDscResource'

# Should find the module 'TestModule' that has a role capacity named 'TestDscResource'
Find-PSResource 'TestModule' -RoleCapability 'TestRoleCapability'

# Should find the module 'TestModule' that has a command named 'Test-Command'
Find-PSResource 'TestModule' -Command 'Test-Command'



### Find Script ###
# Should find the script named 'TestScript'
Find-PSResource -name 'TestScript'

# Should find the script named 'TestScript'
Find-PSResource 'TestScript'

# Should find the script named 'TestScript'
Find-PSResource 'TestScript' -Type 'Script'

# Should find the script named 'TestScript'
Find-PSResource 'TestScript' -Type 'Command', 'DscResource', 'RoleCapability', 'Module', 'Script'

# Should find the latest, non-prerelease script 'TestScript' that has a minimum version of 1.5.0
Find-PSResource 'TestScript' -MinimumVersion '1.5.0'

# Should find the latest, non-prerelease script 'TestScript' that have a maximum version of 1.5.0
Find-PSResource 'TestScript' -MaximumVersion '1.5.0'

# Should find the latest, non-prerelease script 'TestScript' that has a minimum version of 1.0.0 and a maximum version of 1.5.0
Find-PSResource 'TestScript' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'

# Should find the latest, non-prerelease scripts 'TestScript' that is exactly version 1.5.0
Find-PSResource 'TestScript' -RequiredVersion '1.5.0'

# Should find all versions of all scripts named 'TestScript', not including prerelease versions
Find-PSResource 'TestScript' -AllVersions

# Should find the script 'TestScript', including prerelease versions
Find-PSResource 'TestScript' -AllowPrerelease

# Should find the script 'TestScript' with the tags 'Tag1', 'Tag2', 'Tag3'
Find-PSResource 'TestScript' -Tag 'Tag1', 'Tag2', 'Tag3'

# Should find the script 'TestScript' that has 'Test' in either the script name or description
Find-PSResource 'TestScript' -Filter 'Test'

# Should find the script 'TestScript' from all of the specified repositories
Find-PSResource 'TestScript' -Repository 'Repository1', 'Repository2'

# Should find the script 'TestScript' and all modules that are dependent upon 'TestScript'
Find-PSResource 'TestScript' -IncludeDependencies

# Should find the script 'TestScript' that has a function named 'TestFunction'
Find-PSResource 'TestScript' -Includes 'TestFunction'

# Should find the script 'TestScript' that has a command named 'Test-Command'
Find-PSResource 'TestScript' -Command 'Test-Command'



### Find multiple resources ###
# Should find the resources 'TestResource1', 'TestResource2', 'TestResource3'
Find-PSResource -name 'TestResource1', 'TestResource2', 'TestResource3'

# Should find the resource 'TestResource1', 'TestResource2', 'TestResource3'
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3'

# Should find the resources 'TestResource1', 'TestResource2', 'TestResource3'
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -Type 'Module'

# Should find the 'TestResource1', 'TestResource2', 'TestResource3'
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -Type 'Command', 'DscResource', 'RoleCapability', 'Module', 'Script'

# Should find the latest, non-prerelease modules 'TestResource1', 'TestResource2', 'TestResource3' that have a minimum version of 1.5.0
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -MinimumVersion '1.5.0'

# Should find the latest, non-prerelease modules 'TestResource1', 'TestResource2', 'TestResource3' that have a maximum version of 1.5.0
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -MaximumVersion '1.5.0'

# Should find the latest, non-prerelease modules 'TestResource1', 'TestResource2', 'TestResource3' that have a minimum version of 1.0.0 and a maximum version of 1.5.0
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -MinimumVersion '1.0.0' -MaximumVersion '2.0.0'

# Should find the modules 'TestResource1', 'TestResource2', 'TestResource3' that are exactly version 1.5.0
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -RequiredVersion '1.5.0'

# Should find all non-prerelease versions of the modules 'TestResource1', 'TestResource2', 'TestResource3', not including prerelease versions
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -AllVersions

# Should find the modules 'TestResource1', 'TestResource2', 'TestResource3', including prerelease versions
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -Prerelease

# Should find the modules 'TestResource1', 'TestResource2', 'TestResource3' with the tags 'Tag1', 'Tag2', 'Tag3'
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -Tag 'Tag1', 'Tag2', 'Tag3'

# Should find the modules 'TestResource1', 'TestResource2', 'TestResource3' that have 'Test' in either the module name or description
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -Filter 'Test'

# Should find the modules 'TestResource1', 'TestResource2', 'TestResource3' from all of the specified repositories
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -Repository 'Repository1', 'Repository2'

# Should find the modules 'TestResource1', 'TestResource2', 'TestResource3' and all modules that are dependent upon 'TestResource1', 'TestResource2', 'TestResource3'
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -IncludeDependencies

# Should find the modules 'TestResource1', 'TestResource2', 'TestResource3' that have DSC resources
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -Includes 'DscResource'

# Should find the modules 'TestResource1', 'TestResource2', 'TestResource3' that have DSC resources named 'TestDscResource'
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -DSCResource 'TestDscResource'

# Should find all the modules named 'TestResource1', 'TestResource2', 'TestResource3' that have a role capacity named 'TestRoleCapacity'
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -RoleCapability 'TestRoleCapability'

# Should find all the modules named 'TestResource1', 'TestResource2', 'TestResource3' that have a command named 'Test-Command'
Find-PSResource 'TestResource1', 'TestResource2', 'TestResource3' -Command 'Test-Command'
