<#####################################################################################
 # File: PSGetTestUtils.psm1
 #
 # Copyright (c) Microsoft Corporation, 2014
 #####################################################################################>

. "$PSScriptRoot\uiproxy.ps1"

$script:NuGetExePath = $null
$script:NuGetExeName = 'NuGet.exe'
$script:NuGetProvider = $null
$script:NuGetProviderName = 'NuGet'
$script:NuGetProviderVersion  = [Version]'2.8.5.201'
$script:DotnetCommandPath = @()
$script:EnvironmentVariableTarget = @{ Process = 0; User = 1; Machine = 2 }
$script:EnvPATHValueBackup = $null

$script:PowerShellGet = 'PowerShellGet'
$script:IsInbox = $PSHOME.EndsWith('\WindowsPowerShell\v1.0', [System.StringComparison]::OrdinalIgnoreCase)
$script:IsWindows = (-not (Get-Variable -Name IsWindows -ErrorAction Ignore)) -or $IsWindows
$script:IsLinux = (Get-Variable -Name IsLinux -ErrorAction Ignore) -and $IsLinux
$script:IsMacOS = (Get-Variable -Name IsMacOS -ErrorAction Ignore) -and $IsMacOS
$script:IsCoreCLR = $PSVersionTable.ContainsKey('PSEdition') -and $PSVersionTable.PSEdition -eq 'Core'

if($script:IsInbox)
{
    $script:ProgramFilesPSPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell"
}
elseif($script:IsCoreCLR){
    if($script:IsWindows) {
        $script:ProgramFilesPSPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath 'PowerShell'
    }
    else {
        $script:ProgramFilesPSPath = Split-Path -Path ([System.Management.Automation.Platform]::SelectProductNameForDirectory('SHARED_MODULES')) -Parent
    }
}

try
{
    $script:MyDocumentsFolderPath = [Environment]::GetFolderPath("MyDocuments")
}
catch
{
    $script:MyDocumentsFolderPath = $null
}

if($script:IsInbox)
{
    $script:MyDocumentsPSPath = if($script:MyDocumentsFolderPath)
                                {
                                    Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsFolderPath -ChildPath "WindowsPowerShell"
                                }
                                else
                                {
                                    Microsoft.PowerShell.Management\Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell"
                                }
}
elseif($script:IsCoreCLR) {
    if($script:IsWindows)
    {
        $script:MyDocumentsPSPath = if($script:MyDocumentsFolderPath)
        {
            Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsFolderPath -ChildPath 'PowerShell'
        }
        else
        {
            Microsoft.PowerShell.Management\Join-Path -Path $HOME -ChildPath "Documents\PowerShell"
        }
    }
    else
    {
        $script:MyDocumentsPSPath = Split-Path -Path ([System.Management.Automation.Platform]::SelectProductNameForDirectory('USER_MODULES')) -Parent
    }
}

$script:ProgramFilesModulesPath = Microsoft.PowerShell.Management\Join-Path -Path $script:ProgramFilesPSPath -ChildPath 'Modules'
$script:MyDocumentsModulesPath = Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsPSPath -ChildPath 'Modules'
$script:ProgramFilesScriptsPath = Microsoft.PowerShell.Management\Join-Path -Path $script:ProgramFilesPSPath -ChildPath 'Scripts'
$script:MyDocumentsScriptsPath = Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsPSPath -ChildPath 'Scripts'
$script:TempPath = [System.IO.Path]::GetTempPath()

if($script:IsWindows) {
    $script:PSGetProgramDataPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
    $script:PSGetAppLocalPath = Microsoft.PowerShell.Management\Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
} else {
    $script:PSGetProgramDataPath = Join-Path -Path ([System.Management.Automation.Platform]::SelectProductNameForDirectory('CONFIG')) -ChildPath 'PowerShellGet'
    $script:PSGetAppLocalPath = Join-Path -Path ([System.Management.Automation.Platform]::SelectProductNameForDirectory('CACHE')) -ChildPath 'PowerShellGet'
}

$script:ProgramDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $script:NuGetExeName
$script:ApplocalDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetAppLocalPath -ChildPath $script:NuGetExeName
$script:moduleSourcesFilePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetAppLocalPath -ChildPath 'PSRepositories.xml'

# PowerShellGetFormatVersion will be incremented when we change the .nupkg format structure.
# PowerShellGetFormatVersion is in the form of Major.Minor.
# Minor is incremented for the backward compatible format change.
# Major is incremented for the breaking change.
$script:CurrentPSGetFormatVersion = "1.0"
$script:PSGetFormatVersionPrefix = "PowerShellGetFormatVersion_"

function Get-AllUsersModulesPath {
    return $script:ProgramFilesModulesPath
}

function Get-CurrentUserModulesPath {
    return $script:MyDocumentsModulesPath
}

function Get-AllUsersScriptsPath {
    return $script:ProgramFilesScriptsPath
}

function Get-CurrentUserScriptsPath {
    return $script:MyDocumentsScriptsPath
}

function Get-TempPath {
    return $script:TempPath
}

function Get-PSGetLocalAppDataPath {
    return $script:PSGetAppLocalPath
}

function GetAndSet-PSGetTestGalleryDetails
{
    param(
        [REF]$PSGallerySourceUri,

        [REF]$PSGalleryPublishUri,

        [REF]$PSGalleryScriptSourceUri,

        [REF]$PSGalleryScriptPublishUri,

        [Switch] $IsScriptSuite,

        [Switch] $SetPSGallery
    )

    if($env:PsgetTestGallery_ModuleUri -and $env:PsgetTestGallery_ScriptUri -and $env:PsgetTestGallery_PublishUri)
    {
        $SourceUri        = $env:PsgetTestGallery_ModuleUri
        $PublishUri       = $env:PsgetTestGallery_PublishUri
        $ScriptSourceUri  = $env:PsgetTestGallery_ScriptUri
        $ScriptPublishUri = $env:PsgetTestGallery_PublishUri
    }
    else
    {
        $SourceUri        = 'http://localhost:8765/api/v2/'
        $psgetModule = Import-Module -Name PowerShellGet -PassThru -Scope Local
        $ResolvedLocalSource = & $psgetModule Resolve-Location -Location $SourceUri -LocationParameterName 'SourceLocation'

        if($ResolvedLocalSource -and
           $PSVersionTable.PSVersion -ge '5.0.0' -and
           [System.Environment]::OSVersion.Version -ge "6.2.9200.0" -and
           $PSCulture -eq 'en-US')
        {
            $SourceUri        = $SourceUri
            $PublishUri       = "$SourceUri/package"
            $ScriptSourceUri  = $SourceUri
            $ScriptPublishUri = $PublishUri
        }
        else
        {
            $SourceUri        = 'https://www.poshtestgallery.com/api/v2/'
            $PublishUri       = 'https://www.poshtestgallery.com/api/v2/package'
            $ScriptSourceUri  = 'https://www.poshtestgallery.com/api/v2/items/psscript/'
            $ScriptPublishUri = $PublishUri
        }
    }

    $params = @{
                Location = $SourceUri
                PublishLocation = $PublishUri
              }

    if($IsScriptSuite)
    {
        $params['ScriptSourceLocation'] = $ScriptSourceUri
        $params['ScriptPublishLocation'] = $ScriptPublishUri
    }

    #$params.Keys | ForEach-Object {Write-Warning -Message "GetAndSet-PSGetTestGalleryDetails, $_ : $($params[$_])"}

    if($SetPSGallery)
    {
        Unregister-PSRepository -Name 'PSGallery'
        Set-PSGallerySourceLocation @params

        $repo = Get-PSRepository -Name 'PSGallery'
        if($repo.SourceLocation -ne $SourceUri)
        {
            Throw 'Test repository is not set properly'
        }
    }

    if($PSGallerySourceUri -ne $null)
    {
        $PSGallerySourceUri.Value = $SourceUri
    }

    if($PSGalleryPublishUri -ne $null)
    {
        $PSGalleryPublishUri.Value = $PublishUri
    }

    if($PSGalleryScriptSourceUri -ne $null)
    {
        $PSGalleryScriptSourceUri.Value = $ScriptSourceUri
    }

    if($PSGalleryScriptPublishUri -ne $null)
    {
        $PSGalleryScriptPublishUri.Value = $ScriptPublishUri
    }
}

