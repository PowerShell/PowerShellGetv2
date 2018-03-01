#region script variables
$script:PowerShellGet = 'PowerShellGet'
$script:IsInbox = $PSHOME.EndsWith('\WindowsPowerShell\v1.0', [System.StringComparison]::OrdinalIgnoreCase)
$script:IsWindows = (-not (Get-Variable -Name IsWindows -ErrorAction Ignore)) -or $IsWindows
$script:IsLinux = (Get-Variable -Name IsLinux -ErrorAction Ignore) -and $IsLinux 
$script:IsMacOS = (Get-Variable -Name IsMacOS -ErrorAction Ignore) -and $IsMacOS
$script:IsCoreCLR = $PSVersionTable.ContainsKey('PSEdition') -and $PSVersionTable.PSEdition -eq 'Core'

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

# AppVeyor.yml sets a value to $env:PowerShellEdition variable, 
# otherwise set $script:PowerShellEdition value based on the current PowerShell Edition.
$script:PowerShellEdition = [System.Environment]::GetEnvironmentVariable("PowerShellEdition")
if(-not $script:PowerShellEdition) {
    if($script:IsCoreCLR) { 
        $script:PowerShellEdition = 'Core'
    } else { 
        $script:PowerShellEdition = 'Desktop'
    }
}
Write-Host "PowerShellEdition value: $script:PowerShellEdition"
#endregion script variables

function Install-Dependencies {
    # Update build title for daily builds
    if($script:IsWindows -and (Test-DailyBuild)) {        
        if($env:APPVEYOR_PULL_REQUEST_TITLE)
        {
            $buildName += $env:APPVEYOR_PULL_REQUEST_TITLE
        } else {
            $buildName += $env:APPVEYOR_REPO_COMMIT_MESSAGE
        }

        if(-not ($buildName.StartsWith("[Daily]", [System.StringComparison]::OrdinalIgnoreCase))) {
            Update-AppveyorBuild -message "[Daily] $buildName"
        }
    }
}

