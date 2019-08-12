#######################
### Find-PSResource ###
#######################

### Find command ###
# Should find the command "TestCommand"
Find-PSResource -name "TestCommand"

# Should find the command "TestCommand"
Find-PSResource "TestCommand"

# Should find the command "TestCommand"
Find-PSResource "TestCommand" -Type "Command"

# Should find the command "TestCommand"
Find-PSResource "TestCommand" -Type "Command","DscResource", "RoleCapability","Module", "Script"

# Should find the command "TestCommand" from all the modules with name "TestCommandModuleName" (default to the latest [minor?] version)
Find-PSResource -name "TestCommand" -ModuleName "TestCommandModuleName"

# Should find the command "TestCommand" from all the modules with name "TestCommandModuleName" that have a minimum version 1.5.0, not including prerelease versions
Find-PSResource -name "TestCommand" -ModuleName "TestCommandModuleName" -MinimumVersion "1.5.0"

# Should find the command "TestCommand" from all the modules with name "TestCommandModuleName" that have a maximum version of 1.5.0, not including prerelease versions
Find-PSResource -name "TestCommand" -ModuleName "TestCommandModuleName" -MaximumVersion "1.5.0"

# Should find the command "TestCommand" from all the modules with name "TestCommandModuleName" that have a minimum version of 1.0.0 and a maximum version of 2.0.0, not including prerelease versions
Find-PSResource -name "TestCommand" -ModuleName "TestCommandModuleName" -MinimumVersion "1.0.0" -MaximumVersion "2.0.0"

# Should find the command "TestCommand" from all the modules with name "TestCommandModuleName" that have a required version of 1.5.0, not including prerelease versions
Find-PSResource -name "TestCommand" -ModuleName "TestCommandModuleName" -RequiredVersion "1.5.0"

# Should find the command "TestCommand" from all versions of the module "TestCommandModuleName", not including prerelease versions
Find-PSResource -name "TestCommand" -ModuleName "TestCommandModuleName" -AllVersions

# Should find the command "TestCommand" from the resource (latest version), including prerelease versions
Find-PSResource -name "TestCommand" -ModuleName "TestCommandModuleName" -AllowPrerelease

# Should find the command "TestCommand" from a resource with the tags "Tag1", "Tag2", "Tag3"
Find-PSResource -name "TestCommand" -Tag "Tag1","Tag2","Tag3"

# Should find the command "TestCommand" from a resource that has "Test" in either the module name or description
Find-PSResource -name "TestCommand" -Filter "Test"

# Should find the command "TestCommand" from one of the specified repositories
Find-PSResource -name "TestCommand" -Repository "Repository1", "Repository2"

# Should NOT find the command "TestCommand"
Find-PSResource "TestCommand" -Type "TestDscResource" 



### Find DSC resource ###
# Should find the DSC resource "TestDscResource"
Find-PSResource -name "TestDscResource"

# Should find the DSC resource "TestDscResource"
Find-PSResource "TestDscResource"

# Should find the DSC resource "TestDscResource"
Find-PSResource "TestDscResource" -Type "DscResource"

# Should find the DSC resource "TestDscResource"
Find-PSResource "TestDscResource" -Type "Command","DscResource", "RoleCapability","Module", "Script"

# Should find the DSC resource "TestDscResource" that is contained within the module "TestDscResourceModuleName" (default to the latest [minor?] version)
Find-PSResource -name "TestDscResource" -ModuleName "TestDscResourceModuleName"

# Should find the DSC resource "TestDscResource" from all the modules with name "TestDscResourceModuleName" that have a minimum version 1.5.0, not including prerelease versions
Find-PSResource -name "TestDscResource" -ModuleName "TestDscResourceModuleName" -MinimumVersion "1.5.0"

# Should find the DSC resource "TestDscResource" from all the modules with name "TestDscResourceModuleName" that have a maximum version of 1.5.0, not including prerelease versions
Find-PSResource -name "TestDscResource" -ModuleName "TestDscResourceModuleName" -MaximumVersion "1.5.0"

# Should find the command "TestDscResource" from all the modules with name "TestDscResourceModuleName" that have a minimum version of 1.0.0 and a maximum version of 2.0.0, not including prerelease versions
Find-PSResource -name "TestDscResource" -ModuleName "TestDscResourceModuleName" -MinimumVersion "1.0.0" -MaximumVersion "2.0.0"

