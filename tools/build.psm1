#region script variables
$script:PowerShellGet = 'PowerShellGet'
$script:IsInbox = $PSHOME.EndsWith('\WindowsPowerShell\v1.0', [System.StringComparison]::OrdinalIgnoreCase)
$script:IsWindows = (-not (Get-Variable -Name IsWindows -ErrorAction Ignore)) -or $IsWindows
$script:IsCoreCLR = $PSVersionTable.ContainsKey('PSEdition') -and $PSVersionTable.PSEdition -eq 'Core'

$script:ProjectRoot = Split-Path -Path $PSScriptRoot -Parent
$script:ModuleRoot = Join-Path -Path $ProjectRoot -ChildPath "src\PowerShellGet"
$script:ModuleFile = Join-Path -Path $ModuleRoot -ChildPath "PSModule.psm1"
$script:DscModuleRoot = Join-Path -Path $ProjectRoot -ChildPath "DSC"
$script:ArtifactRoot = Join-Path -Path $ProjectRoot -ChildPath "dist"


$script:PublicPSGetFunctions = @( Get-ChildItem -Path $ModuleRoot\public\psgetfunctions\*.ps1 -ErrorAction SilentlyContinue )
$script:PublicProviderFunctions = @( Get-ChildItem -Path $ModuleRoot\public\providerfunctions\*.ps1 -ErrorAction SilentlyContinue )
$script:PrivateFunctions = @( Get-ChildItem -Path $ModuleRoot\private\functions\*.ps1 -ErrorAction SilentlyContinue )

if ($script:IsInbox) {
    $script:ProgramFilesPSPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell"
}
elseif ($script:IsCoreCLR) {
    if ($script:IsWindows) {
        $script:ProgramFilesPSPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath 'PowerShell'
    }
    else {
        $script:ProgramFilesPSPath = Split-Path -Path ([System.Management.Automation.Platform]::SelectProductNameForDirectory('SHARED_MODULES')) -Parent
    }
}

$script:ProgramFilesModulesPath = Microsoft.PowerShell.Management\Join-Path -Path $script:ProgramFilesPSPath -ChildPath "Modules"
$script:TempPath = [System.IO.Path]::GetTempPath()

if ($script:IsWindows) {
    $script:PSGetProgramDataPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
}
else {
    $script:PSGetProgramDataPath = Join-Path -Path ([System.Management.Automation.Platform]::SelectProductNameForDirectory('CONFIG')) -ChildPath 'PowerShellGet'
}

$AllUsersModulesPath = $script:ProgramFilesModulesPath

# AppVeyor.yml sets a value to $env:PowerShellEdition variable,
# otherwise set $script:PowerShellEdition value based on the current PowerShell Edition.
$script:PowerShellEdition = [System.Environment]::GetEnvironmentVariable("PowerShellEdition")
if (-not $script:PowerShellEdition) {
    if ($script:IsCoreCLR) {
        $script:PowerShellEdition = 'Core'
    }
    else {
        $script:PowerShellEdition = 'Desktop'
    }
}
elseif (($script:PowerShellEdition -eq 'Core') -and ($script:IsWindows)) {
    # In AppVeyor test runs, OneGet and PSGet modules are installed from Windows PowerShell process
    # Set AllUsersModulesPath to $env:ProgramFiles\PowerShell\Modules
    $AllUsersModulesPath = Join-Path -Path $env:ProgramFiles -ChildPath 'PowerShell' | Join-Path -ChildPath 'Modules'
}
Write-Host "PowerShellEdition value: $script:PowerShellEdition"

#endregion script variables

