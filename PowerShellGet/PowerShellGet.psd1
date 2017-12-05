@{
RootModule = 'PSModule.psm1'
ModuleVersion = '1.6.0'
GUID = '1d73a601-4a6c-43c5-ba3f-619b18bbb404'
Author = 'Microsoft Corporation'
CompanyName = 'Microsoft Corporation'
Copyright = '(c) Microsoft Corporation. All rights reserved.'
Description = 'PowerShell module with commands for discovering, installing, updating and publishing the PowerShell artifacts like Modules, DSC Resources, Role Capabilities and Scripts.'
PowerShellVersion = '3.0'
FormatsToProcess = 'PSGet.Format.ps1xml'
FunctionsToExport = @('Install-Module',
                      'Find-Module',
                      'Save-Module',
                      'Update-Module',
                      'Publish-Module',
                      'Get-InstalledModule',
                      'Uninstall-Module',
                      'Find-Command',
                      'Find-DscResource',
                      'Find-RoleCapability',
                      'Install-Script',
                      'Find-Script',
                      'Save-Script',
                      'Update-Script',
                      'Publish-Script',
                      'Get-InstalledScript',
                      'Uninstall-Script',
                      'Test-ScriptFileInfo',
                      'New-ScriptFileInfo',
                      'Update-ScriptFileInfo',
                      'Get-PSRepository',
                      'Set-PSRepository',
                      'Register-PSRepository',
                      'Unregister-PSRepository',
                      'Update-ModuleManifest')
VariablesToExport = "*"
AliasesToExport = @('inmo',
                    'fimo',
                    'upmo',
                    'pumo')
FileList = @('PSModule.psm1',
             'PSGet.Format.ps1xml',
             'PSGet.Resource.psd1')
RequiredModules = @(@{ModuleName='PackageManagement';ModuleVersion='1.1.7.0'})
PrivateData = @{
                "PackageManagementProviders" = 'PSModule.psm1'
                 "SupportedPowerShellGetFormatVersions" = @('1.x','2.x')
    PSData = @{
        Tags = @('Packagemanagement',
                 'Provider',
                 'PSEdition_Desktop',
                 'PSEdition_Core',
                 'Linux',
                 'Mac')
        ProjectUri = 'https://go.microsoft.com/fwlink/?LinkId=828955'
        LicenseUri = 'https://go.microsoft.com/fwlink/?LinkId=829061'
        ReleaseNotes = @'
## 1.6.0
        
New features
* Prerelease Version Support (#185)
  - Implemented prerelease versions functionality in PowerShellGet cmdlets.
  - Enables publishing, discovering, and installing the prerelease versions of modules and scripts from the PowerShell Gallery.
  - [Documentation](https://docs.microsoft.com/en-us/powershell/gallery/psget/module/PrereleaseModule)

* Enabled publish cmdlets on PWSH and Nano Server (#196)
  - Dotnet command version 2.0.0 or newer should be installed by the user prior to using the publish cmdlets on PWSH and Windows Nano Server.
  - Users can install the dotnet command by following the instructions specified at https://aka.ms/dotnet-install-script.
  - On Windows, users can install the dotnet command by running *Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile '.\dotnet-install.ps1'; & '.\dotnet-install.ps1' -Channel Current -Version '2.0.0'*
  - Publish cmdlets on Windows PowerShell supports using the dotnet command for publishing operations.

Breaking Change
- PWSH: Changed the installation location of AllUsers scope to the parent of $PSHOME instead of $PSHOME. It is the SHARED_MODULES folder on PWSH.

Bug fixes
- Update HelpInfoURI to 'https://go.microsoft.com/fwlink/?linkid=855963' (#195)
- Ensure MyDocumentsPSPath path is correct (#179) (Thanks @lwsrbrts)


## 1.5.0.0

New features
* Added support for modules requiring license acceptance (#150)
  - [Documentation](https://docs.microsoft.com/en-us/powershell/gallery/psget/module/RequireLicenseAcceptance)

* Added version for REQUIREDSCRIPTS (#162)
  - Enabled following scenarios for REQUIREDSCRIPTS
    - [1.0] - RequiredVersion
    - [1.0,2.0] - Min and Max Version
    - (,1.0] - Max Version
    - 1.0 - Min Version

Bug fixes
* Fixed empty version value in nuspec (#157)


## 1.1.3.2
* Disabled PowerShellGet Telemetry on PS Core as PowerShell Telemetry APIs got removed in PowerShell Core beta builds. (#153)
* Fixed for DateTime format serialization issue. (#141)
* Update-ModuleManifest should add ExternalModuleDependencies value as a collection. (#129)

## 1.1.3.1

New features
* Added `PrivateData` field to ScriptFileInfo. (#119)

Bug fixes
* Fixed Add-Type issue in v6.0.0-beta.1 release of PowerShellCore. (#125, #124)
* Install-Script -Scope CurrentUser PATH changes should not require a reboot for new PS processes. (#124)
    - Made changes to broadcast the Environment variable changes, so that other processes pick changes to Environment variables without having to reboot or logoff/logon.
* Changed `Get-EnvironmentVariable` to get the unexpanded version of `%path%`. (#117)
* Refactor credential parameter propagation to sub-functions. (#104)
* Added credential parameter to subsequent calls of `Publish-Module/Script`. (#93)
    - This is needed when a module is published that has the RequiredModules attribute in the manifest on a repository that does not have anonymous access because the required module lookups will fail.

## 1.1.2.0

Bug fixes
* Renamed `PublishModuleIsNotSupportedOnNanoServer` errorid to `PublishModuleIsNotSupportedOnPowerShellCoreEdition`. (#44)
    - Also renamed `PublishScriptIsNotSupportedOnNanoServer` to `PublishScriptIsNotSupportedOnPowerShellCoreEdition`.
* Fixed an issue in `Update-Module` and `Update-Script` cmdlets to show proper version of current item being updated in `Confirm`/`WhatIf` message. (#44)
* Updated `Test-ModuleInstalled` function to return single module instead of multiple modules. (#44)
* Updated `ModuleCommandAlreadyAvailable` error message to include all conflicting commands instead of one.  (#44)
    - Corresponding changes to collect the complete set of conflicting commands from the being installed.
    - Also ensured that conflicting commands from PSModule.psm1 are ignored in the command collision analysis as Get-Command includes the commands from current local scope as well.

* Fixed '[Test-ScriptFileInfo] Fails on *NIX newlines (LF vs. CRLF)' (#18)


## 1.1.1.0

Bug fixes
* Fixed 'Update-Module fails with `ModuleAuthenticodeSignature` error for modules with signed PSD1'. (#12) (#8)
* Fixed 'Properties of `AdditionalMetadata` are case-sensitive'. #7
* Changed `ErrorAction` to `Ignore` for few cmdlet usages as they should not show up in ErrorVariable.
    - For example, error returned by `Get-Command Test-FileCatalog` should be ignored.


## 1.1.0.0

* Initial release from GitHub.
* PowerShellCore support.
* Security enhancements including the enforcement of catalog-signed modules during installation.
* Authenticated Repository support.
* Proxy Authentication support.
* Responses to a number of user requests and issues.
'@
    }
}

HelpInfoURI = 'https://go.microsoft.com/fwlink/?linkid=855963'
}