# Should find the DSC resource "TestDscResource" from all the modules with name "TestDscResourceModuleName" that have a required version of 1.5.0, not including prerelease versions
Find-PSResource -name "TestDscResource" -ModuleName "TestDscResourceModuleName" -RequiredVersion "1.5.0"

# Should find the DSC resource "TestDscResource" from all versions of the module "TestDscResourceModuleName", not including prerelease versions
Find-PSResource -name "TestDscResource" -ModuleName "TestDscResourceModuleName" -AllVersions

# Should find the DSC resource "TestDscResource" from the resource (latest version), including prerelease versions
Find-PSResource -name "TestDscResource" -ModuleName "TestDscResourceModuleName" -AllowPrerelease

# Should find the DSC resource "TestDscResource" from a resource with the tags "Tag1", "Tag2", "Tag3"
Find-PSResource -name "TestDscResource" -Tag "Tag1","Tag2","Tag3"

# Should find the DSC resource "TestDscResource" from a resource that has "Test" in either the module name or description
Find-PSResource -name "TestDscResource" -Filter "Test"

# Should find the DSC resource "TestDscResource" from one of the specified repositories
Find-PSResource -name "TestDscResource" -Repository "Repository1", "Repository2"

# Should NOT find the DSC resource "TestDscResource"
Find-PSResource "TestDscResource" -Type "DscResource" 



### Find role capability ###
# Should find the role capability "TestRoleCapability"
Find-PSResource -name "TestRoleCapability"

# Should find the role capability "TestRoleCapability"
Find-PSResource "TestRoleCapability"

# Should find the role capability "TestRoleCapability"
Find-PSResource "TestRoleCapability" -Type "DscResource"

# Should find the role capability "TestRoleCapability"
Find-PSResource "TestRoleCapability" -Type "Command","DscResource", "RoleCapability","Module", "Script"

# Should find the role capability "TestRoleCapability" from the module (default to the latest [minor?] version)
Find-PSResource -name "TestRoleCapability" -ModuleName "TestDscResourceModuleName"

# Should find the role capability "TestRoleCapability" from all the modules with name "TestDscResourceModuleName" that have a minimum version 1.5.0, not including prerelease versions
Find-PSResource -name "TestRoleCapability" -ModuleName "TestDscResourceModuleName" -MinimumVersion "1.5.0"

# Should find the role capability "TestRoleCapability" from all the modules with name "TestDscResourceModuleName" that have a maximum version of 1.5.0, not including prerelease versions
Find-PSResource -name "TestRoleCapability" -ModuleName "TestDscResourceModuleName" -MaximumVersion "1.5.0"

# Should find the command "TestRoleCapability" from all the modules with name "TestDscResourceModuleName" that have a minimum version of 1.0.0 and a maximum version of 2.0.0, not including prerelease versions
Find-PSResource -name "TestRoleCapability" -ModuleName "TestDscResourceModuleName" -MinimumVersion "1.0.0" -MaximumVersion "2.0.0"

# Should find the role capability "TestRoleCapability"  from all the modules with name "TestDscResourceModuleName" that have a required version of 1.5.0, not including prerelease versions
Find-PSResource -name "TestRoleCapability" -ModuleName "TestDscResourceModuleName" -RequiredVersion "1.5.0"

# Should find the role capability "TestRoleCapability" from the resource (lists all versions), not including prerelease versions
Find-PSResource -name "TestRoleCapability" -ModuleName "TestDscResourceModuleName" -AllVersions

# Should find the role capability "TestRoleCapability" from the resource (latest version), including prerelease versions
Find-PSResource -name "TestRoleCapability" -ModuleName "TestDscResourceModuleName" -AllowPrerelease

# Should find the role capability "TestRoleCapability" from a resource with the tags "Tag1", "Tag2", "Tag3"
Find-PSResource -name "TestRoleCapability" -Tag "Tag1","Tag2","Tag3"

# Should find the role capability "TestRoleCapability" from a resource that has "Test" in either the module name or description
Find-PSResource -name "TestRoleCapability" -Filter "Test"

# Should find the role capability "TestRoleCapability" from one of the specified repositories
Find-PSResource -name "TestRoleCapability" -Repository "Repository1", "Repository2"

# Should NOT find the role capability "TestRoleCapability"
Find-PSResource "TestRoleCapability" -Type "TestDscResource" 



### Find module ###
# Should find the module "TestModule"
Find-PSResource -name "TestModule"

# Should find the module "TestModule"
Find-PSResource "TestModule"

