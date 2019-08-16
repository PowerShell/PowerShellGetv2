##########################
### Publish-PSResource ###
##########################

### Publish module ###
# Should publish the module 'TestModule'
Publish-PSResource -name 'TestModule'

# Should publish the module 'TestModule'
Publish-PSResource 'TestModule'

# Should publish the module 'TestModule' from the specified path
Publish-PSResource 'TestModule' -Path '.\*\somepath'

# Should publish the module 'TestModule' from the specified literal path
Publish-PSResource 'TestModule' -LiteralPath '.'

# Should publish the version 1.5.0 of the module 'TestModule'
Publish-PSResource 'TestModule' -RequiredVersion '1.5.0'

# Should publish the lastest version of the module 'TestModule' even if it's a prerelease version
Publish-PSResource 'TestModule' -Prerelease

# Should publish the version 1.5.0 of the module 'TestModule'
Publish-PSResource 'TestModule' -NuGetApiKey '1234567890'

# Should publish the module 'TestModule' to the specified repository
Publish-PSResource 'TestModule' -Repository 'Repository'

# Should publish the module 'TestModule' with release notes
Publish-PSResource 'TestModule' -ReleaseNotes 'Mock release notes.'

# Should publish the module 'TestModule' with the tags 'Tag1', 'Tag2', 'Tag3'
Publish-PSResource 'TestModule' -Tags 'Tag1', 'Tag2', 'Tag3'

# Should publish the module 'TestModule' with a specified license uri
Publish-PSResource 'TestModule' -LicenseUri 'www.licenseuri.com'

# Should publish the module 'TestModule' with a specified icon uri
Publish-PSResource 'TestModule' -IconUri 'www.iconuri.com'

# Should publish the module 'TestModule' with a specified projected uri
Publish-PSResource 'TestModule' -ProjectUri 'www.projecturi.com'

# Should publish the module 'TestModule' and exclude the specified file from the nuspec.
Publish-PSResource 'TestModule' -Exclude 'some\path\file.ps1'

# Should publish the module 'TestModule' without asking for user confirmation
Publish-PSResource 'TestModule' -Force

# Should publish the module 'TestModule' without checking that all dependencies are present
Publish-PSResource 'TestModule' -SkipDependenciesCheck

# Should publish the module 'TestModule' with a specified nuspec file
Publish-PSResource 'TestModule' -Nuspec '\path\to\file.nuspec'


# Should publish the nupkg 'TestNupkg' from the specified literal path
Publish-PSResource 'TestModule' -DestinationPath '.\TestNupkg.nupkg'



### Publish Script ###
# Should publish the script 'TestScript' from the specified path
Publish-PSResource 'TestScript' -Path '.\*\TestScript.ps1'

# Should publish the script 'TestScript' from the specified literal path
Publish-PSResource 'TestScript' -LiteralPath '.\TestScript.ps1'

# Should publish the version 1.5.0 of the script 'TestScript'
Publish-PSResource 'TestScript' -RequiredVersion '1.5.0'

# Should publish the lastest version of the script 'TestScript' even if it's a prerelease version
Publish-PSResource 'TestScript' -Prerelease

# Should publish the version 1.5.0 of the script 'TestScript'
Publish-PSResource 'TestScript' -NuGetApiKey '1234567890'

# Should publish the script 'TestScript' to the specified repository
Publish-PSResource 'TestScript' -Repository 'Repository'

# Should publish the script 'TestScript' with release notes
Publish-PSResource 'TestScript' -ReleaseNotes 'Mock release notes.'

# Should publish the script 'TestScript' with the tags 'Tag1', 'Tag2', 'Tag3'
Publish-PSResource 'TestScript' -Tags 'Tag1', 'Tag2', 'Tag3'

# Should publish the script 'TestScript' with a specified license uri
Publish-PSResource 'TestScript' -LicenseUri 'www.licenseuri.com'

# Should publish the script 'TestScript' with a specified icon uri
Publish-PSResource 'TestScript' -IconUri 'www.iconuri.com'

# Should publish the script 'TestScript' with a specified projected uri
Publish-PSResource 'TestScript' -ProjectUri 'www.projecturi.com'

# Should publish the script 'TestScript' without asking for user confirmation
Publish-PSResource 'TestScript' -Force

# Should publish the script 'TestScript' without checking that all dependencies are present
Publish-PSResource 'TestScript' -SkipDependenciesCheck

# Should publish the script 'TestScript' with a specified nuspec file
Publish-PSResource 'TestScript' -Nuspec '\path\to\file.nuspec'