function Install-Dependencies {
    # Update build title for daily builds
    if ($script:IsWindows -and (Test-DailyBuild)) {
        if ($env:APPVEYOR_PULL_REQUEST_TITLE) {
            $buildName += $env:APPVEYOR_PULL_REQUEST_TITLE
        }
        else {
            $buildName += $env:APPVEYOR_REPO_COMMIT_MESSAGE
        }

        if (-not ($buildName.StartsWith("[Daily]", [System.StringComparison]::OrdinalIgnoreCase))) {
            Update-AppveyorBuild -message "[Daily] $buildName"
        }
    }

    Install-PackageManagement
}
function Install-PackageManagement {

    # Bootstrap NuGet.exe
    $NuGetExeName = 'NuGet.exe'
    $NugetExeFilePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $NuGetExeName

    if (-not (Test-Path -Path $NugetExeFilePath -PathType Leaf)) {
        if (-not (Microsoft.PowerShell.Management\Test-Path -Path $script:PSGetProgramDataPath)) {
            $null = Microsoft.PowerShell.Management\New-Item -Path $script:PSGetProgramDataPath -ItemType Directory -Force
        }

        # Download the NuGet.exe from https://dist.nuget.org/win-x86-commandline/latest/nuget.exe
        Microsoft.PowerShell.Utility\Invoke-WebRequest -Uri https://aka.ms/psget-nugetexe -OutFile $NugetExeFilePath
    }

    Get-ChildItem -Path $NugetExeFilePath -File

    # Install latest PackageManagement from Gallery
    $OneGetModuleName = 'PackageManagement'
    $OneGetModuleInfo = Get-Module -ListAvailable -Name $OneGetModuleName | Select-Object -First 1
    if ($OneGetModuleInfo) {
        $NuGetProvider = Get-PackageProvider | Where-Object { $_.Name -eq 'NuGet' }
        if (-not $NuGetProvider) {
            Install-PackageProvider -Name NuGet -Force
        }

        $FindModule_params = @{
            Name = $OneGetModuleName
        }
        if ($PSVersionTable.PSVersion -eq '5.1.14394.1000') {
            # Adding -MaximumVersion 1.1.7.0 as AppVeyor VM with WMF 5 is not installed with latest root CA certificates
            $FindModule_params['MaximumVersion'] = '1.1.7.0'
        }
        $LatestOneGetInPSGallery = Find-Module @FindModule_params
        if ($LatestOneGetInPSGallery.Version -gt $OneGetModuleInfo.Version) {
            Install-Module -InputObject $LatestOneGetInPSGallery -Force
        }
    }
    else {
        # Install latest PackageManagement module from PSGallery
        $TempModulePath = Microsoft.PowerShell.Management\Join-Path -Path $script:TempPath -ChildPath "$(Get-Random)"
        $null = Microsoft.PowerShell.Management\New-Item -Path $TempModulePath -Force -ItemType Directory
        $OneGetModuleName = 'PackageManagement'
        try {
            & $NugetExeFilePath install $OneGetModuleName -source https://www.powershellgallery.com/api/v2 -outputDirectory $TempModulePath -verbosity detailed
            $OneGetWithVersion = Microsoft.PowerShell.Management\Get-ChildItem -Path $TempModulePath -Directory
            $OneGetVersion = ($OneGetWithVersion.Name.Split('.', 2))[1]

            $OneGetModulePath = Microsoft.PowerShell.Management\Join-Path -Path  $AllUsersModulesPath -ChildPath $OneGetModuleName
            if ($PSVersionTable.PSVersion -ge '5.0.0') {
                $OneGetModulePath = Microsoft.PowerShell.Management\Join-Path -Path $OneGetModulePath -ChildPath $OneGetVersion
            }

            $null = Microsoft.PowerShell.Management\New-Item -Path $OneGetModulePath -Force -ItemType Directory
            Microsoft.PowerShell.Management\Copy-Item -Path "$($OneGetWithVersion.FullName)\*" -Destination "$OneGetModulePath\" -Recurse -Force
            Get-Module -ListAvailable -Name $OneGetModuleName | Microsoft.PowerShell.Core\Where-Object { $_.Version -eq $OneGetVersion }
        }
        finally {
            Remove-Item -Path $TempModulePath -Recurse -Force
        }
    }
}
function Get-PSHome {
    $PowerShellHome = $PSHOME

    # Install PowerShell Core on Windows.
    if (($script:PowerShellEdition -eq 'Core') -and $script:IsWindows) {
        $InstallPSCoreUrl = 'https://aka.ms/install-pscore'
        $InstallPSCorePath = Microsoft.PowerShell.Management\Join-Path -Path $PSScriptRoot -ChildPath 'install-powershell.ps1'
        Microsoft.PowerShell.Utility\Invoke-RestMethod -Uri $InstallPSCoreUrl -OutFile $InstallPSCorePath

        $PowerShellHome = "$env:SystemDrive\PowerShellCore"
        & $InstallPSCorePath -Destination $PowerShellHome -Daily

        if (-not $PowerShellHome -or -not (Microsoft.PowerShell.Management\Test-Path -Path $PowerShellHome -PathType Container)) {
            Throw "$PowerShellHome path is not available."
        }

        Write-Host ("PowerShell Home Path '{0}'" -f $PowerShellHome)
    }

    return $PowerShellHome
}
function Invoke-PowerShellGetTest {

    Param(
        [Parameter()]
        [Switch]
        $IsFullTestPass
    )

    Write-Host -ForegroundColor Green "`$env:PS_DAILY_BUILD value $env:PS_DAILY_BUILD"
    Write-Host -ForegroundColor Green "`$env:APPVEYOR_SCHEDULED_BUILD value $env:APPVEYOR_SCHEDULED_BUILD"
    Write-Host -ForegroundColor Green "`$env:APPVEYOR_REPO_TAG_NAME value $env:APPVEYOR_REPO_TAG_NAME"
    Write-Host -ForegroundColor Green "TRAVIS_EVENT_TYPE environment variable value $([System.Environment]::GetEnvironmentVariable('TRAVIS_EVENT_TYPE'))"

    if (-not $IsFullTestPass) {
        $IsFullTestPass = Test-DailyBuild
    }
    Write-Host -ForegroundColor Green "`$IsFullTestPass value $IsFullTestPass"
    Write-Host -ForegroundColor Green "Test-DailyBuild: $(Test-DailyBuild)"

    $env:APPVEYOR_TEST_PASS = $true
    $ClonedProjectPath = Resolve-Path "$PSScriptRoot\.."
    $PowerShellGetTestsPath = "$ClonedProjectPath\Tests\"
    $PowerShellHome = Get-PSHome
    if ($script:IsWindows) {
        if ($script:PowerShellEdition -eq 'Core') {
            $PowerShellExePath = Join-Path -Path $PowerShellHome -ChildPath 'pwsh.exe'
        }
        else {
            $PowerShellExePath = Join-Path -Path $PowerShellHome -ChildPath 'PowerShell.exe'
        }
    }
    else {
        $PowerShellExePath = 'pwsh'
    }

    # Test Environment
    # - PowerShellGet from Current branch
    # - PowerShellGet packaged with PowerShellCore build:
    #   -- Where PowerShellGet module was installed from MyGet feed https://powershell.myget.org/F/powershellmodule/api/v2/
    #   -- This option is used only for Daily builds
    $TestScenarios = @()
    if (($script:PowerShellEdition -eq 'Core') -and $IsFullTestPass -and $script:IsWindows) {
        # Disabled NoUpdate test scenario on PWSH
        #$TestScenarios += 'NoUpdate'
    }
    # We should run PSCore_PSGet_TestRun first before updating the PowerShellGet module from current branch.
    $TestScenarios += 'Current'

    $PesterTag = '' # Conveys all test priorities
    if (-not $IsFullTestPass) {
        $PesterTag = 'BVT' # Only BVTs
    }

    $TestResults = @()

    foreach ($TestScenario in $TestScenarios) {

        Write-Host "TestScenario: $TestScenario"

        & $PowerShellExePath -Command @'
            $env:PSModulePath;
            $PSVersionTable;
            Get-PackageProvider;
            Get-PSRepository;
            Get-Module;

            $NuGetProvider = Get-PackageProvider | Where-Object { $_.Name -eq 'NuGet' }
            if(-not $NuGetProvider) {
                Install-PackageProvider -Name NuGet -Force
            }

            Install-Module -Name Pester -MaximumVersion 4.1.0 -Force -SkipPublisherCheck -AllowClobber
            Get-Module -Name Pester -ListAvailable;

            # Remove PSGetModuleInfo.xml files from the installed module bases to ensure that Update-Module tests executed properly.
            Get-InstalledModule -Name Pester,PackageManagement,DockerMsftProvider -ErrorAction SilentlyContinue | Foreach-Object {
                $PSGetModuleInfoXmlPath = Join-Path -Path $_.InstalledLocation -ChildPath 'PSGetModuleInfo.xml'
                Remove-Item -Path $PSGetModuleInfoXmlPath -Force -Verbose
            }
            Get-InstalledModule

            # WMF 4 appveyor OS Image has duplicate entries in $env:PSModulePath
            if($PSVersionTable.PSVersion -le '5.0.0') {
                Write-Host "PSModulePath value before removing the duplicate entries:"
                $env:PSModulePath;

                # Current Process
                $ValueWithUniqueEntries = ([System.Environment]::GetEnvironmentVariable('PSModulePath', [System.EnvironmentVariableTarget]::Process) -split ';' | Foreach-Object {$_.Trim('\\')} | Select-Object -Unique) -join ';'
                [System.Environment]::SetEnvironmentVariable('PSModulePath', $ValueWithUniqueEntries, [System.EnvironmentVariableTarget]::Process)

                # Current User
                $ValueWithUniqueEntries = ([System.Environment]::GetEnvironmentVariable('PSModulePath', [System.EnvironmentVariableTarget]::User) -split ';' | Foreach-Object {$_.Trim('\\')} | Select-Object -Unique) -join ';'
                [System.Environment]::SetEnvironmentVariable('PSModulePath', $ValueWithUniqueEntries, [System.EnvironmentVariableTarget]::User)

                # Current Machine
                $ValueWithUniqueEntries = ([System.Environment]::GetEnvironmentVariable('PSModulePath', [System.EnvironmentVariableTarget]::Machine) -split ';' | Foreach-Object {$_.Trim('\\')} | Select-Object -Unique) -join ';'
                [System.Environment]::SetEnvironmentVariable('PSModulePath', $ValueWithUniqueEntries, [System.EnvironmentVariableTarget]::Machine)

                Write-Host "PSModulePath value after removing the duplicate entries:"
                $env:PSModulePath;
            }
'@

        try {
            Push-Location $PowerShellGetTestsPath

            $TestResultsFile = Microsoft.PowerShell.Management\Join-Path -Path $PowerShellGetTestsPath -ChildPath "TestResults$TestScenario.xml"
            & $PowerShellExePath -Command "`$env:PSModulePath = (`$env:PSModulePath -split ';' | Foreach-Object {`$_.Trim('\\')} | Select-Object -Unique) -join ';' ;
                                        Write-Host 'After updating the PSModulePath value:' ;
                                        `$env:PSModulePath ;
                                        `$ProgressPreference = 'SilentlyContinue'
                                        Invoke-Pester -Script $PowerShellGetTestsPath -OutputFormat NUnitXml -OutputFile $TestResultsFile -PassThru $(if($PesterTag){"-Tag @('" + ($PesterTag -join "','") + "')"})"

            $TestResults += [xml](Get-Content -Raw -Path $TestResultsFile)
        }
        finally {
            Pop-Location
        }
    }

    $FailedTestCount = 0
    $TestResults | ForEach-Object { $FailedTestCount += ([int]$_.'test-results'.failures) }
    if ($FailedTestCount) {
        throw "$FailedTestCount tests failed"
    }
}
# tests if we should run a daily build
# returns true if the build is scheduled
# or is a pushed tag
function Test-DailyBuild {

    # https://docs.travis-ci.com/user/environment-variables/
    # TRAVIS_EVENT_TYPE: Indicates how the build was triggered.
    # One of push, pull_request, api, cron.
    $TRAVIS_EVENT_TYPE = [System.Environment]::GetEnvironmentVariable('TRAVIS_EVENT_TYPE')
    if (($env:PS_DAILY_BUILD -eq 'True') -or
        ($env:APPVEYOR_SCHEDULED_BUILD -eq 'True') -or
        ($env:APPVEYOR_REPO_TAG_NAME) -or
        ($TRAVIS_EVENT_TYPE -eq 'cron') -or
        ($TRAVIS_EVENT_TYPE -eq 'api')) {
        return $true
    }

    return $false
}
function New-ModulePSMFile {
    $moduleFile = New-Item -Path $ArtifactRoot\PowerShellGet\PSModule.psm1 -ItemType File -Force

    # Add the localized data
    'Import-LocalizedData LocalizedData -filename PSGet.Resource.psd1' | Out-File -FilePath $moduleFile
    # Add the first part of the distributed .psm1 file from template.
    Get-Content -Path "$ModuleRoot\private\modulefile\PartOne.ps1" | Out-File -FilePath $moduleFile -Append

    # Add a region and write out the private functions.
    "`n#region Private Functions" | Out-File -FilePath $moduleFile -Append
    Get-Content $PrivateFunctions | Out-String | Out-File -FilePath $moduleFile -Append
    "#endregion`n" | Out-File -FilePath $moduleFile -Append

    # Add a region and write out the public functions
    "#region Public Functions" | Out-File -FilePath $moduleFile -Append
    Get-Content $PublicPSGetFunctions | Out-String | Out-File -FilePath $moduleFile -Append
    Get-Content $PublicProviderFunctions | Out-String | Out-File -FilePath $moduleFile -Append
    "#endregion`n" | Out-File -FilePath $moduleFile -Append

    # Build a string to export only /public/psmexports functions from the PSModule.psm1 file.
    $publicFunctionNames = $PublicProviderFunctions.BaseName + $PublicPSGetFunctions.BaseName
    foreach ($publicFunction in $publicFunctionNames) {
        $functionNameString += "$publicFunction,"
    }

    $functionNameString = $functionNameString.TrimEnd(",")
    $functionNameString = "Export-ModuleMember -Function $functionNameString`n"

    # Add the export module member string to the module file.
    $functionNameString | Out-File -FilePath $moduleFile -Append

    # Add the remaining part of the psm1 file from template.
    Get-Content -Path "$ModuleRoot\private\modulefile\PartTwo.ps1" | Out-File -FilePath $moduleFile -Append

    # Copy the DSC resources into the dist folder.
    Copy-Item -Path "$script:DscModuleRoot\DSCResources" -Destination "$script:ArtifactRoot\PowerShellGet" -Recurse
    Copy-Item -Path "$script:DscModuleRoot\Modules" -Destination "$script:ArtifactRoot\PowerShellGet" -Recurse
}
function Update-ModuleManifestFunctions {
    # Update the psd1 file with the /public/psgetfunctions
    # Update-ModuleManifest is not used because a) it is not availabe for ps version <5.0 and b) it is destructive.
    # First a helper method removes the functions and replaces with the standard FunctionsToExport = @()
    # then this string is replaced by another string built from /public/psgetfunctions

    $ManifestFile = "$ModuleRoot\PowerShellGet.psd1"

    # Call helper function to replace with an empty FunctionsToExport = @()
    Remove-ModuleManifestFunctions -Path $ManifestFile

    $ManifestFileContent = Get-Content -Path "$ManifestFile"

    # FunctionsToExport string needs to be array definition with function names surrounded by quotes.
    $formatedFunctionNames = @()
    foreach ($function in $PublicPSGetFunctions.basename) {
        $function = "`'$function`'"
        $formatedFunctionNames += $function
    }

    # Tabbing and new lines to make the psd1 consistent
    $formatedFunctionNames = $formatedFunctionNames -join ",`n`t"
    $ManifestFunctionExportString = "FunctionsToExport = @(`n`t$formatedFunctionNames)`n"

    # Do the string replacement in the manifest file with the formated function names.
    $ManifestFileContent = $ManifestFileContent.Replace('FunctionsToExport = @()', $ManifestFunctionExportString)
    Set-Content -Path "$ManifestFile" -Value $ManifestFileContent
}
function Remove-ModuleManifestFunctions ($Path) {
    # Utility method to remove the list of functions from a manifest. This is specific to this modules manifest and
    # assumes the next item in the manifest file after the functions is a comment containing 'VariablesToExport'.

    $rawFile = Get-Content -Path $Path -Raw
    $arrFile = Get-Content -Path $Path

    $functionsStartPos = ($arrFile | Select-String -Pattern 'FunctionsToExport =').LineNumber - 1
    $functionsEndPos = ($arrFile | Select-String -Pattern 'VariablesToExport =').LineNumber - 2

    $functionsExportString = $arrFile[$functionsStartPos..$functionsEndPos] | Out-String

    $rawFile = $rawFile.Replace($functionsExportString, "FunctionsToExport = @()`n")

    Set-Content -Path $Path -Value $rawFile
}
function Publish-ModuleArtifacts {

    if (Test-Path -Path $ArtifactRoot) {
        Remove-Item -Path $ArtifactRoot -Recurse -Force
    }

    New-Item -Path $ArtifactRoot -ItemType Directory | Out-Null

    # Copy the module into the dist folder
    Copy-Item -Path $ModuleRoot -Destination $ArtifactRoot -Recurse

    # Remove the private and public folders from the distribution and the developer .psm1 file.
    Remove-Item -Path $ArtifactRoot\PowerShellGet\public -Recurse -Force
    Remove-Item -Path $ArtifactRoot\PowerShellGet\PSModule.psm1 -Force
    Remove-Item -Path $ArtifactRoot\PowerShellGet\private -Recurse -Force

    # Construct the distributed .psm1 file.
    New-ModulePSMFile

    # Package the module in /dist
    $zipFileName = "PowerShellGet.zip"
    $artifactZipFile = Join-Path -Path $ArtifactRoot -ChildPath $zipFileName
    $tempZipfile = Join-Path -Path $TempPath -ChildPath $zipFileName

    if ($PSEdition -ne 'Core') {
        Add-Type -assemblyname System.IO.Compression.FileSystem
    }

    if (Test-Path -Path $tempZipfile) {
        Remove-Item -Path $tempZipfile -Force
    }

    Write-Verbose "Zipping module artifacts in $ArtifactRoot"
    [System.IO.Compression.ZipFile]::CreateFromDirectory($ArtifactRoot, $tempZipfile)

    Move-Item -Path $tempZipfile -Destination $artifactZipFile -Force
}
function Install-PublishedModule {
    # function to install the merged module artifact from /dist into the module path.
    Param (
        [switch]$LocalDevInstall
    )

    $moduleFolder = Join-Path -Path $ArtifactRoot -ChildPath 'PowerShellGet'
    $manifestFullName = Join-Path -Path $moduleFolder -ChildPath "PowerShellGet.psd1" -ErrorAction Ignore
    $PowerShellGetModuleInfo = Test-ModuleManifest $manifestFullName
    $ModuleVersion = "$($PowerShellGetModuleInfo.Version)"
    $InstallLocation = Join-Path -Path $AllUsersModulesPath -ChildPath 'PowerShellGet'

    if ($LocalDevInstall) {
        Write-Verbose -Message "Local dev installation specified."
        $versionUnderDevelopment = "$ModuleVersion.9999"
        $rawManifest = Get-Content -Path $manifestFullName -Raw
        $newContent = $rawManifest -replace "    ModuleVersion     = '$ModuleVersion'", "    ModuleVersion     = '$versionUnderDevelopment'"
        Set-Content -Path $manifestFullName -Value $newContent
        $ModuleVersion = $versionUnderDevelopment
    }

    if (($script:PowerShellEdition -eq 'Core') -or ($PSVersionTable.PSVersion -ge '5.0.0')) {
        $InstallLocation = Join-Path -Path $InstallLocation -ChildPath $ModuleVersion
    }
    New-Item -Path $InstallLocation -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$moduleFolder\*" -Destination $InstallLocation -Recurse -Force

    Write-Verbose -Message "Copied module artifacts from $moduleFolder merged module artifact to`n$InstallLocation"
}

