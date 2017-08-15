﻿<#####################################################################################
 # File: PSGetTestUtils.psm1
 #
 # Copyright (c) Microsoft Corporation, 2014
 #####################################################################################>

. "$PSScriptRoot\uiproxy.ps1"

$script:NuGetClient = $null
$script:NuGetExeName = 'NuGet.exe'
$script:NuGetProvider = $null
$script:NuGetProviderName = 'NuGet'
$script:NuGetProviderVersion  = [Version]'2.8.5.201'
$script:EnvironmentVariableTarget = @{ Process = 0; User = 1; Machine = 2 }

$script:PowerShellGet = 'PowerShellGet'
$script:IsInbox = $PSHOME.EndsWith('\WindowsPowerShell\v1.0', [System.StringComparison]::OrdinalIgnoreCase)
$script:IsWindows = (-not (Get-Variable -Name IsWindows -ErrorAction Ignore)) -or $IsWindows
$script:IsLinux = (Get-Variable -Name IsLinux -ErrorAction Ignore) -and $IsLinux
$script:IsOSX = (Get-Variable -Name IsOSX -ErrorAction Ignore) -and $IsOSX
$script:IsCoreCLR = (Get-Variable -Name IsCoreCLR -ErrorAction Ignore) -and $IsCoreCLR

if($script:IsInbox) {
    $script:ProgramFilesPSPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell"
} else {
    $script:ProgramFilesPSPath = $PSHome
}

if($script:IsInbox) {
    try {
        $script:MyDocumentsFolderPath = [Environment]::GetFolderPath("MyDocuments")
    } catch {
        $script:MyDocumentsFolderPath = $null
    }

    $script:MyDocumentsPSPath = if($script:MyDocumentsFolderPath) {
                                    Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsFolderPath -ChildPath "WindowsPowerShell"
                                } else {
                                    Microsoft.PowerShell.Management\Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell"
                                }
} elseif($script:IsWindows) {
    $script:MyDocumentsPSPath = Microsoft.PowerShell.Management\Join-Path -Path $HOME -ChildPath 'Documents\PowerShell'
} else {
    $script:MyDocumentsPSPath = Microsoft.PowerShell.Management\Join-Path -Path $HOME -ChildPath ".local/share/powershell"
}

$script:ProgramFilesModulesPath = Microsoft.PowerShell.Management\Join-Path -Path $script:ProgramFilesPSPath -ChildPath "Modules"
$script:MyDocumentsModulesPath = Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsPSPath -ChildPath "Modules"
$script:ProgramFilesScriptsPath = Microsoft.PowerShell.Management\Join-Path -Path $script:ProgramFilesPSPath -ChildPath "Scripts"
$script:MyDocumentsScriptsPath = Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsPSPath -ChildPath "Scripts"
$script:TempPath = if($script:IsWindows) { ([System.IO.DirectoryInfo]$env:TEMP).FullName } else { '/tmp' }

if($script:IsWindows) {
    $script:PSGetProgramDataPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
    $script:PSGetAppLocalPath = Microsoft.PowerShell.Management\Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
} else {
    $script:PSGetProgramDataPath = "$HOME/.config/powershell/powershellget"
    $script:PSGetAppLocalPath = "$HOME/.config/powershell/powershellget"
}