function Get-PSHome {
    $PowerShellHome = $PSHOME

    # Install PowerShell Core on Windows.
    if(($script:PowerShellEdition -eq 'Core') -and $script:IsWindows)
    {
        $InstallPSCoreUrl = 'https://aka.ms/install-pscore'
        $InstallPSCorePath = Microsoft.PowerShell.Management\Join-Path -Path $PSScriptRoot -ChildPath 'install-powershell.ps1'
        Microsoft.PowerShell.Utility\Invoke-RestMethod -Uri $InstallPSCoreUrl -OutFile $InstallPSCorePath

        $PowerShellHome = "$env:SystemDrive\PowerShellCore"
        & $InstallPSCorePath -Destination $PowerShellHome -Daily

        if(-not $PowerShellHome -or -not (Microsoft.PowerShell.Management\Test-Path -Path $PowerShellHome -PathType Container))
        {
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

    if(-not $IsFullTestPass){
        $IsFullTestPass = Test-DailyBuild
    }
    Write-Host -ForegroundColor Green "`$IsFullTestPass value $IsFullTestPass"
    Write-Host -ForegroundColor Green "Test-DailyBuild: $(Test-DailyBuild)"

    $env:APPVEYOR_TEST_PASS = $true
    $ClonedProjectPath = Resolve-Path "$PSScriptRoot\.."    
    $PowerShellGetTestsPath = "$ClonedProjectPath\Tests\"
    $PowerShellHome = Get-PSHome
    if($script:IsWindows){
        if ($script:PowerShellEdition -eq 'Core') {
            $PowerShellExePath = Join-Path -Path $PowerShellHome -ChildPath 'pwsh.exe'
        }
        else {
            $PowerShellExePath = Join-Path -Path $PowerShellHome -ChildPath 'PowerShell.exe'
        }
    } else {
        $PowerShellExePath = 'pwsh'
    }

    # Bootstrap NuGet.exe
    $NuGetExeName = 'NuGet.exe'
    $NugetExeFilePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $NuGetExeName
    
    if(-not (Test-Path -Path $NugetExeFilePath -PathType Leaf)) {
        if(-not (Microsoft.PowerShell.Management\Test-Path -Path $script:PSGetProgramDataPath))
        {
            $null = Microsoft.PowerShell.Management\New-Item -Path $script:PSGetProgramDataPath -ItemType Directory -Force
        }
        
        # Download the NuGet.exe from https://nuget.org/NuGet.exe
        Microsoft.PowerShell.Utility\Invoke-WebRequest -Uri https://nuget.org/NuGet.exe -OutFile $NugetExeFilePath
    }

    Get-ChildItem -Path $NugetExeFilePath -File

    # Test Environment
    # - PowerShellGet from Current branch 
    # - PowerShellGet packaged with PowerShellCore build: 
    #   -- Where PowerShellGet module was installed from MyGet feed https://powershell.myget.org/F/powershellmodule/api/v2/
    #   -- This option is used only for Daily builds
    $TestScenarios = @()
    if(($script:PowerShellEdition -eq 'Core') -and $IsFullTestPass -and $script:IsWindows){
        # Disabled NoUpdate test scenario on PWSH
        #$TestScenarios += 'NoUpdate'
    }
    # We should run PSCore_PSGet_TestRun first before updating the PowerShellGet module from current branch.
    $TestScenarios += 'Current'

    $PesterTag = '' # Conveys all test priorities
    if(-not $IsFullTestPass){
        $PesterTag = 'BVT' # Only BVTs
    }

    $TestResults = @()

    foreach ($TestScenario in $TestScenarios){    
        
        Write-Host "TestScenario: $TestScenario"

        if($TestScenario -eq 'Current') {
            $AllUsersModulesPath = $script:ProgramFilesModulesPath
            if(($script:PowerShellEdition -eq 'Core') -and $script:IsWindows)
            {
                $AllUsersModulesPath = Microsoft.PowerShell.Management\Join-Path -Path $PowerShellHome -ChildPath 'Modules'
            }

            # Install latest PackageManagement from Gallery
            $OneGetModuleName = 'PackageManagement'
            $OneGetModuleInfo = Get-Module -ListAvailable -Name $OneGetModuleName | Select-Object -First 1
            if ($OneGetModuleInfo)
            {
                $NuGetProvider = Get-PackageProvider | Where-Object { $_.Name -eq 'NuGet' }
                if(-not $NuGetProvider) {
                    Install-PackageProvider -Name NuGet -Force
                }

                $LatestOneGetInPSGallery = Find-Module -Name $OneGetModuleName
                if($LatestOneGetInPSGallery.Version -gt $OneGetModuleInfo.Version) {
                    Install-Module -InputObject $LatestOneGetInPSGallery -Force
                }
            }
            else
            {
                # Install latest PackageManagement module from PSGallery
                $TempModulePath = Microsoft.PowerShell.Management\Join-Path -Path $script:TempPath -ChildPath "$(Get-Random)"
                $null = Microsoft.PowerShell.Management\New-Item -Path $TempModulePath -Force -ItemType Directory
                $OneGetModuleName = 'PackageManagement'
                try
                {
                    & $NugetExeFilePath install $OneGetModuleName -source https://www.powershellgallery.com/api/v2 -outputDirectory $TempModulePath -verbosity detailed
                    $OneGetWithVersion = Microsoft.PowerShell.Management\Get-ChildItem -Path $TempModulePath -Directory
                    $OneGetVersion = ($OneGetWithVersion.Name.Split('.',2))[1]
        
                    $OneGetModulePath = Microsoft.PowerShell.Management\Join-Path -Path  $AllUsersModulesPath -ChildPath $OneGetModuleName
                    if($PSVersionTable.PSVersion -ge '5.0.0')
                    {
                        $OneGetModulePath = Microsoft.PowerShell.Management\Join-Path -Path $OneGetModulePath -ChildPath $OneGetVersion
                    }
        
                    $null = Microsoft.PowerShell.Management\New-Item -Path $OneGetModulePath -Force -ItemType Directory
                    Microsoft.PowerShell.Management\Copy-Item -Path "$($OneGetWithVersion.FullName)\*" -Destination "$OneGetModulePath\" -Recurse -Force
                    Get-Module -ListAvailable -Name $OneGetModuleName | Microsoft.PowerShell.Core\Where-Object {$_.Version -eq $OneGetVersion}
                }
                finally
                {
                    Remove-Item -Path $TempModulePath -Recurse -Force
                }
            }
        
            # Copy OneGet and PSGet modules to PSHOME    
            $PowerShellGetSourcePath = Microsoft.PowerShell.Management\Join-Path -Path $ClonedProjectPath -ChildPath $script:PowerShellGet
            $PowerShellGetModuleInfo = Test-ModuleManifest "$PowerShellGetSourcePath\PowerShellGet.psd1" -ErrorAction Ignore
            $ModuleVersion = "$($PowerShellGetModuleInfo.Version)"

            $InstallLocation =  Microsoft.PowerShell.Management\Join-Path -Path $AllUsersModulesPath -ChildPath 'PowerShellGet'

            if(($script:PowerShellEdition -eq 'Core') -or ($PSVersionTable.PSVersion -ge '5.0.0'))
            {
                $InstallLocation = Microsoft.PowerShell.Management\Join-Path -Path $InstallLocation -ChildPath $ModuleVersion
            }
            $null = New-Item -Path $InstallLocation -ItemType Directory -Force
            Microsoft.PowerShell.Management\Copy-Item -Path "$PowerShellGetSourcePath\*" -Destination $InstallLocation -Recurse -Force

            Write-Host "Copied latest PowerShellGet to $InstallLocation"
        }

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
                $ValueWithUniqueEntries = ([System.Environment]::GetEnvironmentVariable('PSModulePath', [System.EnvironmentVariableTarget]::Process) -split ';' | %{$_.Trim('\\')} | Select-Object -Unique) -join ';'
                [System.Environment]::SetEnvironmentVariable('PSModulePath', $ValueWithUniqueEntries, [System.EnvironmentVariableTarget]::Process)

                # Current User
                $ValueWithUniqueEntries = ([System.Environment]::GetEnvironmentVariable('PSModulePath', [System.EnvironmentVariableTarget]::User) -split ';' | %{$_.Trim('\\')} | Select-Object -Unique) -join ';'
                [System.Environment]::SetEnvironmentVariable('PSModulePath', $ValueWithUniqueEntries, [System.EnvironmentVariableTarget]::User)

                # Current Machine
                $ValueWithUniqueEntries = ([System.Environment]::GetEnvironmentVariable('PSModulePath', [System.EnvironmentVariableTarget]::Machine) -split ';' | %{$_.Trim('\\')} | Select-Object -Unique) -join ';'
                [System.Environment]::SetEnvironmentVariable('PSModulePath', $ValueWithUniqueEntries, [System.EnvironmentVariableTarget]::Machine)

                Write-Host "PSModulePath value after removing the duplicate entries:"
                $env:PSModulePath;
            }
'@

        try {
            Push-Location $PowerShellGetTestsPath

            $TestResultsFile = Microsoft.PowerShell.Management\Join-Path -Path $PowerShellGetTestsPath -ChildPath "TestResults$TestScenario.xml"
            & $PowerShellExePath -Command "`$env:PSModulePath = (`$env:PSModulePath -split ';' | %{`$_.Trim('\\')} | Select-Object -Unique) -join ';' ;
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

    # Packing
    $stagingDirectory = Microsoft.PowerShell.Management\Split-Path $ClonedProjectPath.Path -Parent
    $zipFile = Microsoft.PowerShell.Management\Join-Path $stagingDirectory "$(Split-Path $ClonedProjectPath.Path -Leaf).zip"
    
    if($PSEdition -ne 'Core')
    {
        Add-Type -assemblyname System.IO.Compression.FileSystem
    }

    Write-Verbose "Zipping $ClonedProjectPath into $zipFile"
    [System.IO.Compression.ZipFile]::CreateFromDirectory($ClonedProjectPath.Path, $zipFile)

    $FailedTestCount = 0
    $TestResults | ForEach-Object { $FailedTestCount += ([int]$_.'test-results'.failures) }
    if ($FailedTestCount)
    {
        throw "$FailedTestCount tests failed"
    }
}

# tests if we should run a daily build
# returns true if the build is scheduled
# or is a pushed tag
function Test-DailyBuild
{
    # https://docs.travis-ci.com/user/environment-variables/
    # TRAVIS_EVENT_TYPE: Indicates how the build was triggered.
    # One of push, pull_request, api, cron.
    $TRAVIS_EVENT_TYPE = [System.Environment]::GetEnvironmentVariable('TRAVIS_EVENT_TYPE')    
    if(($env:PS_DAILY_BUILD -eq 'True') -or 
       ($env:APPVEYOR_SCHEDULED_BUILD -eq 'True') -or 
       ($env:APPVEYOR_REPO_TAG_NAME) -or
       ($TRAVIS_EVENT_TYPE -eq 'cron') -or 
       ($TRAVIS_EVENT_TYPE -eq 'api'))
    {
        return $true
    }

    return $false
}