function Install-DevelopmentModule {
    Update-ModuleManifestFunctions
    Publish-ModuleArtifacts
    Install-PublishedModule -LocalDevInstall
}

function Uninstall-DevelopmentModule {
    $manifestFullName = Join-Path -Path $ModuleRoot -ChildPath "PowerShellGet.psd1" -ErrorAction Ignore
    $PowerShellGetModuleInfo = Test-ModuleManifest $manifestFullName
    $ModuleVersion = "$($PowerShellGetModuleInfo.Version)"
    $InstallLocation = Join-Path -Path $AllUsersModulesPath -ChildPath 'PowerShellGet'
    $versionUnderDevelopment = "$ModuleVersion.9999"

    if (($script:PowerShellEdition -eq 'Core') -or ($PSVersionTable.PSVersion -ge '5.0.0')) {
        $InstallLocation = Join-Path -Path $InstallLocation -ChildPath $versionUnderDevelopment
        Remove-Item $InstallLocation -Recurse -Force
    }

}

<#
    .SYNOPSIS
        This function changes the folder location in the current session to
        the folder that is the root for the DSC resources
        ('$env:APPVEYOR_BUILD_FOLDER/PowerShellGet').

    .NOTES
        Used by other helper functions when testing DSC resources in AppVeyor.
