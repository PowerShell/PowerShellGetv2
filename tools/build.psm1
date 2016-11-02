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

$script:PowerShellEdition = [System.Environment]::GetEnvironmentVariable("PowerShellEdition")
if($script:IsWindows)
{
    Write-Host "PowerShellEdition value: $script:PowerShellEdition"
}

function Install-Dependencies {
    if($script:PowerShellEdition -eq 'Desktop') {
        # Download the NuGet.exe from http://nuget.org/NuGet.exe
        $NuGetExeName = 'NuGet.exe'
        if(-not (Microsoft.PowerShell.Management\Test-Path -Path $script:PSGetProgramDataPath))
        {
            $null = Microsoft.PowerShell.Management\New-Item -Path $script:PSGetProgramDataPath -ItemType Directory -Force
        }
        $NugetExeFilePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $NuGetExeName
        Microsoft.PowerShell.Utility\Invoke-WebRequest -Uri http://nuget.org/NuGet.exe -OutFile $NugetExeFilePath
        Get-ChildItem $NugetExeFilePath -File
        
        if(-not (Get-Module -ListAvailable Pester))
        {
            nuget install pester -source https://www.powershellgallery.com/api/v2 -outputDirectory $script:ProgramFilesModulesPath -ExcludeVersion
        }

        $AllUsersModulesPath = $script:ProgramFilesModulesPath
        <# TODO: Install latest version of OneGet on PSCore
        if(($script:PowerShellEdition -eq 'Core') -and $script:IsWindows)
        {
            $AllUsersModulesPath = Microsoft.PowerShell.Management\Join-Path -Path (Get-PSHome) -ChildPath 'Modules'
        }
        #>

        # Install latest PackageManagement module from PSGallery
        $TempModulePath = Microsoft.PowerShell.Management\Join-Path -Path $script:TempPath -ChildPath "$(Get-Random)"
        $null = Microsoft.PowerShell.Management\New-Item -Path $TempModulePath -Force -ItemType Directory
        $OneGetModuleName = 'PackageManagement'
        try
        {
            nuget install $OneGetModuleName -source https://dtlgalleryint.cloudapp.net/api/v2 -outputDirectory $TempModulePath -verbosity detailed
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
}

function Get-PSHome {
    $PowerShellFolder = $PSHOME

    # install powershell core if test framework is coreclr
    if(($script:PowerShellEdition -eq 'Core') -and $script:IsWindows)
    {
        if(-not (Get-PackageProvider -Name PSL -ErrorAction Ignore)) {
            $null = Install-PackageProvider -Name PSL -Force
        }

        $PowerShellCore = (Get-Package -Provider PSL -Name PowerShell -ErrorAction Ignore)
        if ($PowerShellCore)
        {
            Write-Warning ("PowerShell already installed" -f $PowerShellCore.Name)
        }
        else
        {   
            $PowerShellCore = Install-Package PowerShell -Provider PSL -Force
        }

        $PowerShellVersion = $PowerShellCore.Version
        Write-Host ("PowerShell Version '{0}'" -f $PowerShellVersion)

        $PowerShellFolder = "$Env:ProgramFiles\PowerShell\$PowerShellVersion"
        Write-Host ("PowerShell Folder '{0}'" -f $PowerShellFolder)
    }

    return $PowerShellFolder
}

function Invoke-PowerShellGetTest {
    $env:APPVEYOR_TEST_PASS = $true
    $ClonedProjectPath = Resolve-Path "$PSScriptRoot\.."    
    $PowerShellGetTestsPath = "$ClonedProjectPath\Tests\"
    $PowerShellHome = Get-PSHome
    if($script:IsWindows){
        $PowerShellExePath = Join-Path -Path $PowerShellHome -ChildPath 'PowerShell.exe'
    } else {
        $PowerShellExePath = 'powershell'
    }

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

    if($PSVersionTable.PSVersion -ge '5.0.0')
    {
        $InstallLocation = Microsoft.PowerShell.Management\Join-Path -Path $InstallLocation -ChildPath $ModuleVersion
    }
    $null = New-Item -Path $InstallLocation -ItemType Directory -Force
    Microsoft.PowerShell.Management\Copy-Item -Path "$PowerShellGetSourcePath\*" -Destination $InstallLocation -Recurse -Force

    & $PowerShellExePath -Command @'
        $env:PSModulePath;
        $PSVersionTable;
        Get-PackageProvider;
        Get-PSRepository;
        Get-Module;
'@

    try {
        Push-Location $PowerShellGetTestsPath

        $TestResultsFile = Microsoft.PowerShell.Management\Join-Path -Path $PowerShellGetTestsPath -ChildPath 'TestResults.xml'
        & $PowerShellExePath -Command "Invoke-Pester -Script $PowerShellGetTestsPath -OutputFormat NUnitXml -OutputFile $TestResultsFile -PassThru -Tag BVT"

        $TestResults = [xml](Get-Content -Raw -Path $TestResultsFile)
        if ([int]$TestResults.'test-results'.failures -gt 0)
        {
            throw "$($TestResults.'test-results'.failures) tests failed"
        }
    }
    finally {
        Pop-Location
    }

    # Packing
    $stagingDirectory = Microsoft.PowerShell.Management\Split-Path $ClonedProjectPath.Path -Parent
    $zipFile = Microsoft.PowerShell.Management\Join-Path $stagingDirectory "$(Split-Path $ClonedProjectPath.Path -Leaf).zip"
    
    if($PSEdition -eq 'Desktop')
    {
        Add-Type -assemblyname System.IO.Compression.FileSystem
    }

    Write-Verbose "Zipping $ClonedProjectPath into $zipFile" -verbose
    [System.IO.Compression.ZipFile]::CreateFromDirectory($ClonedProjectPath.Path, $zipFile)
}