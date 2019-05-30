
#########################################################################################
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# PowerShellGet Module
#
#########################################################################################

Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

#region script variables

$script:IsInbox = $PSHOME.EndsWith('\WindowsPowerShell\v1.0', [System.StringComparison]::OrdinalIgnoreCase)
$script:IsWindows = (-not (Get-Variable -Name IsWindows -ErrorAction Ignore)) -or $IsWindows
$script:IsLinux = (Get-Variable -Name IsLinux -ErrorAction Ignore) -and $IsLinux
$script:IsMacOS = (Get-Variable -Name IsMacOS -ErrorAction Ignore) -and $IsMacOS
$script:IsCoreCLR = $PSVersionTable.ContainsKey('PSEdition') -and $PSVersionTable.PSEdition -eq 'Core'
$script:IsNanoServer = & {
    if (!$script:IsWindows) {
        return $false
    }

    $serverLevelsPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Server\ServerLevels\'
    if (Test-Path -Path $serverLevelsPath) {
        $NanoItem = Get-ItemProperty -Name NanoServer -Path $serverLevelsPath -ErrorAction Ignore
        if ($NanoItem -and ($NanoItem.NanoServer -eq 1)) {
            return $true
        }
    }
    return $false
}

if ($script:IsInbox) {
    $script:ProgramFilesPSPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell"
}
elseif ($script:IsCoreCLR) {
    if ($script:IsWindows) {
        $script:ProgramFilesPSPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath 'PowerShell'
    }
    else {
        $script:ProgramFilesPSPath = Microsoft.PowerShell.Management\Split-Path -Path ([System.Management.Automation.Platform]::SelectProductNameForDirectory('SHARED_MODULES')) -Parent
    }
}

try {
    $script:MyDocumentsFolderPath = [Environment]::GetFolderPath("MyDocuments")
}
catch {
    $script:MyDocumentsFolderPath = $null
}

if ($script:IsInbox) {
    $script:MyDocumentsPSPath = if ($script:MyDocumentsFolderPath) {
        Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsFolderPath -ChildPath "WindowsPowerShell"
    }
    else {
        Microsoft.PowerShell.Management\Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell"
    }
}
elseif ($script:IsCoreCLR) {
    if ($script:IsWindows) {
        $script:MyDocumentsPSPath = if ($script:MyDocumentsFolderPath) {
            Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsFolderPath -ChildPath 'PowerShell'
        }
        else {
            Microsoft.PowerShell.Management\Join-Path -Path $HOME -ChildPath "Documents\PowerShell"
        }
    }
    else {
        $script:MyDocumentsPSPath = Microsoft.PowerShell.Management\Split-Path -Path ([System.Management.Automation.Platform]::SelectProductNameForDirectory('USER_MODULES')) -Parent
    }
}

$script:ProgramFilesModulesPath = Microsoft.PowerShell.Management\Join-Path -Path $script:ProgramFilesPSPath -ChildPath 'Modules'
$script:MyDocumentsModulesPath = Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsPSPath -ChildPath 'Modules'

$script:ProgramFilesScriptsPath = Microsoft.PowerShell.Management\Join-Path -Path $script:ProgramFilesPSPath -ChildPath 'Scripts'
$script:MyDocumentsScriptsPath = Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsPSPath -ChildPath 'Scripts'

$script:PSGetPath = [pscustomobject]@{
    AllUsersModules    = $script:ProgramFilesModulesPath
    AllUsersScripts    = $script:ProgramFilesScriptsPath
    CurrentUserModules = $script:MyDocumentsModulesPath
    CurrentUserScripts = $script:MyDocumentsScriptsPath
    PSTypeName         = 'Microsoft.PowerShell.Commands.PSGetPath'
}

$script:TempPath = [System.IO.Path]::GetTempPath()
$script:PSGetItemInfoFileName = "PSGetModuleInfo.xml"

if ($script:IsWindows) {
    $script:PSGetProgramDataPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
    $script:PSGetAppLocalPath = Microsoft.PowerShell.Management\Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
}
else {
    $script:PSGetProgramDataPath = Microsoft.PowerShell.Management\Join-Path -Path ([System.Management.Automation.Platform]::SelectProductNameForDirectory('CONFIG')) -ChildPath 'PowerShellGet'
    $script:PSGetAppLocalPath = Microsoft.PowerShell.Management\Join-Path -Path ([System.Management.Automation.Platform]::SelectProductNameForDirectory('CACHE')) -ChildPath 'PowerShellGet'
}

$script:PSGetModuleSourcesFilePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetAppLocalPath -ChildPath "PSRepositories.xml"
$script:PSGetModuleSources = $null
$script:PSGetInstalledModules = $null
$script:PSGetSettingsFilePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetAppLocalPath -ChildPath "PowerShellGetSettings.xml"
$script:PSGetSettings = $null

$script:MyDocumentsInstalledScriptInfosPath = Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsScriptsPath -ChildPath 'InstalledScriptInfos'
$script:ProgramFilesInstalledScriptInfosPath = Microsoft.PowerShell.Management\Join-Path -Path $script:ProgramFilesScriptsPath -ChildPath 'InstalledScriptInfos'

$script:IsRunningAsElevated = $true
$script:IsRunningAsElevatedTested = $false

$script:InstalledScriptInfoFileName = 'InstalledScriptInfo.xml'
$script:PSGetInstalledScripts = $null

# Public PSGallery module source name and location
$Script:PSGalleryModuleSource = "PSGallery"
$Script:PSGallerySourceUri = 'https://www.powershellgallery.com/api/v2'
$Script:PSGalleryPublishUri = 'https://www.powershellgallery.com/api/v2/package/'
$Script:PSGalleryScriptSourceUri = 'https://www.powershellgallery.com/api/v2/items/psscript'

# PSGallery V3 Source
$Script:PSGalleryV3SourceUri = 'https://www.powershellgallery.com/api/v3'

$Script:ResponseUri = "ResponseUri"
$Script:StatusCode = "StatusCode"
$Script:Exception = "Exception"

$script:PSModuleProviderName = 'PowerShellGet'
$script:PackageManagementProviderParam = "PackageManagementProvider"
$script:PublishLocation = "PublishLocation"
$script:ScriptSourceLocation = 'ScriptSourceLocation'
$script:ScriptPublishLocation = 'ScriptPublishLocation'
$script:Proxy = 'Proxy'
$script:ProxyCredential = 'ProxyCredential'
$script:Credential = 'Credential'
$script:VSTSAuthenticatedFeedsDocUrl = 'https://go.microsoft.com/fwlink/?LinkID=698608'
$script:Prerelease = "Prerelease"

$script:NuGetProviderName = "NuGet"
$script:NuGetProviderVersion = [Version]'2.8.5.201'

$script:SupportsPSModulesFeatureName = "supports-powershell-modules"
$script:FastPackRefHashtable = @{ }
$script:NuGetBinaryProgramDataPath = if ($script:IsWindows) { "$env:ProgramFiles\PackageManagement\ProviderAssemblies" }
$script:NuGetBinaryLocalAppDataPath = if ($script:IsWindows) { "$env:LOCALAPPDATA\PackageManagement\ProviderAssemblies" }
# go fwlink for 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe'
$script:NuGetClientSourceURL = 'https://aka.ms/psget-nugetexe'
$script:NuGetExeMinRequiredVersion = [Version]'4.1.0'
$script:NuGetExeName = 'NuGet.exe'
$script:NuGetExePath = $null
$script:NuGetExeVersion = $null
$script:NuGetProvider = $null
$script:DotnetCommandName = 'dotnet'
$script:MinimumDotnetCommandVersion = [Version]'2.0.0'
$script:DotnetInstallUrl = 'https://aka.ms/dotnet-install-script'
$script:DotnetCommandPath = $null
# PowerShellGetFormatVersion will be incremented when we change the .nupkg format structure.
# PowerShellGetFormatVersion is in the form of Major.Minor.
# Minor is incremented for the backward compatible format change.
# Major is incremented for the breaking change.
$script:PSGetRequireLicenseAcceptanceFormatVersion = [Version]'2.0'
$script:CurrentPSGetFormatVersion = $script:PSGetRequireLicenseAcceptanceFormatVersion
$script:PSGetFormatVersion = "PowerShellGetFormatVersion"
$script:SupportedPSGetFormatVersionMajors = @("1", "2")
$script:ModuleReferences = 'Module References'
$script:AllVersions = "AllVersions"
$script:AllowPrereleaseVersions = "AllowPrereleaseVersions"
$script:Filter = "Filter"
$script:IncludeValidSet = @('DscResource', 'Cmdlet', 'Function', 'Workflow', 'RoleCapability')
$script:DscResource = "PSDscResource"
$script:Command = "PSCommand"
$script:Cmdlet = "PSCmdlet"
$script:Function = "PSFunction"
$script:Workflow = "PSWorkflow"
$script:RoleCapability = 'PSRoleCapability'
$script:Includes = "PSIncludes"
$script:Tag = "Tag"
$script:NotSpecified = '_NotSpecified_'
$script:PSGetModuleName = 'PowerShellGet'
$script:FindByCanonicalId = 'FindByCanonicalId'
$script:InstalledLocation = 'InstalledLocation'
$script:PSArtifactType = 'Type'
$script:PSArtifactTypeModule = 'Module'
$script:PSArtifactTypeScript = 'Script'
$script:All = 'All'