#>
function Set-AppVeyorLocationDscResourceModuleBuildFolder {
    [CmdletBinding()]
    param()

    $script:originalBuildFolder = $env:APPVEYOR_BUILD_FOLDER
    $env:APPVEYOR_BUILD_FOLDER = Join-Path -Path $env:APPVEYOR_BUILD_FOLDER -ChildPath 'DSC'
    Set-Location -Path $env:APPVEYOR_BUILD_FOLDER
}

<#
    .SYNOPSIS
        This function changes the folder location in the current session back
        to the original build folder that is the root for the module
        ('$env:APPVEYOR_BUILD_FOLDER').

    .NOTES
        Used by other helper functions when testing DSC resources in AppVeyor.
#>
function Set-AppVeyorLocationOriginalBuildFolder {
    [CmdletBinding()]
    param()

    $env:APPVEYOR_BUILD_FOLDER = $script:originalBuildFolder
    Set-Location -Path $env:APPVEYOR_BUILD_FOLDER
}

<#
    .SYNOPSIS
        This function removes any present PowerShellGet modules in $env:PSModulePath's.

    .NOTES
        Used by other helper functions when testing DSC resources in AppVeyor.
#>
function Remove-ModulePowerShellGet {
    [CmdletBinding()]
    param()

    Remove-Module -Name PowerShellGet -Force
    Get-Module -Name PowerShellGet -ListAvailable | ForEach-Object {
        Remove-Item -Path (Split-Path -Path $_.Path -Parent) -Recurse -Force
    }
}