# Should find the module "TestModule"
Find-PSResource "TestModule" -Type "Module"

# Should find the module "TestModule"
Find-PSResource "TestModule" -Type "Command","DscResource", "RoleCapability","Module", "Script"

# Should find all modules named "TestModule" that have a minimum version of 1.5.0, not including prerelease versions
Find-PSResource -name "TestModule" -MinimumVersion "1.5.0"

# Should find all modules named "TestModule" that have a maximum version of 1.5.0, not including prerelease versions
Find-PSResource -name "TestModule" -MaximumVersion "1.5.0"

# Should find all modules named "TestModule" that have a minimum version of 1.0.0 and a maximum version of 1.5.0, not including prerelease versions
Find-PSResource -name "TestModule" -MinimumVersion "1.0.0" -MaximumVersion "2.0.0"

# Should find all the modules named "TestModule" that is version 1.5.0
Find-PSResource -name "TestModule" -RequiredVersion "1.5.0"

# Should find all versions of all modules named "TestModule", not including prerelease versions
Find-PSResource -name "TestModule" -AllVersions

# Should find all modules named "TestModule", including prerelease versions
Find-PSResource -name "TestModule" -AllowPrerelease

# Should find all the modules named "TestModule" with the tags "Tag1", "Tag2", "Tag3"
Find-PSResource -name "TestModule" -Tag "Tag1","Tag2","Tag3"

# Should find all the modules named "TestModule" that have "Test" in either the module name or description
Find-PSResource -name "TestModule" -Filter "Test"

# Should find all the modules named "TestModule" from all of the specified repositories
Find-PSResource -name "TestModule" -Repository "Repository1", "Repository2"

# Should find all the modules named "TestModule" and all modules that are dependent upon "TestModule"
Find-PSResource -name "TestModule" -IncludeDependencies

# Should find all the modules named "TestModule" that have DSC resources
Find-PSResource -name "TestModule" -Includes 'DscResource'

# Should find all the modules named "TestModule" that have DSC resources named "TestDscResource"
Find-PSResource -name "TestModule" -DSCResource "TestDscResource"

# Should find all the modules named "TestModule" that have a role capacity named "TestDscResource"
Find-PSResource -name "TestModule" -RoleCapability "TestRoleCapability"

# Should find all the modules named "TestModule" that have a command named "Test-Command"
Find-PSResource -name "TestModule" -Command "Test-Command"



### Find Script ###
# Should find all scripts named "TestScript"
Find-PSResource -name "TestScript"

# Should find all scripts named "TestScript"
Find-PSResource "TestScript"

# Should find all scripts named "TestScript"
Find-PSResource "TestScript" -Type "Script"

# Should find all scripts named "TestScript"
Find-PSResource "TestScript" -Type "Command","DscResource", "RoleCapability","Module", "Script"

# Should find all scripts named "TestScript" that have a minimum version of 1.5.0, not including prerelease versions
Find-PSResource -name "TestScript" -MinimumVersion "1.5.0"

# Should find all scripts named "TestScript" that have a maximum version of 1.5.0, not including prerelease versions
Find-PSResource -name "TestScript" -MaximumVersion "1.5.0"

# Should find all scripts named "TestScript" that have a minimum version of 1.0.0 and a maximum version of 1.5.0, not including prerelease versions
Find-PSResource -name "TestScript" -MinimumVersion "1.0.0" -MaximumVersion "2.0.0"

# Should find all the scripts named "TestScript" that is version 1.5.0
Find-PSResource -name "TestScript" -RequiredVersion "1.5.0"

# Should find all versions of all scripts named "TestScript", not including prerelease versions
Find-PSResource -name "TestScript" -AllVersions

# Should find all scripts named "TestScript", including prerelease versions
Find-PSResource -name "TestScript" -AllowPrerelease

# Should find all the scripts named "TestScript" with the tags "Tag1", "Tag2", "Tag3"
Find-PSResource -name "TestScript" -Tag "Tag1","Tag2","Tag3"

# Should find all the scripts named "TestScript" that have "Test" in either the script name or description
Find-PSResource -name "TestScript" -Filter "Test"

# Should find all the scripts named "TestScript" from all of the specified repositories
Find-PSResource -name "TestScript" -Repository "Repository1", "Repository2"

# Should find all the scripts named "TestScript" and all modules that are dependent upon "TestScript"
Find-PSResource -name "TestScript" -IncludeDependencies

# Should find all the scripts named "TestScript" that have a function named "TestFunction"
Find-PSResource -name "TestScript" -Includes 'TestFunction'