$script:Name = 'Name'
$script:Version = 'Version'
$script:Guid = 'Guid'
$script:Path = 'Path'
$script:ScriptBase = 'ScriptBase'
$script:Description = 'Description'
$script:Author = 'Author'
$script:CompanyName = 'CompanyName'
$script:Copyright = 'Copyright'
$script:Tags = 'Tags'
$script:LicenseUri = 'LicenseUri'
$script:ProjectUri = 'ProjectUri'
$script:IconUri = 'IconUri'
$script:RequiredModules = 'RequiredModules'
$script:ExternalModuleDependencies = 'ExternalModuleDependencies'
$script:ReleaseNotes = 'ReleaseNotes'
$script:RequiredScripts = 'RequiredScripts'
$script:ExternalScriptDependencies = 'ExternalScriptDependencies'
$script:DefinedCommands = 'DefinedCommands'
$script:DefinedFunctions = 'DefinedFunctions'
$script:DefinedWorkflows = 'DefinedWorkflows'
$script:TextInfo = (Get-Culture).TextInfo
$script:PrivateData = 'PrivateData'

$script:PSScriptInfoProperties = @($script:Name
    $script:Version,
    $script:Guid,
    $script:Path,
    $script:ScriptBase,
    $script:Description,
    $script:Author,
    $script:CompanyName,
    $script:Copyright,
    $script:Tags,
    $script:ReleaseNotes,
    $script:RequiredModules,
    $script:ExternalModuleDependencies,
    $script:RequiredScripts,
    $script:ExternalScriptDependencies,
    $script:LicenseUri,
    $script:ProjectUri,
    $script:IconUri,
    $script:DefinedCommands,
    $script:DefinedFunctions,
    $script:DefinedWorkflows,
    $script:PrivateData
)

$script:SystemEnvironmentKey = 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment'
$script:UserEnvironmentKey = 'HKCU:\Environment'
$script:SystemEnvironmentVariableMaximumLength = 1024
$script:UserEnvironmentVariableMaximumLength = 255
$script:EnvironmentVariableTarget = @{ Process = 0; User = 1; Machine = 2 }