<#
    .SYNOPSIS
        This function runs all the necessary install steps to prepare the
        environment for testing of DSC resources.

    .NOTES
        Used when testing DSC resources in AppVeyor.
#>
function Invoke-DscPowerShellGetAppVeyorInstallTask {
    [CmdletBinding()]
    param()

    # Temporary change the build folder during install phase of DscResource.Test framework.
    Set-AppVeyorLocationDscResourceModuleBuildFolder

    try {
        Import-Module -Name "$env:APPVEYOR_BUILD_FOLDER\DscResource.Tests\AppVeyor.psm1"
        Invoke-AppveyorInstallTask

        # Remove any present PowerShellGet modules so DSC integration tests don't see multiple modules.
        Remove-ModulePowerShellGet
    }
    catch {
        throw $_
    }
    finally {
        Set-AppVeyorLocationOriginalBuildFolder
    }

    Update-ModuleManifestFunctions
    Publish-ModuleArtifacts
    # Deploy PowerShellGet module so DSC integration tests uses the correct one.
    Install-PublishedModule

    Get-Module -Name PowerShellGet -ListAvailable | ForEach-Object {
        $pathNumber += 1
        Write-Verbose -Message ('Found module path {0}: {1}' -f $pathNumber, $_.Path) -Verbose
    }
}

