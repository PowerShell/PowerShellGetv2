#region script variables
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
    if($script:PowerShellEdition -eq 'Desktop') {
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

        Get-ChildItem $NugetExeFilePath -File
        
        if(-not (Get-Module -ListAvailable Pester))
        {
            & $NugetExeFilePath install pester -source https://www.powershellgallery.com/api/v2 -outputDirectory $script:ProgramFilesModulesPath -ExcludeVersion
        }

        $AllUsersModulesPath = $script:ProgramFilesModulesPath
        # Install latest PackageManagement module from PSGallery
        $TempModulePath = Microsoft.PowerShell.Management\Join-Path -Path $script:TempPath -ChildPath "$(Get-Random)"
        $null = Microsoft.PowerShell.Management\New-Item -Path $TempModulePath -Force -ItemType Directory
        $OneGetModuleName = 'PackageManagement'
        try
        {
            & $NugetExeFilePath install $OneGetModuleName -source https://dtlgalleryint.cloudapp.net/api/v2 -outputDirectory $TempModulePath -verbosity detailed
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

    # Install PowerShell Core MSI on Windows.
    if(($script:PowerShellEdition -eq 'Core') -and $script:IsWindows)
    {
        $PowerShellMsiPath = Get-PowerShellCoreBuild -AppVeyorProjectName 'PowerShell'
        $PowerShellInstallPath = "$env:SystemDrive\PowerShellCore"
        <#
        $PowerShellMsiUrl = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.11/PowerShell_6.0.0.11-alpha.11-win81-x64.msi'
        $PowerShellMsiName = 'PowerShell_6.0.0.11-alpha.11-win81-x64.msi'
        $PowerShellMsiPath = Microsoft.PowerShell.Management\Join-Path -Path $PSScriptRoot -ChildPath $PowerShellMsiName
        Microsoft.PowerShell.Utility\Invoke-WebRequest -Uri $PowerShellMsiUrl -OutFile $PowerShellMsiPath
        #>
        Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList "/qb INSTALLFOLDER=$PowerShellInstallPath /i $PowerShellMsiPath" -Wait
        
        $PowerShellVersionPath = Get-ChildItem -Path $PowerShellInstallPath -Attributes Directory | Select-Object -First 1 -ErrorAction Ignore
        $PowerShellHome = $null
        if ($PowerShellVersionPath) {
            $PowerShellHome = $PowerShellVersionPath.FullName
        }
        
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
        $PowerShellExePath = Join-Path -Path $PowerShellHome -ChildPath 'PowerShell.exe'
    } else {
        $PowerShellExePath = 'powershell'
    }

    # Test Environment
    # - PowerShellGet from Current branch 
    # - PowerShellGet packaged with PowerShellCore build: 
    #   -- Where PowerShellGet module was installed from MyGet feed https://powershell.myget.org/F/powershellmodule/api/v2/
    #   -- This option is used only for Daily builds
    $TestScenarios = @()
    if(($script:PowerShellEdition -eq 'Core') -and $IsFullTestPass -and $script:IsWindows){
        $TestScenarios += 'NoUpdate'
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

function Get-PowerShellCoreBuild {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $AppVeyorProjectName = 'powershell-f975h',

        [Parameter()]
        [string]
        $GitHubBranchName = 'master',

        [Parameter()]
        [string]
        $Destination = 'C:\projects'
    )

    $appVeyorConstants =  @{ 
        AccountName = 'powershell'
        ApiUrl = 'https://ci.appveyor.com/api'
    }

    $foundGood = $false
    $records = 20
    $lastBuildId = $null
    $project = $null

    while(!$foundGood)
    {
        $startBuildIdString = [string]::Empty
        if($lastBuildId)
        {
            $startBuildIdString = "&startBuildId=$lastBuildId"
        }


        $project = Invoke-RestMethod -Method Get -Uri "$($appVeyorConstants.ApiUrl)/projects/$($appVeyorConstants.AccountName)/$AppVeyorProjectName/history?recordsNumber=$records$startBuildIdString&branch=$GitHubBranchName"

        foreach($build in $project.builds)
        {
            $version = $build.version
            $status = $build.status
            if($status -ieq 'success')
            {
                Write-Verbose "Using PowerShell Version: $version"

                $foundGood = $true

                Write-Host "Uri = $($appVeyorConstants.ApiUrl)/projects/$($appVeyorConstants.AccountName)/$AppVeyorProjectName/build/$version"
                $project = Invoke-RestMethod -Method Get -Uri "$($appVeyorConstants.ApiUrl)/projects/$($appVeyorConstants.AccountName)/$AppVeyorProjectName/build/$version" 
                break
            }
            else 
            {
                Write-Warning "There is a newer PowerShell build, $version, which is in status: $status"
            }
        }
    }

    # get project with last build details
    if (-not $project) {

        throw "Cannot find a good build for $GitHubBranchName"
    }

    # we assume here that build has a single job
    # get this job id

    $jobId = $project.build.jobs[0].jobId
    Write-Verbose "jobId=$jobId"
    
    Write-Verbose "$project.build.jobs[0]"

    $artifactsUrl = "$($appVeyorConstants.ApiUrl)/buildjobs/$jobId/artifacts"

    Write-Verbose "Uri=$artifactsUrl"
    $artifacts = Invoke-RestMethod -Method Get -Uri $artifactsUrl 

    if (-not $artifacts) {
        throw "Cannot find artifacts in $artifactsUrl"
    }

    # Get PowerShellCore.msi artifacts for Windows
    $artifacts = $artifacts | where-object { $_.filename -like '*powershell*.msi'}
    $returnArtifactsLocation = @{}

    #download artifacts to a temp location
    foreach($artifact in $artifacts)
    {
        $artifactPath = $artifact[0].fileName
        $artifactFileName = Split-Path -Path $artifactPath -Leaf

        # artifact will be downloaded as 
        $tempLocalArtifactPath = "$Destination\Temp-$artifactFileName-$jobId.msi"
        $localArtifactPath = "$Destination\$artifactFileName-$jobId.msi"
        if(!(Test-Path $localArtifactPath))
        {
            # download artifact
            # -OutFile - is local file name where artifact will be downloaded into

            try 
            {
                Write-Host "PowerShell MSI URL: $($appVeyorConstants.ApiUrl)/buildjobs/$jobId/artifacts/$artifactPath"
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Method Get -Uri "$($appVeyorConstants.ApiUrl)/buildjobs/$jobId/artifacts/$artifactPath" `
                    -OutFile $tempLocalArtifactPath  -UseBasicParsing -DisableKeepAlive

                Move-Item -Path $tempLocalArtifactPath -Destination $localArtifactPath   
            } 
            finally
            {
                $ProgressPreference = 'Continue'
                if(test-path $tempLocalArtifactPath)
                {
                    remove-item $tempLocalArtifactPath
                }
            } 
        }
    }

    Write-Verbose $localArtifactPath
    return $localArtifactPath
}
