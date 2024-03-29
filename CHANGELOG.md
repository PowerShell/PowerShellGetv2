# Changelog
### 2.2.5.1
- Improved error handling for Register-PSRepository
- Improved handling of Azure DeVOps urls (#672 Thanks @sebastianrogers!)
- Improved handling of publishing with non en-US locale (#613 Thanks @glatzert!)
- Tab completion for -Name parameter in Set-PSRepository (#603 Thanks @bergmeister!)
- Updated PSGet reference links (#589 Thanks @srjennings!)

### 2.2.5
- Security patch for code injection bug

### 2.2.4.1
- Remove catalog file

### 2.2.4
- Enforce a security protocol of TLS 1.2 when interacting with online repositories (#598)

### 2.2.3

- Update `HelpInfoUri` to point to the latest content (#560)
- Improve discovery of usable nuget.exe binary (Thanks bwright86!) (#558)

### 2.2.2

Bug Fix

- Update casing of DscResources output

### 2.2.1

Bug Fix

- Allow DscResources to work on case sensitive platforms (#521)
- Fix for failure to return credential provider when using private feeds (#521)

## 2.2

Bug Fix

- Fix for prompting for credentials when passing in -Credential parameter when using Register-PSRepository

## 2.1.5

New Features

- Add and remove nuget based repositories as a nuget source when nuget client tool is installed (#498)

Bug Fix

- Fix for 'Failed to publish module' error thrown when publishing modules (#497)

## 2.1.4

Bug Fix

- Fixed hang when publishing some modules (#478)

## 2.1.3

New Features

- Added -Scope parameter to Update-Module (Thanks @lwajswaj!) (#471)
- Added -Exclude parameter to Publish-Module (Thanks @Benny1007!) (#191)
- Added -SkipAutomticTags parameter to Publish-Module (Thanks @awickham10!) (#452)

Bug Fix

- Fixed issue with finding modules using macOS and .NET Core 3.0

## 2.1.2

New Feature

- Added support for registering repositories with special characters (@Thanks jborean93!) (#442)

## 2.1.1

- Fix DSC resource folder structure

## 2.1.0

Breaking Change

- Default installation scope for Update-Module and Update-Script has changed to match Install-Module and Install-Script. For Windows PowerShell (version 5.1 or below), the default scope is AllUsers when running in an elevated session, and CurrentUser at all other times.
  For PowerShell version 6.0.0 and above, the default installation scope is always CurrentUser. (#421)

Bug Fixes

- Update-ModuleManifest no longer clears FunctionsToExport, AliasesToExport, nor NestModules (#415 & #425) (Thanks @pougetat and @tnieto88!)
- Update-Module no longer changes repository URL (#407)
- Update-ModuleManifest no longer preprends 'PSGet_' to module name (#403) (Thanks @ThePoShWolf)
- Update-ModuleManifest now throws error and fails to update when provided invalid entries (#398) (Thanks @pougetat!)
- Ignore files no longer being included when uploading modules (#396)

New Features

- New DSC resource, PSRepository (#426) (Thanks @johlju!)
- Added tests and integration of DSC resource PSModule (Thanks @johlju!)
- Piping of PS respositories (#420)
- utf8 support for .nuspec (#419)

## 2.0.4

Bug Fix

- Remove PSGallery availability checks (#374)

## 2.0.3

Bug fixes and Improvements

- Fix CommandAlreadyAvailable error for PackageManagement module (#333)
- Remove trailing whitespace when value is not provided for Get-PSScriptInfoString (#337) (Thanks @thomasrayner)
- Expanded aliases for improved readability (#338) (Thanks @lazywinadmin)
- Improvements for Catalog tests (#343)
- Fix Update-ScriptInfoFile to preserve PrivateData (#346) (Thanks @tnieto88)
- Install modules with many commands faster (#351)

New Features

- Tab completion for -Repository parameter (#339) and for Publish-Module -Name (#359) (Thanks @matt9ucci)

## 2.0.1

Bug fixes

- Resolved Publish-Module doesn't report error but fails to publish module (#316)
- Resolved CommandAlreadyAvailable error while installing the latest version of PackageManagement module (#333)

## 2.0.0

Breaking Change

- Default installation scope for Install-Module, Install-Script, and Install-Package has changed. For Windows PowerShell (version 5.1 or below), the default scope is AllUsers when running in an elevated session, and CurrentUser at all other times.
  For PowerShell version 6.0.0 and above, the default installation scope is always CurrentUser.

## 1.6.7

Bug fixes

- Resolved Install/Save-Module error in PSCore 6.1.0-preview.4 on Ubuntu 18.04 OS (WSL/Azure) (#313)
- Updated error message in Save-Module cmdlet when the specified path is not accessible (#313)
- Added few additional verbose messages (#313)

## 1.6.6

Dependency Updates

- Add dependency on version 4.1.0 or newer of NuGet.exe
- Update NuGet.exe bootstrap URL to https://aka.ms/psget-nugetexe

Build and Code Cleanup Improvements

- Improved error handling in network connectivity tests.

Bug fixes

- Change Update ModuleManifest so that prefix is not added to CmdletsToExport.
- Change Update ModuleManifest so that parameters will not reset to default values.
- Specify AllowPrereleaseVersions provider option only when AllowPrerelease is specified on the PowerShellGet cmdlets.

## 1.6.5

New features

- Allow Pester/PSReadline installation when signed by non-Microsoft certificate (#258)
  - Allowlist installation of non-Microsoft signed Pester and PSReadline over Microsoft signed Pester and PSReadline.

Build and Code Cleanup Improvements

- Splitting of functions (#229) (Thanks @Benny1007)
  - Moves private functions into respective private folder.
  - Moves public functions as defined in PSModule.psd1 into respective public folder.
  - Removes all functions from PSModule.psm1 file.
  - Dot sources the functions from PSModule.psm1 file.
  - Uses Export-ModuleMember to export the public functions from PSModule.psm1 file.

- Add build step to construct a single .psm1 file (#242) (Thanks @Benny1007)
  - Merged public and private functions into one .psm1 file to increase load time performance.

Bug fixes

- Fix null parameter error caused by MinimumVersion in Publish-PackageUtility (#201)
- Change .ExternalHelp link from PSGet.psm1-help.xml to PSModule-help.xml in PSModule.psm1 file (#215)
- Change Publish-* to allow version comparison instead of string comparison (#219)
- Ensure Get-InstalledScript -RequiredVersion works when versions have a leading 0 (#260)
- Add positional path to Save-Module and Save-Script (#264, #266)
- Ensure that Get-AuthenticodePublisher verifies publisher and that installing or updating a module checks for approprite catalog signature (#272)
- Update HelpInfoURI to 'http://go.microsoft.com/fwlink/?linkid=855963' (#274)

## 1.6.0

New features

- Prerelease Version Support (#185)
  - Implemented prerelease versions functionality in PowerShellGet cmdlets.
  - Enables publishing, discovering, and installing the prerelease versions of modules and scripts from the PowerShell Gallery.
  - [Documentation](https://docs.microsoft.com/en-us/powershell/gallery/psget/module/PrereleaseModule)

- Enabled publish cmdlets on PWSH and Nano Server (#196)
  - Dotnet command version 2.0.0 or newer should be installed by the user prior to using the publish cmdlets on PWSH and Windows Nano Server.
  - Users can install the dotnet command by following the instructions specified at https://aka.ms/dotnet-install-script .
  - On Windows, users can install the dotnet command by running *Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile '.\dotnet-install.ps1'; & '.\dotnet-install.ps1' -Channel Current -Version '2.0.0'*
  - Publish cmdlets on Windows PowerShell supports using the dotnet command for publishing operations.

Breaking Change

- PWSH: Changed the installation location of AllUsers scope to the parent of $PSHOME instead of $PSHOME. It is the SHARED_MODULES folder on PWSH.

Bug fixes

- Update HelpInfoURI to 'https://go.microsoft.com/fwlink/?linkid=855963' (#195)
- Ensure MyDocumentsPSPath path is correct (#179) (Thanks @lwsrbrts)

## 1.5.0.0

New features

- Added support for modules requiring license acceptance (#150)
  - [Documentation](https://docs.microsoft.com/en-us/powershell/gallery/psget/module/RequireLicenseAcceptance)

- Added version for REQUIREDSCRIPTS (#162)
  - Enabled following scenarios for REQUIREDSCRIPTS
    - [1.0] - RequiredVersion
    - [1.0,2.0] - Min and Max Version
    - (,1.0] - Max Version
    - 1.0 - Min Version

Bug fixes

- Fixed empty version value in nuspec (#157)

## 1.1.3.2

- Disabled PowerShellGet Telemetry on PS Core as PowerShell Telemetry APIs got removed in PowerShell Core beta builds. (#153)
- Fixed for DateTime format serialization issue. (#141)
- Update-ModuleManifest should add ExternalModuleDependencies value as a collection. (#129)

## 1.1.3.1

New features

- Added `PrivateData` field to ScriptFileInfo. (#119)

Bug fixes

- Fixed Add-Type issue in v6.0.0-beta.1 release of PowerShellCore. (#125, #124)
- Install-Script -Scope CurrentUser PATH changes should not require a reboot for new PS processes. (#124)
  - Made changes to broadcast the Environment variable changes, so that other processes pick changes to Environment variables without having to reboot or logoff/logon.
- Changed `Get-EnvironmentVariable` to get the unexpanded version of `%path%`. (#117)
- Refactor credential parameter propagation to sub-functions. (#104)
- Added credential parameter to subsequent calls of `Publish-Module/Script`. (#93)
  - This is needed when a module is published that has the RequiredModules attribute in the manifest on a repository that does not have anonymous access because the required module lookups will fail.

## 1.1.2.0

Bug fixes

- Renamed `PublishModuleIsNotSupportedOnNanoServer` errorid to `PublishModuleIsNotSupportedOnPowerShellCoreEdition`. (#44)
  - Also renamed `PublishScriptIsNotSupportedOnNanoServer` to `PublishScriptIsNotSupportedOnPowerShellCoreEdition`.
- Fixed an issue in `Update-Module` and `Update-Script` cmdlets to show proper version of current item being updated in `Confirm`/`WhatIf` message. (#44)
- Updated `Test-ModuleInstalled` function to return single module instead of multiple modules. (#44)
- Updated `ModuleCommandAlreadyAvailable` error message to include all conflicting commands instead of one.  (#44)
  - Corresponding changes to collect the complete set of conflicting commands from the being installed.
  - Also ensured that conflicting commands from PSModule.psm1 are ignored in the command collision analysis as Get-Command includes the commands from current local scope as well.

- Fixed '[Test-ScriptFileInfo] Fails on *NIX newlines (LF vs. CRLF)' (#18)

## 1.1.1.0

Bug fixes

- Fixed 'Update-Module fails with `ModuleAuthenticodeSignature` error for modules with signed PSD1'. (#12) (#8)
- Fixed 'Properties of `AdditionalMetadata` are case-sensitive'. #7
- Changed `ErrorAction` to `Ignore` for few cmdlet usages as they should not show up in ErrorVariable.
  - For example, error returned by `Get-Command Test-FileCatalog` should be ignored.

## 1.1.0.0

- Initial release from GitHub.
- PowerShellCore support.
- Security enhancements including the enforcement of catalog-signed modules during installation.
- Authenticated Repository support.
- Proxy Authentication support.
- Responses to a number of user requests and issues.