function Install-NuGetBinaries
{
    [cmdletbinding()]
    param()

    # Look for renamed dotnet file
    $dotnetrenamed = 'dotnet.exe.Renamed'
    $DotnetCmdRenamed = Microsoft.PowerShell.Core\Get-Command -Name $dotnetrenamed -All -ErrorAction Ignore -WarningAction SilentlyContinue

    # Reset name if the original dotnet command was renamed during the previous bootstrap tests.
    if ($DotnetCmdRenamed.path -and (Test-Path -LiteralPath $DotnetCmdRenamed.path -PathType Leaf)) {
        For ($count=0; $count -lt $DotnetCmdRenamed.Length; $count++) {
            # Check every path in $script:DotnetCommandPath_Renamed is valid
            # If test-path is true, rename the particular path back to the original name
            if (Test-Path -LiteralPath $DotnetCmdRenamed.path[$count] -PathType Leaf) {
                $originalDotnetCmd = $DotnetCmdRenamed.path[$count] -replace ".Renamed", ''
                Rename-Item -Path $DotnetCmdRenamed.path[$count] -NewName $originalDotnetCmd
            }
        }
    }

    if($script:NuGetProvider -and
       (($script:NuGetExePath -and (Microsoft.PowerShell.Management\Test-Path -Path $script:NuGetExePath)) -or
       ($script:DotnetCommandPath -and (Microsoft.PowerShell.Management\Test-Path -Path $script:DotnetCommandPath))))
    {
        return
    }

    # Invoke Install-NuGetClientBinaries internal function in PowerShellGet module to bootstrap both NuGet provider and NuGet.exe
    $psgetModule = Import-Module -Name PowerShellGet -PassThru -Scope Local

    # Reset the environment path if the original env path was renamed during the previous bootstrap tests.
    if ($script:IsWindows -and $script:EnvPATHValueBackup) {
       & $psgetModule Set-EnvironmentVariable -Name 'PATH' -Value $script:EnvPATHValueBackup -Target $script:EnvironmentVariableTarget.Process
       $script:EnvPATHValueBackup = $null
    }

    & $psgetModule Install-NuGetClientBinaries -Force -BootstrapNuGetExe -CallerPSCmdlet $PSCmdlet

    $script:NuGetProvider = PackageManagement\Get-PackageProvider -ErrorAction SilentlyContinue -WarningAction SilentlyContinue |
                                Microsoft.PowerShell.Core\Where-Object {
                                                                         $_.Name -eq $script:NuGetProviderName -and
                                                                         $_.Version -ge $script:NuGetProviderVersion
                                                                       }

    if ($script:IsWindows) {
        # Check if NuGet.exe is available under one of the predefined PowerShellGet locations under ProgramData or LocalAppData
        if(Microsoft.PowerShell.Management\Test-Path -Path $script:ProgramDataExePath)
        {
            $script:NuGetExePath = $script:ProgramDataExePath
        }
        elseif(Microsoft.PowerShell.Management\Test-Path -Path $script:ApplocalDataExePath)
        {
            $script:NuGetExePath = $script:ApplocalDataExePath
        }
        else
        {
            # Get the NuGet.exe location if it is available under $env:PATH
            # NuGet.exe does not work if it is under $env:WINDIR, so skipping it from the Get-Command results
            $nugetCmd = Microsoft.PowerShell.Core\Get-Command -Name $script:NuGetExeName `
                                                                -ErrorAction SilentlyContinue `
                                                                -WarningAction SilentlyContinue |
                            Microsoft.PowerShell.Core\Where-Object {
                                $_.Path -and
                                ((Microsoft.PowerShell.Management\Split-Path -Path $_.Path -Leaf) -eq $script:NuGetExeName) -and
                                (-not $_.Path.StartsWith($env:windir, [System.StringComparison]::OrdinalIgnoreCase))
                            } | Microsoft.PowerShell.Utility\Select-Object -First 1

            if($nugetCmd -and $nugetCmd.Path)
            {
                $script:NuGetExePath = $nugetCmd.Path
            }
        }
    }

    if(-not $script:NuGetExePath) {
        $DotnetCmd = Microsoft.PowerShell.Core\Get-Command -Name dotnet -ErrorAction Ignore -WarningAction SilentlyContinue |
            Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

        if ($DotnetCmd -and $DotnetCmd.Path) {
            $script:DotnetCommandPath = $DotnetCmd.Path
        }
        else {
            if($script:IsWindows) {
                $DotnetCommandPath = Join-Path -Path $env:LocalAppData -ChildPath Microsoft |
                    Join-Path -ChildPath dotnet | Join-Path -ChildPath dotnet.exe

                if($DotnetCommandPath -and
                    -not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $DotnetCommandPath -PathType Leaf)) {
                    $DotnetCommandPath = Join-Path -Path $env:ProgramFiles -ChildPath dotnet | Join-Path -ChildPath dotnet.exe
                }
            }
            else {
                $DotnetCommandPath = '/usr/local/bin/dotnet'
            }

            if($DotnetCommandPath -and (Microsoft.PowerShell.Management\Test-Path -LiteralPath $DotnetCommandPath -PathType Leaf)) {
                $script:DotnetCommandPath = $DotnetCommandPath
            }
        }
    }
}