<#
    .SYNOPSIS
        This function starts the test step and tests all of DSC resources.

    .NOTES
        Used when testing DSC resources in AppVeyor.
#>
function Invoke-DscPowerShellGetAppVeyorTestTask {
    [CmdletBinding()]
    param()

    # Temporary change the build folder during testing of the DSC resources.
    Set-AppVeyorLocationDscResourceModuleBuildFolder

    try {
        Import-Module -Name "$env:APPVEYOR_BUILD_FOLDER\DscResource.Tests\AppVeyor.psm1"
        Invoke-AppveyorTestScriptTask -CodeCoverage -ExcludeTag @()
    }
    catch {
        throw $_
    }
    finally {
        Set-AppVeyorLocationOriginalBuildFolder
    }
}

<#
    .SYNOPSIS
        This function starts the deploy step for the DSC resources. The
        deploy step only publishes the examples to the PowerShell Gallery
        so they show up in the gallery part of Azure State Configuration.

    .NOTES
        Publishes using the account 'dscresourcekit' which is owned by
        PowerShell DSC Team (DSC Resource Kit).
        Only runs on the master branch.
#>
function Invoke-DscPowerShellGetAppVeyorDeployTask {
    [CmdletBinding()]
    param()

    <#
        Removes any present PowerShellGet modules so deployment
        don't see multiple modules.
    #>
    Remove-ModulePowerShellGet

    <#
        Removes the source folder so when the deploy step copies
        the module folder it only see the resource in the 'dist'
        folder created by the AppVeyor install task.
    #>
    Remove-Item -Path (Join-Path -Path $env:APPVEYOR_BUILD_FOLDER -ChildPath 'src') -Recurse -Force

    # Temporary change the build folder during testing of the DSC resources.
    Set-AppVeyorLocationDscResourceModuleBuildFolder

    try {
        Import-Module -Name "$env:APPVEYOR_BUILD_FOLDER\DscResource.Tests\AppVeyor.psm1"
        Invoke-AppVeyorDeployTask -OptIn @('PublishExample') -ModuleRootPath (Split-Path -Path $env:APPVEYOR_BUILD_FOLDER -Parent)
    }
    catch {
        throw $_
    }
    finally {
        Set-AppVeyorLocationOriginalBuildFolder
    }
}