$script:ProgramDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $script:NuGetExeName
$script:ApplocalDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetAppLocalPath -ChildPath $script:NuGetExeName
$script:moduleSourcesFilePath="$script:PSGetAppLocalPath\PSRepositories.xml"

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
            $SourceUri        = 'https://dtlgalleryint.cloudapp.net/api/v2/'
            $PublishUri       = 'https://dtlgalleryint.cloudapp.net/api/v2/package'
            $ScriptSourceUri  = 'https://dtlgalleryint.cloudapp.net/api/v2/items/psscript/'
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

    if($script:NuGetProvider -and 
       ($script:NuGetClient -and (Microsoft.PowerShell.Management\Test-Path -Path $script:NuGetClient)))
    {
        return
    }

    # Invoke Install-NuGetClientBinaries internal function in PowerShellGet module to bootstrap both NuGet provider and NuGet.exe 
    $psgetModule = Import-Module -Name PowerShellGet -PassThru -Scope Local
    & $psgetModule Install-NuGetClientBinaries -Force -BootstrapNuGetExe -CallerPSCmdlet $PSCmdlet

    $script:NuGetProvider = PackageManagement\Get-PackageProvider -ErrorAction SilentlyContinue -WarningAction SilentlyContinue |
                                Microsoft.PowerShell.Core\Where-Object { 
                                                                         $_.Name -eq $script:NuGetProviderName -and 
                                                                         $_.Version -ge $script:NuGetProviderVersion
                                                                       }

    # Check if NuGet.exe is available under one of the predefined PowerShellGet locations under ProgramData or LocalAppData
    if(Microsoft.PowerShell.Management\Test-Path -Path $script:ProgramDataExePath)
    {
        $script:NuGetClient = $script:ProgramDataExePath
    }
    elseif(Microsoft.PowerShell.Management\Test-Path -Path $script:ApplocalDataExePath)
    {
        $script:NuGetClient = $script:ApplocalDataExePath
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
            $script:NuGetClient = $nugetCmd.Path
        }
    }
}

function Remove-NuGetExe
{
    # Uninstall NuGet.exe if it is available under one of the predefined PowerShellGet locations under ProgramData or LocalAppData
    if(Microsoft.PowerShell.Management\Test-Path -Path $script:ProgramDataExePath)
    {
        Remove-Item -Path $script:ProgramDataExePath -Force -Confirm:$false -WhatIf:$false
    }

    if(Microsoft.PowerShell.Management\Test-Path -Path $script:ApplocalDataExePath)
    {
        Remove-Item -Path $script:ApplocalDataExePath -Force -Confirm:$false -WhatIf:$false
    }    
}

function Get-NuGetExeFilePath
{
    Install-NuGetBinaries

    return $script:NuGetClient
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
        $Versions = @("1.0","1.5","2.0","2.5"),

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

    try
    {        
        
        $NupkgPath = "$NugetPackageRoot\$($PSModuleInfo.Name).$($PSModuleInfo.Version.ToString()).nupkg"
        $NuspecPath = "$NugetPackageRoot\$($PSModuleInfo.Name).nuspec"

        # Remove existing nuspec and nupkg files
        Remove-Item $NupkgPath  -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
        Remove-Item $NuspecPath -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
            
        Set-Content -Value $nuspec -Path $NuspecPath

        # Create .nupkg file
        $output = & $script:NuGetClient pack $NuspecPath -OutputDirectory $NugetPackageRoot
        if($LASTEXITCODE)
        {
            $message = $LocalizedData.FailedToCreateCompressedModule -f ($output) 
            Write-Error -Message $message -ErrorId "FailedToCreateCompressedModule" -Category InvalidOperation
            return
        }

        # Publish the .nupkg to gallery
        $output = & $script:NuGetClient push $NupkgPath  -source $Destination -NonInteractive -ApiKey $NugetApiKey 
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

    Get-Module $Name -ListAvailable | %{ 
            
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
        $ScriptPublishLocation
    )

    $PSGetModuleSources = [ordered]@{}
    $moduleSource = New-Object PSCustomObject -Property ([ordered]@{
            Name = 'PSGallery'
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
    $PSGetModuleSources.Add("PSGallery", $moduleSource)
    
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
    $cert = $null;
    $scriptName = Join-Path $script:TempPath  "$([IO.Path]::GetRandomFileName()).ps1"  
    "get-date" >$scriptName  
    $cert = @(get-childitem cert:\CurrentUser\My -codesigning | Where-Object {(Set-AuthenticodeSignature $scriptName -cert $_).Status -eq "Valid"})[0];  
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