function Remove-NuGetExe
{
    Install-NuGetBinaries

    # Uninstall NuGet.exe if it is available under one of the predefined PowerShellGet locations under ProgramData or LocalAppData
    if (Microsoft.PowerShell.Management\Test-Path -Path $script:ProgramDataExePath) {
        Remove-Item -Path $script:ProgramDataExePath -Force -Confirm:$false -WhatIf:$false
    }

    if (Microsoft.PowerShell.Management\Test-Path -Path $script:ApplocalDataExePath) {
        Remove-Item -Path $script:ApplocalDataExePath -Force -Confirm:$false -WhatIf:$false
    }

    $DotnetCmd = Microsoft.PowerShell.Core\Get-Command -Name 'dotnet.exe' -All -ErrorAction Ignore -WarningAction SilentlyContinue

    if ($DotnetCmd -and $DotnetCmd.path) {
        # Dotnet can be stored in multiple locations, so test each path
        $DotnetCmd.path | ForEach-Object {
            if (Test-Path -LiteralPath $_ -PathType Leaf) {
                # if test-path is true, rename the particular path
                $renamed_dotnetCmdPath = "$_.Renamed"
                Rename-Item -Path $_ -NewName $renamed_dotnetCmdPath
            }
        }
    }

    $script:NuGetExePath = $null

    if ($script:IsWindows) {
        # Changes the environment so that dotnet and nuget files are temporarily removed
        $SourceLocations = Get-Command dotnet*, nuget* | ForEach-Object {
            if ($_.Source) {
                Split-Path -Path $_.Source -Parent
            }
            elseif ($_.Path) {
                Split-Path -Path $_.Path -Parent
            }
            elseif ($_.FileVersionInfo.file) {
                Split-Path -Path $_.FileVersionInfo.file -Parent
            }
        }
        if ($sourceLocations) {
            $psgetModule = Import-Module -Name PowerShellGet -PassThru -Scope Local
            $currentValue = & $psgetModule Get-EnvironmentVariable -Name 'PATH' -Target $script:EnvironmentVariableTarget.Process
            $script:EnvPATHValueBackup = $currentValue
            $PathElements = $currentValue -split ';' | Where-Object {$_ -and ($sourceLocations -notcontains $_.TrimEnd('\'))}

            & $psgetModule Set-EnvironmentVariable -Name 'PATH' -Value ($PathElements -join ';') -Target $script:EnvironmentVariableTarget.Process
        }
    }
}

function Install-Nuget28
{
    Remove-NuGetExe

    # Download outdated version 2.8.60717.93 of NuGet.exe from https://nuget.org/nuget.exe
    $null = Microsoft.PowerShell.Utility\Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?LinkID=690216&clcid=0x409' `
     -OutFile $programDataExePath
}

function Get-NuGetExeFilePath
{
    Install-NuGetBinaries

    return $script:NuGetExePath
}

function Get-DotnetCommandPath
{
    Install-NuGetBinaries

    return $script:DotnetCommandPath
}

function CreateAndPublish-TestScript
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $NuGetApiKey,

        [Parameter(Mandatory=$true)]
        [string]
        $Repository,

        [Parameter()]
        [string[]]
        $Versions = @("1.0","1.5","2.0","2.5"),

        [Parameter()]
        $RequiredModules = @(),

        [Parameter()]
        $ExternalModuleDependencies = @(),

        [Parameter()]
        $RequiredScripts = @(),

        [Parameter()]
        $ExternalScriptDependencies = @(),

        [Parameter()]
        [string]
        $ScriptsPath = $script:TempPath
    )

    $scriptFilePath = Join-Path -Path $ScriptsPath -ChildPath "$Name.ps1"
    $null = New-Item -Path $scriptFilePath -ItemType File -Force

    try
    {
        foreach($version in $Versions)
        {
            $params = @{
                        Path = $scriptFilePath
                        Version = $version
                        Author = 'manikb'
                        CompanyName = 'Microsoft Corporation'
                        Copyright = '(c) 2015 Microsoft Corporation. All rights reserved.'
                        Description = "Description for the $Name script"
                        LicenseUri = "https://$Name.com/license"
                        IconUri = "https://$Name.com/icon"
                        ProjectUri = "https://$Name.com"
                        Tags = @('Tag1','Tag2', "Tag-$Name-$version")
                        ReleaseNotes = "$Name release notes"
                        Force = $true
                       }

            if($RequiredModules) { $params['RequiredModules'] = $RequiredModules }
            if($RequiredScripts) { $params['RequiredScripts'] = $RequiredScripts }
            if($ExternalModuleDependencies) { $params['ExternalModuleDependencies'] = $ExternalModuleDependencies }
            if($ExternalScriptDependencies) { $params['ExternalScriptDependencies'] = $ExternalScriptDependencies }

            New-ScriptFileInfo @params

            Add-Content -Path $scriptFilePath -Value @"

Function Test-FunctionFromScript_$Name { Get-Date }

Workflow Test-WorkflowFromScript_$Name { Get-Date }

"@

            Publish-Script -Path $scriptFilePath `
                           -NuGetApiKey $NuGetApiKey `
                           -Repository $Repository
        }
    }
    finally
    {
        Remove-Item -Path $scriptFilePath -Force -ErrorAction SilentlyContinue
    }
}

function CreateAndPublishTestModule
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ModuleName,

        [Parameter(Mandatory=$true)]
        [string]
        $NuGetApiKey,

        [Parameter(Mandatory=$true)]
        [string]
        $Repository,

        [Parameter()]
        [string[]]
        $Versions = @("1.0","1.5","2.0","2.5"),

        [Parameter()]
        $RequiredModules = @(),

        [Parameter()]
        $NestedModules = @(),

        [Parameter()]
        [string]
        $ModulesPath = $script:TempPath
    )

    $ModuleBase = Join-Path $ModulesPath $ModuleName
    $null = New-Item -Path $ModuleBase -ItemType Directory -Force

    # To create a module manifest for $ModuleName with some dependencies in NestedModules and RequiredModules,
    # the dependency module should be available under one of the specified path in $env:PSModulePath.
    # Creating dummy module folders for them and will delete them after publishing the $ModuleName

    $ModulesToBeRemoved = @()
    $RequiredModulesToBeAvailable = @()
    if($RequiredModules)
    {
        $RequiredModulesToBeAvailable += $RequiredModules
    }

    if($NestedModules)
    {
        $RequiredModulesToBeAvailable += $NestedModules
    }

    foreach($ModuleToBeAvailable in $RequiredModulesToBeAvailable)
    {
        $ModuleToBeAvailable_Name = $null
        $ModuleToBeAvailable_Version = "1.0"

        if($ModuleToBeAvailable.GetType().ToString() -eq 'System.Collections.Hashtable')
        {
            $ModuleToBeAvailable_Name = $ModuleToBeAvailable.ModuleName

            if($ModuleToBeAvailable.Keys -Contains "RequiredVersion")
            {
                $ModuleToBeAvailable_Version = $ModuleToBeAvailable.RequiredVersion
            }
            elseif($ModuleToBeAvailable.Keys -Contains 'MaximumVersion')
            {
                $ModuleToBeAvailable_Version = $($ModuleToBeAvailable.MaximumVersion -replace "\*",'9')
            }
            else
            {
                $ModuleToBeAvailable_Version = $ModuleToBeAvailable.ModuleVersion
            }
        }
        else
        {
            $ModuleToBeAvailable_Name = $ModuleToBeAvailable.ToString()
        }

        $ModulesToBeRemoved += $ModuleToBeAvailable_Name

        $ModuleToBeAvailable_Base = Join-Path $script:ProgramFilesModulesPath $ModuleToBeAvailable_Name
        $null = New-Item -Path $ModuleToBeAvailable_Base -ItemType Directory -Force

        New-ModuleManifest -Path "$ModuleToBeAvailable_Base\$ModuleToBeAvailable_Name.psd1" `
                           -ModuleVersion $ModuleToBeAvailable_Version `
                           -Description "$ModuleToBeAvailable_Name module"
    }

    Set-Content "$ModuleBase\$ModuleName.psm1" -Value "function Get-$ModuleName { Get-Date }"

    $NestedModules += "$ModuleName.psm1"

    try
    {
        foreach($version in $Versions)
        {
            $tags = @('Tag1','Tag2', "Tag-$ModuleName-$version")

            $exportedFunctions = '*'
            if($ModuleName -match "ModuleWithDependencies*")
            {
                # For module with NestedModule dependencies, it's exported functions include the ones from NestedModules too.
                # To avoid that specifying the exported functions as empty list.
                $exportedFunctions = ''
            }

            $params = @{
                          Path = $ModuleBase
                          NuGetApiKey = $NuGetApiKey
                          Repository  = $Repository
                          WarningAction = 'SilentlyContinue'
                       }

            if($PSVersionTable.PSVersion -ge '5.0.0')
            {
                New-ModuleManifest -Path "$ModuleBase\$ModuleName.psd1" `
                                   -ModuleVersion $version `
                                   -Description "$ModuleName module" `
                                   -FunctionsToExport $exportedFunctions `
                                   -NestedModules $NestedModules `
                                   -LicenseUri "https://$ModuleName.com/license" `
                                   -IconUri "https://$ModuleName.com/icon" `
                                   -ProjectUri "https://$ModuleName.com" `
                                   -Tags $tags `
                                   -ReleaseNotes "$ModuleName release notes" `
                                   -RequiredModules $RequiredModules
            }
            else
            {
                New-ModuleManifest -Path "$ModuleBase\$ModuleName.psd1" `
                                   -ModuleVersion $version `
                                   -Description "$ModuleName module" `
                                   -FunctionsToExport $exportedFunctions `
                                   -NestedModules $NestedModules `
                                   -RequiredModules $RequiredModules

                $params['ReleaseNotes'] = "$ModuleName release notes"
                $params['Tags'] = $tags
                $params['LicenseUri'] = "https://$ModuleName.com/license"
                $params['IconUri'] = "https://$ModuleName.com/icon"
                $params['ProjectUri'] = "https://$ModuleName.com"
            }

            $null = Publish-Module @params
        }
    }
    finally
    {
        $ModulesToBeRemoved | ForEach-Object { Uninstall-Module -Name $_ }
        Uninstall-Module -Name $ModuleName -ErrorAction SilentlyContinue
    }
}

function PublishDscTestModule
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ModuleName,

        [Parameter(Mandatory=$true)]
        [string]
        $NuGetApiKey,

        [Parameter(Mandatory=$true)]
        [string]
        $Repository,

        [Parameter()]
        [string[]]
        $Versions = @("1.0","1.5","2.0","2.5"),

        [Parameter(Mandatory=$true)]
        [string]
        $TestModulesBase
    )

    $TempModulesPath = Join-Path $script:TempPath "$(Get-Random)"
    $null = New-Item -Path $TempModulesPath -ItemType Directory -Force

    Copy-Item -Path "$TestModulesBase\$ModuleName" -Destination $TempModulesPath -Recurse -Force
    $ModuleBase = Join-Path $TempModulesPath $ModuleName

    # Create binary module
    $content = @"
        using System;
        using System.Management.Automation;
        namespace PSGetTestModule
        {
            [Cmdlet("Test","PSGetTestCmdlet")]
            public class PSGetTestCmdlet : PSCmdlet
            {
                [Parameter]
                public int a {
                    get;
                    set;
                }
                protected override void ProcessRecord()
                {
                    String s = "Value is :" + a;
                    WriteObject(s);
                }
            }
        }
"@

    $assemblyName = "psgettestbinary_$(Get-Random).dll"
    $testBinaryPath = "$ModuleBase\$assemblyName"
    Add-Type -TypeDefinition $content -OutputAssembly $testBinaryPath -OutputType Library -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    foreach($version in $Versions)
    {
        $tags = @("PSGet","DSC","CommandsAndResource", 'Tag1','Tag2', 'Tag3', "Tag-$ModuleName-$version")
        $manfiestFilePath = "$ModuleBase\$ModuleName.psd1"

        RemoveItem -path $manfiestFilePath

        if($PSVersionTable.PSVersion -ge '5.0.0')
        {
            New-ModuleManifest -Path $manfiestFilePath `
                               -ModuleVersion $version  `
                               -NestedModules "$ModuleName.psm1",".\$assemblyName" `
                               -Tags $tags `
                               -Description 'Temp Description KeyWord1 Keyword2 Keyword3' `
                               -LicenseUri "https://$ModuleName.com/license" `
                               -IconUri "https://$ModuleName.com/icon" `
                               -ProjectUri "https://$ModuleName.com" `
                               -ReleaseNotes "$ModuleName release notes"
        }
        else
        {
            New-ModuleManifest -Path $manfiestFilePath `
                               -ModuleVersion $version  `
                               -NestedModules "$ModuleName.psm1",".\$assemblyName" `
                               -Description 'Temp Description KeyWord1 Keyword2 Keyword3' `
        }

        $null = Publish-Module -Path $ModuleBase `
                               -NuGetApiKey $NuGetApiKey `
                               -Repository $Repository `
                               -ReleaseNotes "$ModuleName release notes" `
                               -Tags $tags `
                               -LicenseUri "https://$ModuleName.com/license" `
                               -IconUri "https://$ModuleName.com/icon" `
                               -ProjectUri "https://$ModuleName.com" `
                               -WarningAction SilentlyContinue
    }
}

function CreateAndPublishTestModuleWithVersionFormat
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ModuleName,

        [Parameter(Mandatory=$true)]
        [string]
        $NuGetApiKey,

        [Parameter(Mandatory=$true)]
        [string]
        $Repository,

        [Parameter()]
        [string[]]
        $Versions = @("1.0.0","1.5.0","2.0.0","2.5.0"),

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Version]
        $PSGetFormatVersion = [Version]$script:CurrentPSGetFormatVersion,

        [Parameter()]
        [string]
        $ModulesPath = $script:TempPath
    )

    $repo = Get-PSRepository -Name $Repository -ErrorVariable err
    if($err)
    {
        Throw $err
    }

    $ModuleBase = Join-Path $ModulesPath $ModuleName

    if ($PSGetFormatVersion -eq '1.0')
    {
        $NugetPackageRoot = $ModuleBase
        $ModuleBase = "$ModuleBase\Content\Deployment\Module References\$ModuleName"
    }
    else
    {
        $NugetPackageRoot = $ModuleBase
    }

    $null = New-Item -Path $ModuleBase -ItemType Directory -Force

    Set-Content "$ModuleBase\$ModuleName.psm1" -Value "function Get-$ModuleName { Get-Date }"

    foreach($version in $Versions)
    {
        if($PSVersionTable.PSVersion -ge '5.0.0')
        {
            New-ModuleManifest -Path "$ModuleBase\$ModuleName.psd1" `
                               -ModuleVersion $version `
                               -Description "$ModuleName module" `
                               -NestedModules "$ModuleName.psm1" `
                               -LicenseUri "https://$ModuleName.com/license" `
                               -IconUri "https://$ModuleName.com/icon" `
                               -ProjectUri "https://$ModuleName.com" `
                               -Tags @('PSGet','PowerShellGet') `
                               -ReleaseNotes "$ModuleName release notes"
        }
        else
        {
            New-ModuleManifest -Path "$ModuleBase\$ModuleName.psd1" `
                               -ModuleVersion $version `
                               -Description "$ModuleName module" `
                               -NestedModules "$ModuleName.psm1"
        }

        $PSModuleInfo = Test-ModuleManifest -Path "$ModuleBase\$ModuleName.psd1"

        $null = Publish-PSGetExtModule -PSModuleInfo $PSModuleInfo `
                                       -NugetPackageRoot $NugetPackageRoot `
                                       -NuGetApiKey $NuGetApiKey `
                                       -Destination $repo.PublishLocation `
                                       -PSGetFormatVersion $PSGetFormatVersion `
                                       -ReleaseNotes "$ModuleName release notes" `
                                       -Tags @('PSGet','PowerShellGet') `
                                       -LicenseUri "https://$ModuleName.com/license" `
                                       -IconUri "https://$ModuleName.com/icon" `
                                       -ProjectUri "https://$ModuleName.com"
    }
}

function Publish-PSGetExtModule
{
    [CmdletBinding(PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSModuleInfo]
        $PSModuleInfo,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Destination,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NugetApiKey,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NugetPackageRoot,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $PSGetFormatVersion = $script:CurrentPSGetFormatVersion,

        [Parameter()]
        [string]
        $ReleaseNotes,

        [Parameter()]
        [string[]]
        $Tags,

        [Parameter()]
        [Uri]
        $LicenseUri,

        [Parameter()]
        [Uri]
        $IconUri,

        [Parameter()]
        [Uri]
        $ProjectUri
    )

    Install-NuGetBinaries

    if($PSModuleInfo.PrivateData -and
       ($PSModuleInfo.PrivateData.GetType().ToString() -eq "System.Collections.Hashtable") -and
       $PSModuleInfo.PrivateData["PSData"] -and
       ($PSModuleInfo.PrivateData["PSData"].GetType().ToString() -eq "System.Collections.Hashtable")
       )
    {
        if( -not $Tags -and $PSModuleInfo.PrivateData.PSData["Tags"])
        {
            $Tags = $PSModuleInfo.PrivateData.PSData.Tags
        }

        if( -not $ReleaseNotes -and $PSModuleInfo.PrivateData.PSData["ReleaseNotes"])
        {
            $ReleaseNotes = $PSModuleInfo.PrivateData.PSData.ReleaseNotes
        }

        if( -not $LicenseUri -and $PSModuleInfo.PrivateData.PSData["LicenseUri"])
        {
            $LicenseUri = $PSModuleInfo.PrivateData.PSData.LicenseUri
        }

        if( -not $IconUri -and $PSModuleInfo.PrivateData.PSData["IconUri"])
        {
            $IconUri = $PSModuleInfo.PrivateData.PSData.IconUri
        }

        if( -not $ProjectUri -and $PSModuleInfo.PrivateData.PSData["ProjectUri"])
        {
            $ProjectUri = $PSModuleInfo.PrivateData.PSData.ProjectUri
        }
    }

    # Add PSModule and PSGet format version tags
    if(-not $Tags)
    {
        $Tags = @()
    }

    if($PSGetFormatVersion -ne [Version]"0.0")
    {
        $Tags += "$script:PSGetFormatVersionPrefix$PSGetFormatVersion"
    }

    $Tags += "PSModule"

    # Populate the nuspec elements
    $nuspec = @"
<?xml version="1.0"?>
<package >
    <metadata>
        <id>$(Get-EscapedString -ElementValue $PSModuleInfo.Name)</id>
        <version>$($PSModuleInfo.Version)</version>
        <authors>$(Get-EscapedString -ElementValue $PSModuleInfo.Author)</authors>
        <owners>$(Get-EscapedString -ElementValue $PSModuleInfo.CompanyName)</owners>
        <description>$(Get-EscapedString -ElementValue $PSModuleInfo.Description)</description>
        <releaseNotes>$(Get-EscapedString -ElementValue $ReleaseNotes)</releaseNotes>
        <copyright>$(Get-EscapedString -ElementValue $PSModuleInfo.Copyright)</copyright>
        <tags>$(if($Tags){ Get-EscapedString -ElementValue ($Tags -join ' ')})</tags>
        $(if($LicenseUri){
        "<licenseUrl>$(Get-EscapedString -ElementValue $LicenseUri)</licenseUrl>
        <requireLicenseAcceptance>true</requireLicenseAcceptance>"
        })
        $(if($ProjectUri){
        "<projectUrl>$(Get-EscapedString -ElementValue $ProjectUri)</projectUrl>"
        })
        $(if($IconUri){
        "<iconUrl>$(Get-EscapedString -ElementValue $IconUri)</iconUrl>"
        })
        <dependencies>
        </dependencies>
    </metadata>
</package>
"@

# When packaging we must build something.
# So, we are building an empty assembly called NotUsed, and discarding it.
$CsprojContent = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <AssemblyName>NotUsed</AssemblyName>
    <Description>Temp project used for creating nupkg file.</Description>
    <NuspecFile>$($PSModuleInfo.Name).nuspec</NuspecFile>
    <NuspecBasePath>$NugetPackageRoot</NuspecBasePath>
    <TargetFramework>netcoreapp2.0</TargetFramework>
  </PropertyGroup>
</Project>
"@

    $csprojBasePath = $null
    try
    {
        $NupkgPath = Join-Path -Path $NugetPackageRoot -ChildPath "$($PSModuleInfo.Name).$($PSModuleInfo.Version.ToString()).nupkg"

        if($script:DotnetCommandPath) {
            $csprojBasePath = Join-Path -Path $script:TempPath -ChildPath ([System.Guid]::NewGuid())
            $null = New-Item -Path $csprojBasePath -ItemType Directory -Force -WhatIf:$false -Confirm:$false
            $NuspecPath = Join-Path -Path $csprojBasePath -ChildPath "$($PSModuleInfo.Name).nuspec"
            $CsprojFilePath = Join-Path -Path $csprojBasePath -ChildPath "$($PSModuleInfo.Name).csproj"
        }
        else {
            $NuspecPath = Join-Path -Path $NugetPackageRoot -ChildPath "$($PSModuleInfo.Name).nuspec"
        }

        # Remove existing nuspec and nupkg files
        Remove-Item $NupkgPath  -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
        Remove-Item $NuspecPath -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false

        Set-Content -Value $nuspec -Path $NuspecPath

        # Create .nupkg file
        if($script:DotnetCommandPath) {
            Microsoft.PowerShell.Management\Set-Content -Value $CsprojContent -Path $CsprojFilePath -Force -Confirm:$false -WhatIf:$false

            $arguments = @('pack')
            $arguments += $csprojBasePath
            $arguments += @('--output',$NugetPackageRoot)
            $arguments += "/p:StagingPath=$NugetPackageRoot"
            $output = & $script:DotnetCommandPath $arguments
            Write-Debug -Message "dotnet pack output:  $output"
        }
        else {
            $output = & $script:NuGetExePath pack $NuspecPath -OutputDirectory $NugetPackageRoot
        }

        if($LASTEXITCODE)
        {
            $message = $LocalizedData.FailedToCreateCompressedModule -f ($output)
            Write-Error -Message $message -ErrorId "FailedToCreateCompressedModule" -Category InvalidOperation
            return
        }

        $output = $null
        # Publish the .nupkg to gallery
        if($script:DotnetCommandPath) {
            $ArgumentList = @('nuget')
            $ArgumentList += 'push'
            $ArgumentList += "`"$NupkgPath`""
            $ArgumentList += @('--source', "`"$($Destination.TrimEnd('\'))`"")
            $ArgumentList += @('--api-key', "`"$NugetApiKey`"")
            $output = & $script:DotnetCommandPath $ArgumentList
        }
        else {
            $output = & $script:NuGetExePath push $NupkgPath  -source $Destination -NonInteractive -ApiKey $NugetApiKey
        }
        if($LASTEXITCODE)
        {
            $message = $LocalizedData.FailedToPublish -f ($output)
            Write-Error -Message $message -ErrorId "FailedToPublishTheModule" -Category InvalidOperation
        }
        else
        {
            $message = $LocalizedData.PublishedSuccessfully -f ($PSModuleInfo.Name, $Destination)
            Write-Verbose -Message $message
        }
    }
    finally
    {
        Remove-Item $NupkgPath  -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
        Remove-Item $NuspecPath -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false

        if($csprojBasePath -and (Test-Path -Path $csprojBasePath -PathType Container))
        {
            Microsoft.PowerShell.Management\Remove-Item -Path $csprojBasePath -Recurse -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
        }
    }
}

function Get-EscapedString
{
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [Parameter()]
        [string]
        $ElementValue
    )

    return [System.Security.SecurityElement]::Escape($ElementValue)
}

function Uninstall-Module
{
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    Get-Module $Name -ListAvailable | Foreach-Object {

            Remove-Module $_ -Force -ErrorAction SilentlyContinue;

            # Check if the module got installed with SxS version feature on PS 5.0 or later.
            if($_.ModuleBase.EndsWith("$($_.Version)", [System.StringComparison]::OrdinalIgnoreCase))
            {
                $ParentDir = Split-Path -Path $_.ModuleBase -Parent -WarningAction SilentlyContinue
                Remove-item $ParentDir -Recurse -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            }
            else
            {
                Remove-item $_.ModuleBase -Recurse -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            }
        }
}

function RemoveItem
{
    Param(
        [string]
        $path
    )

    if($path -and (Test-Path $path))
    {
        Remove-Item $path -Force -Recurse -ErrorAction SilentlyContinue
    }
}

function Set-PSGallerySourceLocation
{
    Param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name = 'PSGallery',

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Location,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $PublishLocation,

        [Parameter()]
        [string]
        $ScriptSourceLocation,

        [Parameter()]
        [string]
        $ScriptPublishLocation,

        [Parameter()]
        [switch]
        $UseExistingModuleSourcesFile
    )

    if ($UseExistingModuleSourcesFile) {
        $PSGetModuleSources = Import-CliXml -Path $script:moduleSourcesFilePath
    } else {
        $PSGetModuleSources = [ordered]@{}
    }

    $moduleSource = New-Object PSCustomObject -Property ([ordered]@{
            Name = $Name
            SourceLocation =  $Location
            PublishLocation = $PublishLocation
            ScriptSourceLocation =  $ScriptSourceLocation
            ScriptPublishLocation = $ScriptPublishLocation
            Trusted=$true
            Registered=$true
            InstallationPolicy = 'trusted'
            PackageManagementProvider='NuGet'
            ProviderOptions = @{}
        })

    $moduleSource.PSTypeNames.Insert(0, "Microsoft.PowerShell.Commands.PSRepository")
    $PSGetModuleSources.Add($Name, $moduleSource)

    if(-not (Test-Path $script:PSGetAppLocalPath))
    {
        $null = New-Item -Path $script:PSGetAppLocalPath `
                            -ItemType Directory -Force `
                            -ErrorAction SilentlyContinue `
                            -WarningAction SilentlyContinue `
                            -Confirm:$false -WhatIf:$false
    }

    # Persist the module sources, so that the PowerShellGet provider in different AppDomain will be able to use the custom module source Uri as the default one.
    Export-Clixml -InputObject $PSGetModuleSources `
                  -Path $script:moduleSourcesFilePath `
                  -Force -Confirm:$false -WhatIf:$false

    $null = Import-PackageProvider -Name PowerShellGet -Force
}

function Test-ModuleSxSVersionSupport
{
    # Side-by-Side module version is avialable on PowerShell 5.0 or later versions only
    # By default, PowerShell module versions will be installed/updated Side-by-Side.
    $PSVersionTable.PSVersion -ge '5.0.0'
}

function Reset-PATHVariableForScriptsInstallLocation
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet("CurrentUser","AllUsers")]
        [string]
        $Scope = "AllUsers",

        [Parameter()]
        [switch]
        $OnlyProcessPathVariable,

        [Parameter()]
        [switch]
        $WriteWarningMessages
    )

    if(($PSEdition -eq 'Core') -and (-not $script:IsWindows)) {
        Write-Verbose 'Set-PATHVariableForScriptsInstallLocation is not supported on Non-Windows platforms'
        return
    }

    if($Scope -eq 'AllUsers')
    {
        $scopePath = $script:ProgramFilesScriptsPath
        $target = $script:EnvironmentVariableTarget.Machine
    }
    else
    {
        $scopePath = $script:MyDocumentsScriptsPath
        $target = $script:EnvironmentVariableTarget.User
    }

    $scopePathEndingWithBackSlash = "$scopePath\"
    $psgetModule = Import-Module -Name PowerShellGet -PassThru -Scope Local -Verbose:$VerbosePreference

    if(-not $OnlyProcessPathVariable)
    {
        # Scope specific PATH
        $currentValue = & $psgetModule Get-EnvironmentVariable -Name 'PATH' -Target $target

        if($WriteWarningMessages)
        {
            Write-Warning "Current PATH value: `r`n    $currentValue"
        }

        $pathsInCurrentValue = ($currentValue -split ';') | Where-Object {$_}

        if($WriteWarningMessages)
        {
            Write-Warning "Current PATH value after splitting: `r`n    $pathsInCurrentValue"
        }

        if (($pathsInCurrentValue -contains $scopePath) -or
            ($pathsInCurrentValue -contains $scopePathEndingWithBackSlash))
        {
            $pathsInCurrentValueAfterRemovingScopePath = $pathsInCurrentValue | Where-Object {
                                                                                              ($_ -ne $scopePath) -and
                                                                                              ($_ -ne $scopePathEndingWithBackSlash)
                                                                                             }

            if($WriteWarningMessages)
            {
                Write-Warning "PathsInCurrentValueAfterRemovingScopePath: `r`n    $pathsInCurrentValueAfterRemovingScopePath"
            }

            & $psgetModule Set-EnvironmentVariable -Name 'PATH' `
                                                   -Value ($pathsInCurrentValueAfterRemovingScopePath -join ';')`
                                                   -Target $target

            $currentValue = & $psgetModule Get-EnvironmentVariable -Name 'PATH' -Target $target

            if($WriteWarningMessages)
            {
                Write-Warning "Current PATH value after resetting: `r`n    $currentValue"
            }
        }
    }

    # Process
    $target = $script:EnvironmentVariableTarget.Process
    $currentValue = & $psgetModule Get-EnvironmentVariable -Name 'PATH' -Target $target
    $pathsInCurrentValue = ($currentValue -split ';') | Where-Object {$_}

    if (($pathsInCurrentValue -contains $scopePath) -or
        ($pathsInCurrentValue -contains $scopePathEndingWithBackSlash))
    {
        $pathsInCurrentValueAfterRemovingScopePath = $pathsInCurrentValue | Where-Object {
                                                                                           ($_ -ne $scopePath) -and
                                                                                           ($_ -ne $scopePathEndingWithBackSlash)
                                                                                         }

        & $psgetModule Set-EnvironmentVariable -Name 'PATH' `
                                               -Value ($pathsInCurrentValueAfterRemovingScopePath -join ';')`
                                               -Target $target

        $currentValue = & $psgetModule Get-EnvironmentVariable -Name 'PATH' -Target $target
    }
}

function Set-PATHVariableForScriptsInstallLocation
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $Scope,

        [Parameter()]
        [switch]
        $OnlyProcessPathVariable
    )

    if(($PSEdition -eq 'Core') -and (-not $script:IsWindows)) {
        Write-Verbose 'Set-PATHVariableForScriptsInstallLocation is not supported on Non-Windows platforms'
        return
    }

    $psgetModule = Import-Module -Name PowerShellGet -PassThru -Scope Local -Verbose:$VerbosePreference

    # Check and add the scope path to PATH environment variable if USER accepts the prompt.
    if($Scope -eq 'AllUsers')
    {
        $ScopePath = $script:ProgramFilesScriptsPath
        $target = $script:EnvironmentVariableTarget.Machine
    }
    else
    {
        $ScopePath = $script:MyDocumentsScriptsPath
        $target = $script:EnvironmentVariableTarget.User
    }

    $AddedToPath = $false
    $scopePathEndingWithBackSlash = "$scopePath\"

    # Check and add the $scopePath to $env:Path value
    if( (($env:PATH -split ';') -notcontains $scopePath) -and
        (($env:PATH -split ';') -notcontains $scopePathEndingWithBackSlash))
    {
        if(-not $OnlyProcessPathVariable)
        {
            $currentPATHValue = & $psgetModule Get-EnvironmentVariable -Name 'PATH' -Target $envVariableTarget

            if((($currentPATHValue -split ';') -notcontains $scopePath) -and
                (($currentPATHValue -split ';') -notcontains $scopePathEndingWithBackSlash))
            {
                # To ensure that the installed script is immediately usable,
                # we need to add the scope path to the PATH enviroment variable.
                & $psgetModule Set-EnvironmentVariable -Name 'PATH' `
                                                       -Value "$currentPATHValue;$scopePath" `
                                                       -Target $envVariableTarget

                $AddedToPath = $true
            }
        }

        # Process specific PATH
        # Check and add the $scopePath to $env:Path value of current process
        # so that installed scripts can be used in the current process.
        $target = $script:EnvironmentVariableTarget.Process
        $currentPATHValue = & $psgetModule Get-EnvironmentVariable -Name 'PATH' -Target $target

        if((($currentPATHValue -split ';') -notcontains $scopePath) -and
            (($currentPATHValue -split ';') -notcontains $scopePathEndingWithBackSlash))
        {
            # To ensure that the installed script is immediately usable,
            # we need to add the scope path to the PATH enviroment variable.
            & $psgetModule Set-EnvironmentVariable -Name 'PATH' `
                                                   -Value "$currentPATHValue;$scopePath" `
                                                   -Target $target

            $AddedToPath = $true
        }
    }

    return $AddedToPath
}

function Get-CodeSigningCert
{
    param(
        [switch]
        $IncludeLocalMachineCerts
    )

    $cert = $null;
    $scriptName = Join-Path $script:TempPath  "$([IO.Path]::GetRandomFileName()).ps1"
    "get-date" >$scriptName
    $cert = @(get-childitem cert:\CurrentUser\My -codesigning | Where-Object {(Set-AuthenticodeSignature $scriptName -cert $_).Status -eq "Valid"})[0];
    if ((-not $cert) -and $IncludeLocalMachineCerts) {
        $cert = @(get-childitem cert:\LocalMachine\My -codesigning | Where-Object {(Set-AuthenticodeSignature $scriptName -cert $_).Status -eq "Valid"})[0];
    }

    del $scriptName
    $cert
}

#cleanup all ca certs
function Cleanup-CACert
{
    param
    (
        $CACert = 'PSCatalog Test Root Authority'
    )

    $CACertSubject = "CN=$CACert"

    get-ChildItem Cert:\LocalMachine\My\ | ?{$_.Subject -eq $CACertSubject} | remove-item -Force -ErrorAction SilentlyContinue
    get-ChildItem Cert:\CurrentUser\My\ | ?{$_.Subject -eq $CACertSubject} | remove-item -Force -ErrorAction SilentlyContinue
    get-ChildItem Cert:\LocalMachine\Root\ | ?{$_.Subject -eq $CACertSubject} | remove-item -Force -ErrorAction SilentlyContinue
    get-ChildItem Cert:\CurrentUser\Root\ | ?{$_.Subject -eq $CACertSubject} | remove-item -Force -ErrorAction SilentlyContinue
    get-ChildItem Cert:\LocalMachine\CA\ | ?{$_.Subject -eq $CACertSubject} | remove-item -Force -ErrorAction SilentlyContinue
    get-ChildItem Cert:\CurrentUser\CA\ | ?{$_.Subject -eq $CACertSubject} | remove-item -Force -ErrorAction SilentlyContinue
}

#creates a self signed ca cert
function Create-CACert
{
    param
    (
        $CACert = 'PSCatalog Test Root Authority'
    )

    $cert = (dir Cert:\LocalMachine\Root | Where-Object {$_.Subject -imatch $CACert})
    if ($cert -ne $null -and $cert.Thumbprint -ne $null)
    {
        Write-Verbose "Cert with subject name $CACert already found, attempting to use it"
        return
    }

    remove-item ca.cer -Force -ErrorAction SilentlyContinue
    remove-item ca.inf -Force -ErrorAction SilentlyContinue
    remove-item ca.pfx -Force -ErrorAction SilentlyContinue
    $certInf = @"
[Version]
Signature = "`$Windows NT`$"

[Strings]
szOID_BASIC_CONSTRAINTS = "2.5.29.19"

[NewRequest]
Subject = "cn=$CACert"
MachineKeySet = true
KeyLength = 2048
HashAlgorithm = Sha256
Exportable = true
RequestType = Cert
KeySpec = AT_SIGNATURE
KeyUsage = "CERT_KEY_CERT_SIGN_KEY_USAGE | CERT_DIGITAL_SIGNATURE_KEY_USAGE | CERT_CRL_SIGN_KEY_USAGE"
KeyUsageProperty = "NCRYPT_ALLOW_SIGNING_FLAG"
ValidityPeriod = "Years"
ValidityPeriodUnits = "1"

[Extensions]
%szOID_BASIC_CONSTRAINTS% = "{text}ca=1&pathlength=0"
Critical = %szOID_BASIC_CONSTRAINTS%
"@
    $certInf | out-file ca.inf -force
    Cleanup-CACert -CACert $CACert
    certreq -new .\ca.inf ca.cer
    $mypwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
    Get-ChildItem -Path Cert:\LocalMachine\My\ | ?{$_.Subject -eq "CN=$CACert"} | Export-PfxCertificate -FilePath .\ca.pfx -Password $mypwd
    Import-PfxCertificate -FilePath .\ca.pfx -CertStoreLocation Cert:\LocalMachine\Root\ -Password $mypwd -Exportable
    remove-item ca.cer -Force -ErrorAction SilentlyContinue
    remove-item ca.inf -Force -ErrorAction SilentlyContinue
    remove-item ca.pfx -Force -ErrorAction SilentlyContinue
}

#cleanup all code signing certs
function Cleanup-CodeSigningCert
{
  Param
  (
    [string]
    $Subject = 'PSCatalog Code Signing'
  )

  get-ChildItem Cert:\LocalMachine\My\ | ?{$_.Subject -eq "CN=$Subject"} | remove-item -Force -ErrorAction SilentlyContinue
  get-ChildItem Cert:\CurrentUser\My\ | ?{$_.Subject -eq "CN=$Subject"} | remove-item -Force -ErrorAction SilentlyContinue
  get-ChildItem Cert:\LocalMachine\TrustedPublisher\ | ?{$_.Subject -eq "CN=$Subject"} | remove-item -Force -ErrorAction SilentlyContinue
  get-ChildItem Cert:\CurrentUser\TrustedPublisher\ | ?{$_.Subject -eq "CN=$Subject"} | remove-item -Force -ErrorAction SilentlyContinue
}

#creates a code signing cert
function Create-CodeSigningCert
{
  Param
    (
        [string]
        $storeName = "Cert:\LocalMachine\TrustedPublisher",

        [string]
        $subject = "PSCatalog Code Signing",

        [string]
        $CertRA = "PSCatalog Test Root Authority"
    )

    if (!(Test-Path $storeName))
    {
       New-Item $storeName -Verbose -Force
    }

    $cert = (dir $storeName | where{$_.Subject -imatch $subject})
    if ($cert -ne $null -and $cert.Thumbprint -ne $null)
    {
        Write-Verbose "Cert with subject name $subject already found, attempting to use it"
        return
    }

    remove-item signing.cer -Force -ErrorAction SilentlyContinue
    remove-item signing.inf -Force -ErrorAction SilentlyContinue
    remove-item signing.pfx -Force -ErrorAction SilentlyContinue
    $certInf = @"
[Version]
Signature = "`$Windows NT`$"

[Strings]
szOID_ENHANCED_KEY_USAGE = "2.5.29.37"
szOID_CODE_SIGNING = "1.3.6.1.5.5.7.3.3"
szOID_BASIC_CONSTRAINTS = "2.5.29.19"

[NewRequest]
Subject = "cn=$subject"
MachineKeySet = true
KeyLength = 2048
HashAlgorithm = Sha256
Exportable = true
RequestType = Cert
KeySpec = AT_SIGNATURE
KeyUsage = "CERT_KEY_CERT_SIGN_KEY_USAGE | CERT_DIGITAL_SIGNATURE_KEY_USAGE | CERT_CRL_SIGN_KEY_USAGE"
KeyUsageProperty = "NCRYPT_ALLOW_SIGNING_FLAG"
ValidityPeriod = "Years"
ValidityPeriodUnits = "1"

[Extensions]
%szOID_BASIC_CONSTRAINTS% = "{text}ca=0"
%szOID_ENHANCED_KEY_USAGE% = "{text}%szOID_CODE_SIGNING%"
"@
    $certInf | out-file signing.inf -force
    [void](Cleanup-CodeSigningCert -Subject $subject)
    Create-CACert -CACert $CertRA
    certreq -new -q -cert $CertRA .\signing.inf signing.cer
    $mypwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
    Get-ChildItem -Path Cert:\LocalMachine\My\ | ?{$_.Subject -eq "CN=$subject"} | Export-PfxCertificate -FilePath .\signing.pfx -Password $mypwd
    Import-PfxCertificate -FilePath .\signing.pfx -CertStoreLocation "$storeName\" -Password $mypwd -Exportable
    remove-item signing.cer -Force -ErrorAction SilentlyContinue
    remove-item signing.inf -Force -ErrorAction SilentlyContinue
    remove-item signing.pfx -Force -ErrorAction SilentlyContinue
}

function Get-LocalModulePath() {
    $modulepath= Join-Path -Path (Split-Path $psscriptroot -parent) -ChildPath "src"
    return $modulepath
}

# Ensure the local directory is at the front of the psmodulepath so that we test that instead of some other version on the system
function Add-LocalTreeInPSModulePath() {
    # we are in repo\tests, module is in repo\src\PowerShellGet
    # add repo\src to $psmodulepath so PowerShellGet is found
    $modulepath= Get-LocalModulePath
    Write-Verbose "Ensure we load PowerShellGet from $modulepath"

    $paths = $env:PSModulePath -split ";"
    if ($paths[0] -notlike $modulepath)
    {
        $env:PSModulePath = "$modulepath;$env:PSModulePath"
    }
    Write-Verbose "New PSModulePath: $($env:psmodulepath -replace ";",`"`n`")"
}

function Remove-LocalTreeInPSModulePath() {
    $modulepath= Get-LocalModulePath
    $paths = $env:PSModulePath -split ";"
    if ($paths[0] -like $modulepath)
    {
        $env:PSModulePath = ($paths[1..($paths.Length-1)] -join ";")
    }
    Write-Verbose "New PSModulePath: $($env:psmodulepath -replace ";",`"`n`")"
}


# Set up things so that tests run reliably and don't conflict with/overwrite user's local configuration during testing
function Set-TestEnvironment() {
    [cmdletbinding(supportsshouldprocess=$true)]
    param(

    )

    $ErrorActionPreference="Stop"

    Add-LocalTreeInPSModulePath

    # Normally we want to test the code in this repo, not some other version of PowerShellGet on the system
    $expectedModuleBase= Join-Path -Path (Split-Path $psscriptroot -parent) -ChildPath "src\PowerShellGet"
    $expectedProviderPath = Join-Path -Path $expectedModuleBase -ChildPath "PSModule.psm1"

    Write-Verbose "Ensure we load PowerShellGet from $expectedModuleBase"

    $psgetmodule = Import-Module -Name PowerShellGet -PassThru -Scope Global -Force
    if($psgetmodule.ModuleBase -ne $expectedModuleBase) {
        Write-Warning "Loading PowerShellGet from $($psgetmodule.ModuleBase), but the PowerShellGet under development is in $expectedModuleBase."
    }

    Write-Verbose "Ensure we load PowerShellGet Provider from $expectedModuleBase"
    $psgetprovider = Import-PackageProvider -Name PowerShellGet -Force

    if($psgetprovider.ProviderPath -ne $expectedProviderPath) {
        Write-Warning "Loading PowerShellGet Package Provider from $($psgetprovider.ProviderPath), but the PowerShellGet under development is in $expectedModuleBase."
    }

    #Set-TestRepositoryLocation -Verbose:$VerbosePreference

    <#
    Write-Verbose "Checking PSGallery Repository"
    $repo = Get-PSRepository PSGallery -ErrorAction SilentlyContinue

    if(-not $repo) {
        Write-Warning "No PSGallery repository found"
        if($psCmdlet.ShouldProcess("PSGallery", "Register default PSGallery")) {
            Register-PSRepository -Default
            $repo = Get-PSRepository PSGallery
        }
        else { throw "No PSGallery, can't continue"}
    }

    if ($repo.SourceLocation -ne "https://www.powershellgallery.com/api/v2" -or $repo.PublishLocation -ne "https://www.powershellgallery.com/api/v2/package/") {
        Write-Warning "PSGallery set to unexpected location $($repo.SourceLocation) / $($repo.PublishLocation)"
        if($psCmdlet.ShouldProcess("PSGallery", "Restore PSGallery to default")) {
            Unregister-PSRepository PSGallery
            Register-PSRepository -Default
        }
    }
    #>
}

# All the test environment changes are inside the loaded module. So just reloading it clears everything
function Remove-TestEnvironment
{
    Remove-LocalTreeInPSModulePath
}

function Invoke-WithoutAdminPrivileges
{
    [CmdletBinding()]
    param($commandLine)

    $tempFile = "$env:temp\$(New-Guid).txt"
    $errFile = "$env:temp\$(New-Guid)-err.txt"
    $wrappedCommandLine = "& { $commandLine } > $tempFile 2> $errFile"
    Write-Verbose "Executing $wrappedCommandLine"
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($wrappedCommandLine)
    $encodedCommand = [Convert]::ToBase64String($bytes)

    $processName = (get-process -Id $pid).ProcessName
    Start-Process "runas.exe" -ArgumentList ("/trustlevel:0x20000", "`"$processName -encodedcommand $encodedcommand`"") -Wait
    Get-Content $tempFile
    $errors = Get-Content $errFile
    if($errors) {
        Write-Error "Errors from child command: $errors"
    }
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    Remove-Item $errFile -Force -ErrorAction SilentlyContinue
}
