# This is a Pester test suite to validate the PowerShellGet module help
#
# Copyright (c) Microsoft Corporation

$script:IsWindowsOS = (-not (Get-Variable -Name IsWindows -ErrorAction Ignore)) -or $IsWindows

$script:HelpContentExtension = ".zip"
if ($script:IsWindowsOS) {
    $script:HelpContentExtension = ".cab"
}

$script:ExpectedHelpFile = 'PSModule-help.xml'
$script:ExpectedHelpInfoFile = 'PowerShellGet_1d73a601-4a6c-43c5-ba3f-619b18bbb404_HelpInfo.xml'
$script:ExpectedCompressedFile = "PowershellGet_1d73a601-4a6c-43c5-ba3f-619b18bbb404_en-US_helpcontent$script:HelpContentExtension"
$script:PowerShellGetModuleInfo = Get-Module -Name PowerShellGet -ListAvailable | Select-Object -First 1 -ErrorAction Ignore
$script:FullyQualifiedModuleName = [Microsoft.PowerShell.Commands.ModuleSpecification]@{
    ModuleName    = $script:PowerShellGetModuleInfo.Name
    Guid          = $script:PowerShellGetModuleInfo.Guid
    ModuleVersion = $script:PowerShellGetModuleInfo.Version
}

$script:HelpInstallationPath = Join-Path -Path $script:PowerShellGetModuleInfo.ModuleBase -ChildPath 'en-US'

function GetFiles {
    param (
        [Parameter()]
        [string]
        $Include = "*help.xml",

        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    Get-ChildItem -Path $Path -Include $Include -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
}

Describe 'Validate PowerShellGet module help' -tags 'P1', 'OuterLoop' {
    It 'Validate Update-Help for the PowerShellGet module' {
        $UpdateHelp_Params = @{
            Force = $true
            UICulture = 'en-US'
        }
        if($PSVersionTable.PSVersion -gt '4.0.0') {
            $UpdateHelp_Params['FullyQualifiedModule'] = $script:FullyQualifiedModuleName

            if($PSVersionTable.PSVersion -gt '6.0.99') {
                $UpdateHelp_Params['Scope'] = 'AllUsers'
            }
        }
        else {
            $UpdateHelp_Params['Name'] = 'PowerShellGet'
        }
        Update-Help @UpdateHelp_Params

        $helpFilesInstalled = @(GetFiles -Path $script:HelpInstallationPath | ForEach-Object {Split-Path -Path $_ -Leaf})
        $helpFilesInstalled | Should Be $script:ExpectedHelpFile

        $helpInfoFileInstalled = @(GetFiles -Include "*HelpInfo.xml" -Path $script:PowerShellGetModuleInfo.ModuleBase | ForEach-Object {Split-Path -Path $_ -Leaf})
        $helpInfoFileInstalled | Should Be $script:ExpectedHelpInfoFile
        
        $FindModuleCommandHelp = Get-Help -Name PowerShellGet\Find-Module -Detailed
        $FindModuleCommandHelp.Examples | Should Not BeNullOrEmpty
    }

    $helpPath = Join-Path -Path $TestDrive -ChildPath PSGetHelp
    New-Item -Path $helpPath -ItemType Directory

    It 'Validate Save-Help for the PowerShellGet module' {        
        if($PSVersionTable.PSVersion -gt '4.0.0') {        
            Save-Help -FullyQualifiedModule $script:FullyQualifiedModuleName -Force -UICulture en-US -DestinationPath $helpPath
        }
        else {
            Save-Help -Module PowerShellGet -Force -UICulture en-US -DestinationPath $helpPath
        }

        $compressedFile = GetFiles -Include "*$script:HelpContentExtension" -Path $helpPath | ForEach-Object { Split-Path -Path $_ -Leaf }
        $compressedFile | Should Be $script:ExpectedCompressedFile

        $helpFilesSaved = GetFiles -Include "*HelpInfo.xml" -Path $helpPath | ForEach-Object { Split-Path -Path $_ -Leaf }
        $helpFilesSaved | Should Be $script:ExpectedHelpInfoFile
    }
}