# Wildcard pattern matching configuration.
$script:wildcardOptions = [System.Management.Automation.WildcardOptions]::CultureInvariant -bor `
    [System.Management.Automation.WildcardOptions]::IgnoreCase

$script:DynamicOptionTypeMap = @{
    0 = [string]; # String
    1 = [string[]]; # StringArray
    2 = [int]; # Int
    3 = [switch]; # Switch
    4 = [string]; # Folder
    5 = [string]; # File
    6 = [string]; # Path
    7 = [Uri]; # Uri
    8 = [SecureString]; #SecureString
}
#endregion script variables

#region Module message resolvers
$script:PackageManagementMessageResolverScriptBlock = {
    param($i, $Message)
    return (PackageManagementMessageResolver -MsgId $i, -Message $Message)
}

$script:PackageManagementSaveModuleMessageResolverScriptBlock = {
    param($i, $Message)
    $PackageTarget = $LocalizedData.InstallModulewhatIfMessage
    $QuerySaveUntrustedPackage = $LocalizedData.QuerySaveUntrustedPackage

    switch ($i) {
        'ActionInstallPackage' { return "Save-Module" }
        'QueryInstallUntrustedPackage' { return $QuerySaveUntrustedPackage }
        'TargetPackage' { return $PackageTarget }
        Default {
            $Message = $Message -creplace "Install", "Download"
            $Message = $Message -creplace "install", "download"
            return (PackageManagementMessageResolver -MsgId $i, -Message $Message)
        }
    }
}

$script:PackageManagementInstallModuleMessageResolverScriptBlock = {
    param($i, $Message)
    $PackageTarget = $LocalizedData.InstallModulewhatIfMessage

    switch ($i) {
        'ActionInstallPackage' { return "Install-Module" }
        'TargetPackage' { return $PackageTarget }
        Default {
            return (PackageManagementMessageResolver -MsgId $i, -Message $Message)
        }
    }
}

$script:PackageManagementUnInstallModuleMessageResolverScriptBlock = {
    param($i, $Message)
    $PackageTarget = $LocalizedData.InstallModulewhatIfMessage
    switch ($i) {
        'ActionUninstallPackage' { return "Uninstall-Module" }
        'TargetPackageVersion' { return $PackageTarget }
        Default {
            return (PackageManagementMessageResolver -MsgId $i, -Message $Message)
        }
    }
}

$script:PackageManagementUpdateModuleMessageResolverScriptBlock = {
    param($i, $Message)
    $PackageTarget = ($LocalizedData.UpdateModulewhatIfMessage -replace "__OLDVERSION__", $($psgetItemInfo.Version))
    switch ($i) {
        'ActionInstallPackage' { return "Update-Module" }
        'TargetPackage' { return $PackageTarget }
        Default {
            return (PackageManagementMessageResolver -MsgId $i, -Message $Message)
        }
    }
}

# Modules allowed to install non-Microsoft signed modules over Microsoft signed modules
$script:WhitelistedModules = @{
    "Pester"     = $true
    "PSReadline" = $true
}

function PackageManagementMessageResolver($MsgID, $Message) {
    $NoMatchFound = $LocalizedData.NoMatchFound
    $SourceNotFound = $LocalizedData.SourceNotFound
    $ModuleIsNotTrusted = $LocalizedData.ModuleIsNotTrusted
    $RepositoryIsNotTrusted = $LocalizedData.RepositoryIsNotTrusted
    $QueryInstallUntrustedPackage = $LocalizedData.QueryInstallUntrustedPackage

    switch ($MsgID) {
        'NoMatchFound' { return $NoMatchFound }
        'SourceNotFound' { return $SourceNotFound }
        'CaptionPackageNotTrusted' { return $ModuleIsNotTrusted }
        'CaptionSourceNotTrusted' { return $RepositoryIsNotTrusted }
        'QueryInstallUntrustedPackage' { return $QueryInstallUntrustedPackage }
        Default {
            if ($Message) {
                $tempMessage = $Message -creplace "PackageSource", "PSRepository"
                $tempMessage = $tempMessage -creplace "packagesource", "psrepository"
                $tempMessage = $tempMessage -creplace "Package", "Module"
                $tempMessage = $tempMessage -creplace "package", "module"
                $tempMessage = $tempMessage -creplace "Sources", "Repositories"
                $tempMessage = $tempMessage -creplace "sources", "repositories"
                $tempMessage = $tempMessage -creplace "Source", "Repository"
                $tempMessage = $tempMessage -creplace "source", "repository"

                return $tempMessage
            }
        }
    }
}

#endregion Module message resolvers

#region Script message resolvers
$script:PackageManagementMessageResolverScriptBlockForScriptCmdlets = {
    param($i, $Message)
    return (PackageManagementMessageResolverForScripts -MsgId $i, -Message $Message)
}

$script:PackageManagementSaveScriptMessageResolverScriptBlock = {
    param($i, $Message)
    $PackageTarget = $LocalizedData.InstallScriptwhatIfMessage
    $QuerySaveUntrustedPackage = $LocalizedData.QuerySaveUntrustedScriptPackage

    switch ($i) {
        'ActionInstallPackage' { return "Save-Script" }
        'QueryInstallUntrustedPackage' { return $QuerySaveUntrustedPackage }
        'TargetPackage' { return $PackageTarget }
        Default {
            $Message = $Message -creplace "Install", "Download"
            $Message = $Message -creplace "install", "download"
            return (PackageManagementMessageResolverForScripts -MsgId $i, -Message $Message)
        }
    }
}

$script:PackageManagementInstallScriptMessageResolverScriptBlock = {
    param($i, $Message)
    $PackageTarget = $LocalizedData.InstallScriptwhatIfMessage

    switch ($i) {
        'ActionInstallPackage' { return "Install-Script" }
        'TargetPackage' { return $PackageTarget }
        Default {
            return (PackageManagementMessageResolverForScripts -MsgId $i, -Message $Message)
        }
    }
}

$script:PackageManagementUnInstallScriptMessageResolverScriptBlock = {
    param($i, $Message)
    $PackageTarget = $LocalizedData.InstallScriptwhatIfMessage
    switch ($i) {
        'ActionUninstallPackage' { return "Uninstall-Script" }
        'TargetPackageVersion' { return $PackageTarget }
        Default {
            return (PackageManagementMessageResolverForScripts -MsgId $i, -Message $Message)
        }
    }
}

$script:PackageManagementUpdateScriptMessageResolverScriptBlock = {
    param($i, $Message)
    $PackageTarget = ($LocalizedData.UpdateScriptwhatIfMessage -replace "__OLDVERSION__", $($psgetItemInfo.Version))
    switch ($i) {
        'ActionInstallPackage' { return "Update-Script" }
        'TargetPackage' { return $PackageTarget }
        Default {
            return (PackageManagementMessageResolverForScripts -MsgId $i, -Message $Message)
        }
    }
}

function PackageManagementMessageResolverForScripts($MsgID, $Message) {
    $NoMatchFound = $LocalizedData.NoMatchFoundForScriptName
    $SourceNotFound = $LocalizedData.SourceNotFound
    $ScriptIsNotTrusted = $LocalizedData.ScriptIsNotTrusted
    $RepositoryIsNotTrusted = $LocalizedData.RepositoryIsNotTrusted
    $QueryInstallUntrustedPackage = $LocalizedData.QueryInstallUntrustedScriptPackage

    switch ($MsgID) {
        'NoMatchFound' { return $NoMatchFound }
        'SourceNotFound' { return $SourceNotFound }
        'CaptionPackageNotTrusted' { return $ScriptIsNotTrusted }
        'CaptionSourceNotTrusted' { return $RepositoryIsNotTrusted }
        'QueryInstallUntrustedPackage' { return $QueryInstallUntrustedPackage }
        Default {
            if ($Message) {
                $tempMessage = $Message -creplace "PackageSource", "PSRepository"
                $tempMessage = $tempMessage -creplace "packagesource", "psrepository"
                $tempMessage = $tempMessage -creplace "Package", "Script"
                $tempMessage = $tempMessage -creplace "package", "script"
                $tempMessage = $tempMessage -creplace "Sources", "Repositories"
                $tempMessage = $tempMessage -creplace "sources", "repositories"
                $tempMessage = $tempMessage -creplace "Source", "Repository"
                $tempMessage = $tempMessage -creplace "source", "repository"

                return $tempMessage
            }
        }
    }
}

#endregion Script message resolvers

#region Add .Net type for Telemetry APIs and WebProxy

# Check and add InternalWebProxy type
if ( -not ('Microsoft.PowerShell.Commands.PowerShellGet.InternalWebProxy' -as [Type])) {
    $RequiredAssembliesForInternalWebProxy = @(
        [System.Net.IWebProxy].Assembly.FullName,
        [System.Uri].Assembly.FullName
    )

    $InternalWebProxySource = @'
using System;
using System.Net;

namespace Microsoft.PowerShell.Commands.PowerShellGet
{
    /// <summary>
    /// Used by Ping-Endpoint function to supply webproxy to HttpClient
    /// We cannot use System.Net.WebProxy because this is not available on CoreClr
    /// </summary>
    public class InternalWebProxy : IWebProxy
    {
        Uri _proxyUri;
        ICredentials _credentials;

        public InternalWebProxy(Uri uri, ICredentials credentials)
        {
            Credentials = credentials;
            _proxyUri = uri;
        }

        /// <summary>
        /// Credentials used by WebProxy
        /// </summary>
        public ICredentials Credentials
        {
            get
            {
                return _credentials;
            }
            set
            {
                _credentials = value;
            }
        }

        public Uri GetProxy(Uri destination)
        {
            return _proxyUri;
        }

        public bool IsBypassed(Uri host)
        {
            return false;
        }
    }
}
'@

    try {
        $AddType_prams = @{
            TypeDefinition = $InternalWebProxySource
            Language       = 'CSharp'
            ErrorAction    = 'SilentlyContinue'
        }
        if (-not $script:IsCoreCLR -or $script:IsNanoServer) {
            $AddType_prams['ReferencedAssemblies'] = $RequiredAssembliesForInternalWebProxy
        }
        Add-Type @AddType_prams
    }
    catch {
        Write-Warning -Message "InternalWebProxy: $_"
    }
}

# Check and add Telemetry type
if (('Microsoft.PowerShell.Telemetry.Internal.TelemetryAPI' -as [Type]) -and
    -not ('Microsoft.PowerShell.Commands.PowerShellGet.Telemetry' -as [Type])) {
    $RequiredAssembliesForTelemetry = @(
        [System.Management.Automation.PSCmdlet].Assembly.FullName
    )

    $TelemetrySource = @'
using System;
using System.Management.Automation;

namespace Microsoft.PowerShell.Commands.PowerShellGet
{
    public static class Telemetry
    {
        public static void TraceMessageArtifactsNotFound(string[] artifactsNotFound, string operationName)
        {
            Microsoft.PowerShell.Telemetry.Internal.TelemetryAPI.TraceMessage(operationName, new { ArtifactsNotFound = artifactsNotFound });
        }

        public static void TraceMessageNonPSGalleryRegistration(string sourceLocationType, string sourceLocationHash, string installationPolicy, string packageManagementProvider, string publishLocationHash, string scriptSourceLocationHash, string scriptPublishLocationHash, string operationName)
        {
            Microsoft.PowerShell.Telemetry.Internal.TelemetryAPI.TraceMessage(operationName, new { SourceLocationType = sourceLocationType, SourceLocationHash = sourceLocationHash, InstallationPolicy = installationPolicy, PackageManagementProvider = packageManagementProvider, PublishLocationHash = publishLocationHash, ScriptSourceLocationHash = scriptSourceLocationHash, ScriptPublishLocationHash = scriptPublishLocationHash });
        }
    }
}
'@

    try {
        $AddType_prams = @{
            TypeDefinition = $TelemetrySource
            Language       = 'CSharp'
            ErrorAction    = 'SilentlyContinue'
        }
        $AddType_prams['ReferencedAssemblies'] = $RequiredAssembliesForTelemetry
        Add-Type @AddType_prams
    }
    catch {
        Write-Warning -Message "Telemetry: $_"
    }
}
# Turn ON Telemetry if the infrastructure is present on the machine
$script:TelemetryEnabled = $false
if ('Microsoft.PowerShell.Commands.PowerShellGet.Telemetry' -as [Type]) {
    $telemetryMethods = ([Microsoft.PowerShell.Commands.PowerShellGet.Telemetry] | Get-Member -Static).Name
    if ($telemetryMethods.Contains("TraceMessageArtifactsNotFound") -and $telemetryMethods.Contains("TraceMessageNonPSGalleryRegistration")) {
        $script:TelemetryEnabled = $true
    }
}

# Check and add Win32Helpers type
$script:IsSafeX509ChainHandleAvailable = ($null -ne ('Microsoft.Win32.SafeHandles.SafeX509ChainHandle' -as [Type]))
if ($script:IsWindows -and -not ('Microsoft.PowerShell.Commands.PowerShellGet.Win32Helpers' -as [Type])) {
    $RequiredAssembliesForWin32Helpers = @()
    if ($script:IsSafeX509ChainHandleAvailable) {
        # It is not possible to define a single internal SafeHandle class in PowerShellGet namespace for all the supported versions of .Net Framework including .Net Core.
        # SafeHandleZeroOrMinusOneIsInvalid is not a public class on .Net Core,
        # therefore SafeX509ChainHandle will be used if it is available otherwise InternalSafeX509ChainHandle is defined below.
        #
        # ChainContext is not available on .Net Core, we must have to use SafeX509ChainHandle on .Net Core.
        #
        $SafeX509ChainHandleClassName = 'SafeX509ChainHandle'
        $RequiredAssembliesForWin32Helpers += [Microsoft.Win32.SafeHandles.SafeX509ChainHandle].Assembly.FullName
    }
    else {
        # SafeX509ChainHandle is not available on .Net Framework 4.5 or older versions,
        # therefore InternalSafeX509ChainHandle is defined below.
        #
        $SafeX509ChainHandleClassName = 'InternalSafeX509ChainHandle'
    }

    $Win32HelpersSource = @"
using System;
using System.Net;
using Microsoft.Win32.SafeHandles;
using System.Security.Cryptography;
using System.Runtime.InteropServices;
using System.Runtime.ConstrainedExecution;
using System.Runtime.Versioning;
using System.Security;

namespace Microsoft.PowerShell.Commands.PowerShellGet
{
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct CERT_CHAIN_POLICY_PARA {
        public CERT_CHAIN_POLICY_PARA(int size) {
            cbSize = (uint) size;
            dwFlags = 0;
            pvExtraPolicyPara = IntPtr.Zero;
        }
        public uint   cbSize;
        public uint   dwFlags;
        public IntPtr pvExtraPolicyPara;
    }

    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct CERT_CHAIN_POLICY_STATUS {
        public CERT_CHAIN_POLICY_STATUS(int size) {
            cbSize = (uint) size;
            dwError = 0;
            lChainIndex = IntPtr.Zero;
            lElementIndex = IntPtr.Zero;
            pvExtraPolicyStatus = IntPtr.Zero;
        }
        public uint   cbSize;
        public uint   dwError;
        public IntPtr lChainIndex;
        public IntPtr lElementIndex;
        public IntPtr pvExtraPolicyStatus;
    }

    // Internal SafeHandleZeroOrMinusOneIsInvalid class to remove the dependency on .Net Framework 4.6.
    public abstract class InternalSafeHandleZeroOrMinusOneIsInvalid : SafeHandle
    {
        protected InternalSafeHandleZeroOrMinusOneIsInvalid(bool ownsHandle)
            : base(IntPtr.Zero, ownsHandle)
        {
        }

        public override bool IsInvalid
        {
            get
            {
                return handle == IntPtr.Zero || handle == new IntPtr(-1);
            }
        }
    }

    // Internal SafeX509ChainHandle class to remove the dependency on .Net Framework 4.6.
    [SecurityCritical]
    public sealed class InternalSafeX509ChainHandle : InternalSafeHandleZeroOrMinusOneIsInvalid {
        private InternalSafeX509ChainHandle () : base(true) {}

        internal InternalSafeX509ChainHandle (IntPtr handle) : base (true) {
            SetHandle(handle);
        }

        internal static InternalSafeX509ChainHandle InvalidHandle {
            get { return new InternalSafeX509ChainHandle(IntPtr.Zero); }
        }

        [SecurityCritical]
        override protected bool ReleaseHandle()
        {
            CertFreeCertificateChain(handle);
            return true;
        }

        [DllImport("Crypt32.dll", SetLastError=true)]
$(if(-not $script:IsCoreCLR)
{
        '
        [SuppressUnmanagedCodeSecurity,
         ResourceExposure(ResourceScope.None),
         ReliabilityContract(Consistency.WillNotCorruptState, Cer.Success)]
        '
})
        private static extern void CertFreeCertificateChain(IntPtr handle);
    }

    public class Win32Helpers
    {
        [DllImport("Crypt32.dll", CharSet=CharSet.Auto, SetLastError=true)]
        public extern static
        bool CertVerifyCertificateChainPolicy(
            [In]     IntPtr                       pszPolicyOID,
            [In]     $SafeX509ChainHandleClassName  pChainContext,
            [In]     ref CERT_CHAIN_POLICY_PARA   pPolicyPara,
            [In,Out] ref CERT_CHAIN_POLICY_STATUS pPolicyStatus);

        [DllImport("Crypt32.dll", CharSet=CharSet.Auto, SetLastError=true)]
        public static extern
        $SafeX509ChainHandleClassName CertDuplicateCertificateChain(
            [In]     IntPtr pChainContext);

$(if($script:IsSafeX509ChainHandleAvailable)
{
@"
        [DllImport("Crypt32.dll", CharSet=CharSet.Auto, SetLastError=true)]
    $(if(-not $script:IsCoreCLR)
    {
    '
        [ResourceExposure(ResourceScope.None)]
    '
    })
        public static extern
        SafeX509ChainHandle CertDuplicateCertificateChain(
            [In]     SafeX509ChainHandle pChainContext);
"@
})

        public static bool IsMicrosoftCertificate([In] $SafeX509ChainHandleClassName pChainContext)
        {
            //-------------------------------------------------------------------------
            //  CERT_CHAIN_POLICY_MICROSOFT_ROOT
            //
            //  Checks if the last element of the first simple chain contains a
            //  Microsoft root public key. If it doesn't contain a Microsoft root
            //  public key, dwError is set to CERT_E_UNTRUSTEDROOT.
            //
            //  pPolicyPara is optional. However,
            //  MICROSOFT_ROOT_CERT_CHAIN_POLICY_ENABLE_TEST_ROOT_FLAG can be set in
            //  the dwFlags in pPolicyPara to also check for the Microsoft Test Roots.
            //
            //  MICROSOFT_ROOT_CERT_CHAIN_POLICY_CHECK_APPLICATION_ROOT_FLAG can be set
            //  in the dwFlags in pPolicyPara to check for the Microsoft root for
            //  application signing instead of the Microsoft product root. This flag
            //  explicitly checks for the application root only and cannot be combined
            //  with the test root flag.
            //
            //  MICROSOFT_ROOT_CERT_CHAIN_POLICY_DISABLE_FLIGHT_ROOT_FLAG can be set
            //  in the dwFlags in pPolicyPara to always disable the Flight root.
            //
            //  pvExtraPolicyPara and pvExtraPolicyStatus aren't used and must be set
            //  to NULL.
            //--------------------------------------------------------------------------
            const uint MICROSOFT_ROOT_CERT_CHAIN_POLICY_ENABLE_TEST_ROOT_FLAG       = 0x00010000;
            const uint MICROSOFT_ROOT_CERT_CHAIN_POLICY_CHECK_APPLICATION_ROOT_FLAG = 0x00020000;
            //const uint MICROSOFT_ROOT_CERT_CHAIN_POLICY_DISABLE_FLIGHT_ROOT_FLAG    = 0x00040000;

            CERT_CHAIN_POLICY_PARA PolicyPara = new CERT_CHAIN_POLICY_PARA(Marshal.SizeOf(typeof(CERT_CHAIN_POLICY_PARA)));
            CERT_CHAIN_POLICY_STATUS PolicyStatus = new CERT_CHAIN_POLICY_STATUS(Marshal.SizeOf(typeof(CERT_CHAIN_POLICY_STATUS)));
            int CERT_CHAIN_POLICY_MICROSOFT_ROOT = 7;

            PolicyPara.dwFlags = (uint) MICROSOFT_ROOT_CERT_CHAIN_POLICY_ENABLE_TEST_ROOT_FLAG;
            bool isMicrosoftRoot = false;

            if(CertVerifyCertificateChainPolicy(new IntPtr(CERT_CHAIN_POLICY_MICROSOFT_ROOT),
                                                pChainContext,
                                                ref PolicyPara,
                                                ref PolicyStatus))
            {
                isMicrosoftRoot = (PolicyStatus.dwError == 0);
            }

            // Also check for the Microsoft root for application signing if the Microsoft product root verification is unsuccessful.
            if(!isMicrosoftRoot)
            {
                // Some Microsoft modules can be signed with Microsoft Application Root instead of Microsoft Product Root,
                // So we need to use the MICROSOFT_ROOT_CERT_CHAIN_POLICY_CHECK_APPLICATION_ROOT_FLAG for the certificate verification.
                // MICROSOFT_ROOT_CERT_CHAIN_POLICY_CHECK_APPLICATION_ROOT_FLAG can not be used
                // with MICROSOFT_ROOT_CERT_CHAIN_POLICY_ENABLE_TEST_ROOT_FLAG,
                // so additional CertVerifyCertificateChainPolicy call is required to verify the given certificate is in Microsoft Application Root.
                //
                CERT_CHAIN_POLICY_PARA PolicyPara2 = new CERT_CHAIN_POLICY_PARA(Marshal.SizeOf(typeof(CERT_CHAIN_POLICY_PARA)));
                CERT_CHAIN_POLICY_STATUS PolicyStatus2 = new CERT_CHAIN_POLICY_STATUS(Marshal.SizeOf(typeof(CERT_CHAIN_POLICY_STATUS)));
                PolicyPara2.dwFlags = (uint) MICROSOFT_ROOT_CERT_CHAIN_POLICY_CHECK_APPLICATION_ROOT_FLAG;

                if(CertVerifyCertificateChainPolicy(new IntPtr(CERT_CHAIN_POLICY_MICROSOFT_ROOT),
                                                    pChainContext,
                                                    ref PolicyPara2,
                                                    ref PolicyStatus2))
                {
                    isMicrosoftRoot = (PolicyStatus2.dwError == 0);
                }
            }

            return isMicrosoftRoot;
        }
    }
}
"@

    try {
        $AddType_prams = @{
            TypeDefinition = $Win32HelpersSource
            Language       = 'CSharp'
            ErrorAction    = 'SilentlyContinue'
        }
        if ((-not $script:IsCoreCLR -or $script:IsNanoServer) -and $RequiredAssembliesForWin32Helpers) {
            $AddType_prams['ReferencedAssemblies'] = $RequiredAssembliesForWin32Helpers
        }
        Add-Type @AddType_prams
    }
    catch {
        Write-Warning -Message "Win32Helpers: $_"
    }
}

#endregion