# Should find all the modules named "TestScript" that have a command named "Test-Command"
Find-PSResource -name "TestScript" -Command "Test-Command"



### Find multiple resources ###
# Should find the resources "TestResource1", "TestResource2", "TestResource3"
Find-PSResource -name "TestResource1", "TestResource2", "TestResource3"

# Should find the resource "TestResource1", "TestResource2", "TestResource3"
Find-PSResource "TestResource1", "TestResource2", "TestResource3"

# Should find the resources "TestResource1", "TestResource2", "TestResource3"
Find-PSResource "TestResource1", "TestResource2", "TestResource3" -Type "Module"

# Should find the "TestResource1", "TestResource2", "TestResource3"
Find-PSResource "TestResource1", "TestResource2", "TestResource3" -Type "Command","DscResource", "RoleCapability","Module", "Script"

# Should find all modules named "TestResource1", "TestResource2", "TestResource3" that have a minimum version of 1.5.0, not including prerelease versions
Find-PSResource -name "TestResource1", "TestResource2", "TestResource3" -MinimumVersion "1.5.0"

# Should find all modules named "TestResource1", "TestResource2", "TestResource3" that have a maximum version of 1.5.0, not including prerelease versions
Find-PSResource -name "TestResource1", "TestResource2", "TestResource3" -MaximumVersion "1.5.0"

# Should find all modules named "TestResource1", "TestResource2", "TestResource3" that have a minimum version of 1.0.0 and a maximum version of 1.5.0, not including prerelease versions
Find-PSResource -name "TestResource1", "TestResource2", "TestResource3" -MinimumVersion "1.0.0" -MaximumVersion "2.0.0"

# Should find all the modules named "TestResource1", "TestResource2", "TestResource3" that is version 1.5.0
Find-PSResource -name "TestResource1", "TestResource2", "TestResource3" -RequiredVersion "1.5.0"

# Should find all versions of all modules named "TestResource1", "TestResource2", "TestResource3", not including prerelease versions
Find-PSResource -name "TestResource1", "TestResource2", "TestResource3" -AllVersions

# Should find all modules named "TestResource1", "TestResource2", "TestResource3", including prerelease versions
Find-PSResource -name "TestResource1", "TestResource2", "TestResource3" -AllowPrerelease

# Should find all the modules named "TestResource1", "TestResource2", "TestResource3" with the tags "Tag1", "Tag2", "Tag3"
Find-PSResource -name "TestResource1", "TestResource2", "TestResource3" -Tag "Tag1","Tag2","Tag3"

# Should find all the modules named "TestResource1", "TestResource2", "TestResource3" that have "Test" in either the module name or description
Find-PSResource -name "TestResource1", "TestResource2", "TestResource3" -Filter "Test"

# Should find all the modules named "TestResource1", "TestResource2", "TestResource3" from all of the specified repositories
Find-PSResource -name "TestResource1", "TestResource2", "TestResource3" -Repository "Repository1", "Repository2"

# Should find all the modules named "TestResource1", "TestResource2", "TestResource3" and all modules that are dependent upon "TestResource1", "TestResource2", "TestResource3"
Find-PSResource -name "TestResource1", "TestResource2", "TestResource3" -IncludeDependencies

# Should find all the modules named "TestResource1", "TestResource2", "TestResource3" that have DSC resources
Find-PSResource -name "TestResource1", "TestResource2", "TestResource3" -Includes 'DscResource'

# Should find all the modules named "TestResource1", "TestResource2", "TestResource3" that have DSC resources named "TestDscResource"
Find-PSResource -name "TestResource1", "TestResource2", "TestResource3" -DSCResource "TestDscResource"

# Should find all the modules named "TestResource1", "TestResource2", "TestResource3" that have a role capacity named "TestRoleCapacity"
Find-PSResource -name "TestResource1", "TestResource2", "TestResource3" -RoleCapability "TestRoleCapability"

# Should find all the modules named "TestResource1", "TestResource2", "TestResource3" that have a command named "Test-Command"
Find-PSResource -name "TestResource1", "TestResource2", "TestResource3" -Command "Test-Command"



##########################
### Install-PSResource ###
##########################

### Installing Modules ###
Install-PSResource 'TestModule' -Repository 'https://mygallery.com'

Install-PSResource 'TestModule1', 'TestModule2', 'TestModule3' -Repository 'https://mygallery.com'



### Installing Scripts ###