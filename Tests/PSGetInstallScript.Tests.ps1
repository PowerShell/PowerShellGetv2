<#####################################################################################
 # File: PSGetInstallScriptTests.ps1
 # Tests for PSGet module functionality
 #
 # Copyright (c) Microsoft Corporation, 2015
 #####################################################################################>

<#
   Name: PowerShell.PSGet.InstallScriptTests
   Description: Tests for Install-Script cmdlet functionality

   Local PSGet Test Gallery (ex: http://localhost:8765/packages) is pre-populated with static scripts:
        Fabrikam-ClientScript: versions 1.0, 1.5, 2.0, 2.5
        Fabrikam-ServerScript: versions 1.0, 1.5, 2.0, 2.5
#>

function SuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

    $script:IsWindowsOS = (-not (Get-Variable -Name IsWindows -ErrorAction Ignore)) -or $IsWindows
    $script:ProgramFilesScriptsPath = Get-AllUsersScriptsPath
    $script:MyDocumentsScriptsPath = Get-CurrentUserScriptsPath
    $script:PSGetLocalAppDataPath = Get-PSGetLocalAppDataPath
    $script:TempPath = Get-TempPath
    New-Item -Path $script:MyDocumentsScriptsPath -ItemType Directory -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    #Bootstrap NuGet binaries
    Install-NuGetBinaries

    $script:psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
    Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $script:psgetModuleInfo.ModuleBase

    $script:moduleSourcesFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml"
    $script:moduleSourcesBackupFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml_$(get-random)_backup"
    if (Test-Path $script:moduleSourcesFilePath) {
        Rename-Item $script:moduleSourcesFilePath $script:moduleSourcesBackupFilePath -Force
    }

    $Global:PSGallerySourceUri = ''
    GetAndSet-PSGetTestGalleryDetails -IsScriptSuite -SetPSGallery -PSGallerySourceUri ([REF]$Global:PSGallerySourceUri)


    Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
    Get-InstalledScript -Name Fabrikam-ClientScript -ErrorAction SilentlyContinue | Uninstall-Script -Force

    if ($script:IsWindowsOS) {
        $script:userName = "PSGetUser"
        $password = "Password1"
        $null = net user $script:userName $password /add
        $secstr = ConvertTo-SecureString $password -AsPlainText -Force
        $script:credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $script:userName, $secstr
    }

    $script:assertTimeOutms = 20000
    $script:UntrustedRepoSourceLocation = 'https://powershell.myget.org/F/powershellget-test-items/api/v2/'
    $script:UntrustedRepoPublishLocation = 'https://powershell.myget.org/F/powershellget-test-items/api/v2/package'

    # Create temp folder for saving the scripts
    $script:TempSavePath = Join-Path -Path $script:TempPath -ChildPath "PSGet_$(Get-Random)"
    $null = New-Item -Path $script:TempSavePath -ItemType Directory -Force

    $script:AddedAllUsersInstallPath = Set-PATHVariableForScriptsInstallLocation -Scope AllUsers
    $script:AddedCurrentUserInstallPath = Set-PATHVariableForScriptsInstallLocation -Scope CurrentUser

    $script:PSGetSettingsFilePath = Join-Path $script:PSGetLocalAppDataPath 'PowerShellGetSettings.xml'
    $script:PSGetSettingsBackupFilePath = Join-Path $script:PSGetLocalAppDataPath "PowerShellGetSettings.xml_$(get-random)_backup"
    if (Test-Path $script:PSGetSettingsFilePath) {
        Rename-Item $script:PSGetSettingsFilePath $script:PSGetSettingsBackupFilePath -Force
    }

    $script:EnvironmentVariableTarget = @{ Process = 0; User = 1; Machine = 2 }
}

function SuiteCleanup {
    if (Test-Path $script:moduleSourcesBackupFilePath) {
        Move-Item $script:moduleSourcesBackupFilePath $script:moduleSourcesFilePath -Force
    }
    else {
        RemoveItem $script:moduleSourcesFilePath
    }

    # Import the PowerShellGet provider to reload the repositories.
    $null = Import-PackageProvider -Name PowerShellGet -Force

    if ($script:IsWindowsOS) {
        # Delete the user
        net user $script:UserName /delete | Out-Null
        # Delete the user profile
        # run only if cmd is available
        if (Get-Command -Name Get-WmiObject -ErrorAction SilentlyContinue) {
            $userProfile = (Get-WmiObject -Class Win32_UserProfile | Where-Object { $_.LocalPath -match $script:UserName })
            if ($userProfile) {
                RemoveItem $userProfile.LocalPath
            }
        }
    }

    RemoveItem $script:TempSavePath

    if ($script:AddedAllUsersInstallPath) {
        Reset-PATHVariableForScriptsInstallLocation -Scope AllUsers
    }

    if ($script:AddedCurrentUserInstallPath) {
        Reset-PATHVariableForScriptsInstallLocation -Scope CurrentUser
    }

    if (Test-Path $script:PSGetSettingsBackupFilePath) {
        Move-Item $script:PSGetSettingsBackupFilePath $script:PSGetSettingsFilePath -Force
    }
    else {
        RemoveItem $script:PSGetSettingsFilePath
    }
}

Describe PowerShell.PSGet.InstallScriptTests -Tags 'BVT', 'InnerLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    AfterEach {
        Get-InstalledScript -Name Fabrikam-Script -ErrorAction SilentlyContinue | Uninstall-Script -Force
        Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
        Get-InstalledScript -Name Fabrikam-ClientScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
    }

    # Purpose: InstallShouldBeSilent
    #
    # Action: Install-Script "Fabrikam-ServerScript"
    #
    # Expected Result: Should pass
    #
    It "Install-Script Fabrikam-ServerScript should be silent" {
        $result = Install-Script -Name "Fabrikam-ServerScript"
        $result | Should -BeNullOrEmpty
    }

    # Purpose: InstallShouldReturnOutput
    #
    # Action: Install-Script "Fabrikam-ServerScript" -PassThru
    #
    # Expected Result: Should pass
    #
    It "Install-Script Fabrikam-ServerScript -PassThru should return output" {
        $result = Install-Script -Name "Fabrikam-ServerScript" -PassThru
        $result | Should -Not -BeNullOrEmpty
    }

    # Purpose: InstallScriptWithRangeWildCards
    #
    # Action: Install-Script "Fab[rR]ikam?Ser[a-z]erScr?pt"
    #
    # Expected Result: should fail with an error
    #
    It "InstallScriptWithRangeWildCards" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Install-Script 'Fab[rR]ikam?Ser[a-z]erScr?pt', 'TempName' } `
            -expectedFullyQualifiedErrorId 'NameShouldNotContainWildcardCharacters,Install-Script'
    }

    # Purpose: InstallNotAvailableScriptWithWildCard
    #
    # Action: Install-Script "Fab[rR]ikam?Ser[a-z]erScr?ptW"
    #
    # Expected Result:  Fabrikam-ServerScript should not be installed
    #
    It "InstallNotAvailableScriptWithWildCard" {
        Install-Script -Name "Fabrikam-ServerScriptW" -ErrorAction SilentlyContinue

        AssertFullyQualifiedErrorIdEquals -scriptblock { Get-InstalledScript Fabrikam-ServerScript } `
            -expectedFullyQualifiedErrorId 'NoMatchFound,Microsoft.PowerShell.PackageManagement.Cmdlets.GetPackage'
    }

    # Purpose: InstallMultipleScripts
    #
    # Action: Install-Script Fabrikam-ClientScript,Fabrikam-ServerScript
    #
    # Expected Result: two scripts should be installed
    #
    It "InstallMultipleScripts" {
        Install-Script Fabrikam-ClientScript, Fabrikam-ServerScript
        $res = Get-InstalledScript Fabrikam-ClientScript, Fabrikam-ServerScript
        Assert ($res.Count -eq 2) "Install-Script with multiple names should not fail"
    }

    # Purpose: InstallSingleScript
    #
    # Action: Install-Script Fabrikam-ServerScript
    #
    # Expected Result: script should be installed
    #
    It "InstallSingleScript" {
        $scriptName = 'Fabrikam-ServerScript'

        $findScriptOutput = Find-Script $scriptName
        $DateTimeBeforeInstall = Get-Date

        Install-Script $scriptName -scope CurrentUser
        $res = Get-InstalledScript $scriptName

        AssertEquals $res.Name $scriptName "Install-Script failed to install $scriptName, $res"
        Assert ($res.Version -ge '2.5') "Invalid Version value in Get-InstalledScript metadata, $res"
        AssertEquals $res.Type 'Script' "Invalid Type value in Get-InstalledScript metadata, $res"
        AssertEquals $res.Description $findScriptOutput.Description "Invalid Description value in Get-InstalledScript metadata, $res"
        AssertEquals $res.Author $findScriptOutput.Author "Invalid Author value in Get-InstalledScript metadata, $res"
        AssertEquals $res.CompanyName $findScriptOutput.CompanyName "Invalid CompanyName value in Get-InstalledScript metadata, $res"
        AssertEquals $res.Copyright $findScriptOutput.Copyright "Invalid Copyright value in Get-InstalledScript metadata, $res"
        AssertEquals $res.PublishedDate $findScriptOutput.PublishedDate "Invalid PublishedDate value in Get-InstalledScript metadata, $res"
        AssertEquals $res.LicenseUri $findScriptOutput.LicenseUri "Invalid LicenseUri value in Get-InstalledScript metadata, $res"
        AssertEquals $res.ProjectUri $findScriptOutput.ProjectUri "Invalid ProjectUri value in Get-InstalledScript metadata, $res"
        AssertEquals $res.IconUri $findScriptOutput.IconUri "Invalid IconUri value in Get-InstalledScript metadata, $res"
        AssertEquals $res.ReleaseNotes $findScriptOutput.ReleaseNotes "Invalid ReleaseNotes value in Get-InstalledScript metadata, $res"
        AssertEquals $res.Repository $findScriptOutput.Repository "Invalid Repository value in Get-InstalledScript metadata, $res"
        AssertEquals $res.RepositorySourceLocation $findScriptOutput.RepositorySourceLocation "Invalid RepositorySourceLocation value in Get-InstalledScript metadata, $res"
        AssertEquals $res.PackageManagementProvider $findScriptOutput.PackageManagementProvider "Invalid PackageManagementProvider value in Get-InstalledScript metadata, $res"
        AssertEquals $res.InstalledLocation $script:MyDocumentsScriptsPath "Invalid InstalledLocation value in Get-InstalledScript metadata, $res"
        AssertEquals $res.PowerShellGetFormatVersion $findScriptOutput.PowerShellGetFormatVersion "Invalid PowerShellGetFormatVersion value in Get-InstalledScript metadata, $res"

        AssertNotNull $res.InstalledDate "Get-InstalledScript results are not expected, InstalledDate should not be null, $res"
        Assert ($res.InstalledDate.AddSeconds(1) -ge $DateTimeBeforeInstall) "Get-InstalledScript results are not expected, InstalledDate $($res.InstalledDate.Ticks) should be after $($DateTimeBeforeInstall.Ticks)"
        AssertNull $res.UpdatedDate "Get-InstalledScript results are not expected, UpdateDate should be null, $res"

        $findScriptOutput.Tags | ForEach-Object {
            Assert ($res.Tags -contains $_) "Invalid Tags value, missing $_ in Tags from Get-InstalledScript metadata, $($res.Tags)"
        }
    }

    # Purpose: InstallAScriptWithMinVersion
    #
    # Action: Install-Script Fabrikam-ServerScript -MinimumVersion 1.0
    #
    # Expected Result: Should install the script
    #
    It "InstallAScriptWithMinVersion" {
        $scriptName = 'Fabrikam-ServerScript'
        $version = '1.0'
        Install-Script $scriptName -MinimumVersion $version
        $res = Get-InstalledScript $scriptName -MinimumVersion $version
        AssertEquals $res.Name $scriptName
        Assert ($res.Version -ge [Version]$version) "Install-Script failed to install with Version"
    }

    # Purpose: InstallAScriptWithReqVersion
    #
    # Action: Install-Script Fabrikam-ServerScript -RequiredVersion 1.5
    #
    # Expected Result: Should install the script with exact version
    #
    It "InstallAScriptWithReqVersion" {
        $scriptName = 'Fabrikam-ServerScript'
        $version = '1.5'
        Install-Script $scriptName -RequiredVersion $version
        $res = Get-InstalledScript $scriptName -RequiredVersion $version
        AssertEquals $res.Name $scriptName
        AssertEquals $res.Version $version "Install-Script failed to install with RequiredVersion"
    }

    # Purpose: InstallScriptShouldNotFailIfReqVersionAlreadyInstalled
    #
    # Action: install a script with 2.0 version, then try to install 2.0 as required version
    #
    # Expected Result: second install script cmdlet should not fail
    #
    It "InstallScriptShouldNotFailIfReqVersionAlreadyInstalled" {
        Install-Script Fabrikam-ServerScript -RequiredVersion 2.0
        $MyError = $null
        Install-Script Fabrikam-ServerScript -RequiredVersion 2.0 -ErrorVariable MyError
        Assert ((-not $MyError) -or -not ($MyError | ? { -not (($_.Message -match 'StopUpstreamCommandsException') -or ($_.Message -eq 'System error.')) })) "There should not be any error from second install with required, $MyError"
    } `
        -Skip:$($PSCulture -ne 'en-US')

    # Purpose: InstallScriptShouldNotFailIfMinVersionAlreadyInstalled
    #
    # Action: install a script with 2.5 version, then try to install 2.0 as minimum version
    #
    # Expected Result: second install script cmdlet should not fail
    #
    It "InstallScriptShouldNotFailIfMinVersionAlreadyInstalled" {
        Install-Script Fabrikam-ServerScript -RequiredVersion 2.5
        $MyError = $null
        Install-Script Fabrikam-ServerScript -MinimumVersion 2.0 -ErrorVariable MyError
        Assert ((-not $MyError) -or -not ($MyError | ? { -not (($_.Message -match 'StopUpstreamCommandsException') -or ($_.Message -eq 'System error.')) }))  "There should not be any error from second install with min version, $MyError"
    } `
        -Skip:$($PSCulture -ne 'en-US')

    # Purpose: InstallScriptWithForce
    #
    # Action:
    #        Install-Script Fabrikam-ServerScript -RequiredVersion 1.0
    #        Install-Script Fabrikam-ServerScript -RequiredVersion 1.5 -Force
    #
    # Expected Result: Second install should not fail
    #
    It InstallScriptWithForce {
        $scriptName = 'Fabrikam-ServerScript'
        Install-Script $scriptName -RequiredVersion 1.0
        $MyError = $null
        Install-Script $scriptName -RequiredVersion 1.5 -Force -ErrorVariable MyError
        Assert ($MyError.Count -eq 0) "There should not be any error from force install, $MyError"

        $res = Get-InstalledScript $scriptName
        AssertEquals $res.Name $scriptName "Install-Script with existing script should be overwritten if force is specified, $res"
        AssertEquals $res.Version '1.5' "Install-Script with existing script should be overwritten if force is specified, $res"
    }

    # Purpose: InstallScriptSameVersionWithForce
    #
    # Action:
    #        Install-Script Fabrikam-ServerScript -RequiredVersion 1.5
    #        Install-Script Fabrikam-ServerScript -RequiredVersion 1.5 -Force
    #
    # Expected Result: Second install should not fail
    #
    It InstallScriptSameVersionWithForce {
        $scriptName = 'Fabrikam-ServerScript'
        $version = '1.5'
        Install-Script $scriptName -RequiredVersion $version
        $MyError = $null
        Install-Script $scriptName -RequiredVersion $version -Force -ErrorVariable MyError
        Assert ($MyError.Count -eq 0) "There should not be any error from force install, $MyError"
        $res = Get-InstalledScript $scriptName
        AssertEquals $res.Name $scriptName "Install-Script with existing script version should be overwritten if force is specified, $res"
        AssertEquals $res.Version '1.5' "Install-Script with existing script should be overwritten if force is specified, $res"
    }

    # Purpose: Install a script using non available MinimumVersion
    #
    # Action: Install-Script Fabrikam-ServerScript -MinimumVersion 10.0
    #
    # Expected Result: should fail with error id
    #
    It "InstallScriptWithNotAvailableMinVersion" {

        $expectedFullyQualifiedErrorId = 'NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'

        AssertFullyQualifiedErrorIdEquals -scriptblock { Install-Script Fabrikam-ServerScript -MinimumVersion 10.0 } `
            -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    # Purpose: Install a script using non available RequiredVersion
    #
    # Action: Install-Script Fabrikam-ServerScript -RequiredVersion 1.44
    #
    # Expected Result: should fail with error id
    #
    It "InstallScriptWithNotAvailableReqVersion" {

        $expectedFullyQualifiedErrorId = 'NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'

        AssertFullyQualifiedErrorIdEquals -scriptblock { Install-Script Fabrikam-ServerScript -RequiredVersion 1.44 } `
            -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    # Purpose: Install a script using RequiredVersion
    #
    # Action: Install-Script Fabrikam-ServerScript -RequiredVersion 1.5
    #
    # Expected Result: should install the specified version
    #
    It "InstallScriptWithReqVersion" {
        $scriptName = 'Fabrikam-ServerScript'
        $version = '1.5'
        Install-Script $scriptName -RequiredVersion $version -Confirm:$false
        $res = Get-InstalledScript $scriptName
        AssertEquals $res.Name $scriptName "Install-Script failed to install with RequiredVersion"
        AssertEquals $res.Version $version "Install-Script failed to install with RequiredVersion"
    }

    # Purpose: Install a script using MinimumVersion
    #
    # Action: Install-Script Fabrikam-ServerScript -MinimumVersion 1.5
    #
    # Expected Result: should install the script with latest or specified version
    #
    It "InstallScriptWithMinVersion" {
        $scriptName = 'Fabrikam-ServerScript'
        $version = '1.5'
        Install-Script $scriptName -MinimumVersion $version
        $res = Get-InstalledScript $scriptName
        AssertEquals $res.Name $scriptName "Install-Script failed to install with MinimumVersion"
        Assert ($res.Version -ge $version) "Install-Script failed to install with MinimumVersion"
    }

    # Purpose: InstallNotAvailableScript
    #
    # Action: Install-Script NonExistentScript
    #
    # Expected Result: should fail with error
    #
    It "InstallNotAvailableScript" {

        $expectedFullyQualifiedErrorId = 'NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'

        AssertFullyQualifiedErrorIdEquals -scriptblock { Install-Script NonExistentScript } `
            -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    # Purpose: InstallScriptWithPipelineInput
    #
    # Action: Find-Script Fabrikam-ServerScript | Install-Script
    #
    # Expected Result: Fabrikam-ServerScript should be installed
    #
    It "InstallScriptWithPipelineInput" {
        $scriptName = 'Fabrikam-ServerScript'
        Find-Script $scriptName | Install-Script
        $res = Get-InstalledScript $scriptName
        AssertEquals $res.Name $scriptName "Install-Script failed to install Fabrikam-ServerScript with pipeline input"
    }

    # Purpose: InstallMultipleScriptsWithPipelineInput
    #
    # Action: Find-Script Fabrikam-ClientScript,Fabrikam-ServerScript | Install-Script
    #
    # Expected Result: Fabrikam-ServerScript and Fabrikam-ClientScript should be installed
    #
    It "InstallMultipleScriptsWithPipelineInput" {
        Find-Script Fabrikam-ClientScript, Fabrikam-ServerScript | Install-Script
        $res = Get-InstalledScript Fabrikam-ClientScript, Fabrikam-ServerScript
        Assert ($res.Count -eq 2) "Install-Script failed to install multiple scripts from Find-Script output"
    }

    # Purpose: InstallMultipleScriptsUsingInputObjectParam
    #
    # Action: find two scripts and use pass it's output as -InputObject param to Install-Script cmdlet
    #
    # Expected Result: Fabrikam-ServerScript and Fabrikam-ClientScript should be installed
    #
    It "InstallMultipleScriptsUsingInputObjectParam" {
        $items = Find-Script Fabrikam-ClientScript, Fabrikam-ServerScript
        Install-Script -InputObject $items
        $res = Get-InstalledScript Fabrikam-ClientScript, Fabrikam-ServerScript
        Assert ($res.Count -eq 2) "Install-Script failed to install multiple scripts with -InputObject parameter"
    }

    # Purpose: InstallToAllUsersScopeWithPipelineInput
    #
    # Action: Find-Script Fabrikam-ServerScript | Install-Script -Scope AllUsers
    #
    # Expected Result: script should be installed to all user's scripts folder under $env:ProgramFiles\WindowsPowerShell\Scripts"
    #
    It "InstallToAllUsersScopeWithPipelineInput" {
        $scriptName = 'Fabrikam-ServerScript'
        Find-Script $scriptName | Install-Script -Scope AllUsers
        $res = Get-InstalledScript $scriptName
        AssertEquals $res.InstalledLocation $script:ProgramFilesScriptsPath "Install-Script with AllUsers scope did not install Fabrikam-ServerScript to program files scripts folder, $script:ProgramFilesScriptsPath"

        if ($IsWindows -ne $False) {
            $cmdInfo = Get-Command -Name $scriptName
            AssertNotNull $cmdInfo "Script installed to the current user scope is not found by the Get-Command cmdlet"
            AssertEquals $cmdInfo.Name "$scriptName.ps1" "Script installed to the current user scope is not found by the Get-Command cmdlet, $cmdlInfo"

            # CommandInfo.Source is not available on 3.0 and 4.0 downlevel PS versions
            if ($PSVersionTable.PSVersion -ge '5.0.0') {
                AssertEquals $cmdInfo.Source "$($res.InstalledLocation)\$scriptName.ps1" "Script installed to the current user scope is not found by the Get-Command cmdlet, $($cmdlInfo.Source)"
            }
        }
    }

    # Purpose: InstallToCurrentUserScope
    #
    # Action: Install-Script Fabrikam-ServerScript -Scope CurrentUser
    #
    # Expected Result: script should be installed to current user's scripts folder under $Home\WindowsPowerShell\Scripts
    #
    It "InstallToCurrentUserScope" {
        $scriptName = 'Fabrikam-ServerScript'
        Install-Script $scriptName -Scope CurrentUser
        $res = Get-InstalledScript $scriptName
        AssertEquals $res.InstalledLocation $script:MyDocumentsScriptsPath "Install-Script with CurrentUser scope did not install Fabrikam-ServerScript to user documents folder, $script:MyDocumentsScriptsPath"
        if ($IsWindows -ne $False) {
            $cmdInfo = Get-Command -Name $scriptName
            AssertNotNull $cmdInfo "Script installed to the current user scope is not found by the Get-Command cmdlet"
            AssertEquals $cmdInfo.Name "$scriptName.ps1" "Script installed to the current user scope is not found by the Get-Command cmdlet, $cmdlInfo"

            # CommandInfo.Source is not available on 3.0 and 4.0 downlevel PS versions
            if ($PSVersionTable.PSVersion -ge '5.0.0') {
                AssertEquals $cmdInfo.Source "$($res.InstalledLocation)\$scriptName.ps1" "Script installed to the current user scope is not found by the Get-Command cmdlet, $($cmdlInfo.Source)"
            }
        }
    }

    # Purpose: InstallScriptWithForceAndDifferentScope
    #
    # Action: Install-Script Fabrikam-ServerScript -Scope CurrentUser; Install-Script Fabrikam-ServerScript -Scope AllUsers -Force
    #
    # Expected Result: script should be installed to the specified scope with -Force
    #
    It "InstallScriptWithForceAndDifferentScope" {
        $scriptName = 'Fabrikam-ServerScript'
        Install-Script $scriptName -Scope 'CurrentUser'
        $res1 = Get-InstalledScript $scriptName
        AssertEquals $res1.InstalledLocation $script:MyDocumentsScriptsPath "Install-Script with CurrentUser scope did not install Fabrikam-ServerScript to user documents folder, $script:MyDocumentsScriptsPath"

        Install-Script $scriptName -Scope AllUsers -Force
        $res2 = Get-InstalledScript $scriptName

        AssertEquals $res2.Name $scriptName "Only one script should be available after changing the -Scope with -Force on Install-Script cmdlet, $res2"
        AssertEquals $res2.InstalledLocation $script:ProgramFilesScriptsPath "Install-Script with AllUsers scope and -Force did not install Fabrikam-ServerScript to program files scripts folder, $res2"
    }

    # Purpose: Install a script with all users scope parameter for non-admin user
    #
    # Action: Try to install a script with all users scope in a non-admin console
    #
    # Expected Result: It should fail with an error
    #
    It "InstallScriptWithAllUsersScopeParameterForNonAdminUser" {
        $NonAdminConsoleOutput = Join-Path ([System.IO.Path]::GetTempPath()) 'nonadminconsole-out.txt'

        $psProcess = "PowerShell.exe"
        if ($script:IsCoreCLR) {
            $psProcess = "pwsh.exe"
        }

        Start-Process $psProcess -ArgumentList '-command if(-not (Get-PSRepository -Name PoshTest -ErrorAction SilentlyContinue)) {
                                                    Register-PSRepository -Name PoshTest -SourceLocation https://www.poshtestgallery.com/api/v2/ -InstallationPolicy Trusted
                                                }
                                                Install-Script -Name Fabrikam-Script -NoPathUpdate -Scope AllUsers -ErrorVariable ev -ErrorAction SilentlyContinue;
                                                Write-Output "$ev"' `
            -Credential $script:credential `
            -Wait `
            -WorkingDirectory $PSHOME `
            -RedirectStandardOutput $NonAdminConsoleOutput

        waitFor { Test-Path $NonAdminConsoleOutput } -timeoutInMilliseconds $script:assertTimeOutms -exceptionMessage "Install-Script on non-admin console failed to complete"
        $content = Get-Content $NonAdminConsoleOutput
        RemoveItem $NonAdminConsoleOutput

        AssertNotNull ($content) "Install-Script with AllUsers scope on non-admin user console should not succeed"
        Assert ($content -match "Administrator rights are required to install" ) "Install script with AllUsers scope on non-admin user console should fail, $content"
    } `
        -Skip:$(
        $whoamiValue = (whoami)

        ($whoamiValue -eq "NT AUTHORITY\SYSTEM") -or
        ($whoamiValue -eq "NT AUTHORITY\LOCAL SERVICE") -or
        ($whoamiValue -eq "NT AUTHORITY\NETWORK SERVICE") -or
        ($PSVersionTable.PSVersion -lt '4.0.0') -or
        (-not $script:IsWindowsOS) -or
        # Temporarily disable tests for Core
        ($script:IsCoreCLR)
    )

    # Purpose: Install a script with default scope parameter for non-admin user
    #
    # Action: Try to install a script with default (current user) scope in a non-admin console
    #
    # Expected Result: It should succeed and install only to current user
    #
    It "InstallScriptDefaultUserScopeParameterForNonAdminUser" {
        $NonAdminConsoleOutput = Join-Path ([System.IO.Path]::GetTempPath()) 'nonadminconsole-out.txt'

        $psProcess = "PowerShell.exe"
        if ($script:IsCoreCLR) {
            $psProcess = "pwsh.exe"
        }

        Start-Process $psProcess -ArgumentList '-command Install-Script -Name Fabrikam-ServerScript -NoPathUpdate;
                                                Get-InstalledScript Fabrikam-ServerScript | Format-List Name, InstalledLocation' `
            -Credential $script:credential `
            -Wait `
            -WorkingDirectory $PSHOME `
            -RedirectStandardOutput $NonAdminConsoleOutput

        waitFor { Test-Path $NonAdminConsoleOutput } -timeoutInMilliseconds $script:assertTimeOutms -exceptionMessage "Install-Script on non-admin console failed to complete"
        $content = Get-Content $NonAdminConsoleOutput
        RemoveItem $NonAdminConsoleOutput

        AssertNotNull ($content) "Install-Script with default current user scope on non-admin user console should succeed"
        Assert ($content -match "Fabrikam-ServerScript") "Script did not install correctly"
        Assert ($content -match "Documents") "Script did not install to the correct location"
    } `
        -Skip:$(
        $whoamiValue = (whoami)

        ($whoamiValue -eq "NT AUTHORITY\SYSTEM") -or
        ($whoamiValue -eq "NT AUTHORITY\LOCAL SERVICE") -or
        ($whoamiValue -eq "NT AUTHORITY\NETWORK SERVICE") -or
        ($PSVersionTable.PSVersion -lt '4.0.0') -or
        (-not $script:IsWindowsOS) -or
        # Temporarily disable tests for Core
        ($script:IsCoreCLR)
    )

    # Purpose: InstallScript_AllUsers_NO_toThePromptForAddingtoPATHVariable
    #
    # Action: Install-Script Fabrikam-ServerScript
    #
    # Expected Result: script install location should not be added to PATH varaible.
    #
    It "InstallScript_AllUsers_NO_toThePromptForAddingtoPATHVariable" {
        try {
            # Remove PSGetSettings.xml file to get the prompt
            RemoveItem -Path $script:PSGetSettingsFilePath

            # Reset the PATH variable to not have the scripts install location in the PATH variable.
            Reset-PATHVariableForScriptsInstallLocation -Scope AllUsers

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            # 1 is mapped to No in prompt
            $Global:proxy.UI.ChoiceToMake = 1

            $content = $null

            try {
                $result = ExecuteCommand $runspace 'Install-Script Fabrikam-ServerScript -Repository PSGallery'
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            $installShouldProcessMessage = $script:LocalizedData.ScriptPATHPromptQuery -f ($script:ProgramFilesScriptsPath)
            Assert ($content -and ($content -eq $installShouldProcessMessage)) "Install script prompt for adding to PATH variable is not working, Expected:$installShouldProcessMessage, Actual:$content"

            $res = Get-InstalledScript Fabrikam-ServerScript
            AssertEquals $res.Name 'Fabrikam-ServerScript' "Install-Script should install a script even when prompt is not accepted, $res"
        }
        finally {
            # Set the PATH variable to not have the scripts install location in the PATH variable.
            Set-PATHVariableForScriptsInstallLocation -Scope AllUsers

            Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
        }
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: InstallScript_AllUsers_YES_toThePromptForAddingtoPATHVariable
    #
    # Action: Install-Script Fabrikam-ServerScript
    #
    # Expected Result: script install location should be added to PATH varaible.
    #
    It "InstallScript_AllUsers_YES_toThePromptForAddingtoPATHVariable" {
        try {
            # Remove PSGetSettings.xml file to get the prompt
            RemoveItem -Path $script:PSGetSettingsFilePath

            # Reset the PATH variable to not have the scripts install location in the PATH variable.
            Reset-PATHVariableForScriptsInstallLocation -Scope AllUsers

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            # 0 is mapped to YES in ShouldProcess prompt
            $Global:proxy.UI.ChoiceToMake = 0

            $content = $null

            try {
                $result = ExecuteCommand $runspace 'Install-Script Fabrikam-ServerScript -Repository PSGallery'
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            $installShouldProcessMessage = $script:LocalizedData.ScriptPATHPromptQuery -f ($script:ProgramFilesScriptsPath)
            Assert ($content -and ($content -eq $installShouldProcessMessage)) "Install script prompt for adding to PATH variable is not working, Expected:$installShouldProcessMessage, Actual:$content"

            $res = Get-InstalledScript Fabrikam-ServerScript
            AssertEquals $res.Name 'Fabrikam-ServerScript' "Install-Script should install a script even when prompt is not accepted, $res"

            Assert (($env:PATH -split ';') -contains $script:ProgramFilesScriptsPath) "Install-Script should add AllUsers scope path to PATH environment variable."
        }
        finally {
            # Set the PATH variable to not have the scripts install location in the PATH variable.
            Set-PATHVariableForScriptsInstallLocation -Scope AllUsers

            Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
        }
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: InstallScript_CurrentUser_NoPathUpdate_NoPromptForAddingtoPATHVariable
    #
    # Action: Install-Script Fabrikam-ServerScript -NoPathUpdate -Force
    #
    # Expected Result: script install location should not be added to PATH varaible.
    #
    It "InstallScript_CurrentUser_NoPathUpdate_NoPromptForAddingtoPATHVariable" {
        try {
            # Remove PSGetSettings.xml file to get the prompt
            RemoveItem -Path $script:PSGetSettingsFilePath

            # Reset the PATH variable to not have the scripts install location in the PATH variable.
            Reset-PATHVariableForScriptsInstallLocation -Scope CurrentUser

            Assert (($env:PATH -split ';') -notcontains $script:MyDocumentsScriptsPath) "PATH environment variable is not reset properly. $env:PATH"

            Install-Script Fabrikam-ServerScript -Repository PSGallery -Scope CurrentUser -NoPathUpdate -Force

            $res = Get-InstalledScript Fabrikam-ServerScript
            AssertEquals $res.Name 'Fabrikam-ServerScript' "Install-Script should install a script, $res"

            Assert (($env:PATH -split ';') -notcontains $script:MyDocumentsScriptsPath) "Install-Package should not add CurrentUser scope path to PATH environment variable."
        }
        finally {
            # Set the PATH variable to not have the scripts install location in the PATH variable.
            Set-PATHVariableForScriptsInstallLocation -Scope CurrentUser
            Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
        }
    } `
        -Skip:$($IsWindows -eq $false)

    # Purpose: InstallScript_CurrentUser_Force_NoPromptForAddingtoPATHVariable
    #
    # Action: Install-Script Fabrikam-ServerScript  -Scope CurrentUser -Force
    #
    # Expected Result: script install location should not be added to PATH varaible.
    #
    It "InstallScript_CurrentUser_Force_NoPromptForAddingtoPATHVariable" {
        try {
            # Remove PSGetSettings.xml file to get the prompt
            RemoveItem -Path $script:PSGetSettingsFilePath

            # Reset the PATH variable to not have the scripts install location in the PATH variable.
            Reset-PATHVariableForScriptsInstallLocation -Scope CurrentUser

            $script:psgetModuleInfo = Import-Module -Name PowerShellGet -Force -PassThru

            Assert (($env:PATH -split ';') -notcontains $script:MyDocumentsScriptsPath) "PATH environment variable is not reset properly. $env:PATH"

            $currentPATHValue = & $script:psgetModuleInfo Get-EnvironmentVariable -Name 'PATH' -Target $script:EnvironmentVariableTarget.User
            Assert (($currentPATHValue -split ';') -notcontains $script:MyDocumentsScriptsPath) "PATH environment variable is not reset properly. $currentPATHValue"

            Install-Script Fabrikam-ServerScript -Repository PSGallery -Scope CurrentUser -Force

            $res = Get-InstalledScript Fabrikam-ServerScript
            AssertEquals $res.Name 'Fabrikam-ServerScript' "Install-Script should install a script, $res"

            Assert (($env:PATH -split ';') -contains $script:MyDocumentsScriptsPath) "Install-Package should add CurrentUser scope path to PATH environment variable."

            $currentPATHValue = & $script:psgetModuleInfo Get-EnvironmentVariable -Name 'PATH' -Target $script:EnvironmentVariableTarget.User
            Assert (($currentPATHValue -split ';') -contains $script:MyDocumentsScriptsPath) "Install-Package should add CurrentUser scope path to PATH environment variable. $currentPATHValue"
        }
        finally {
            # Set the PATH variable to not have the scripts install location in the PATH variable.
            Set-PATHVariableForScriptsInstallLocation -Scope CurrentUser
            Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force

            $script:psgetModuleInfo = Import-Module -Name PowerShellGet -Force -PassThru
        }
    } `
        -Skip:$($IsWindows -eq $false)

    # Purpose: InstallScript_CurrentUser_NO_toThePromptForAddingtoPATHVariable
    #
    # Action: Install-Script Fabrikam-ServerScript
    #
    # Expected Result: script install location should not be added to PATH varaible.
    #
    It "InstallScript_CurrentUser_NO_toThePromptForAddingtoPATHVariable" {
        try {
            # Remove PSGetSettings.xml file to get the prompt
            RemoveItem -Path $script:PSGetSettingsFilePath

            # Reset the PATH variable to not have the scripts install location in the PATH variable.
            Reset-PATHVariableForScriptsInstallLocation -Scope CurrentUser

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            # 1 is mapped to No in prompt
            $Global:proxy.UI.ChoiceToMake = 1

            $content = $null

            try {
                $result = ExecuteCommand $runspace 'Install-Script Fabrikam-ServerScript -Repository PSGallery -Scope CurrentUser'
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            $installShouldProcessMessage = $script:LocalizedData.ScriptPATHPromptQuery -f ($script:MyDocumentsScriptsPath)
            Assert ($content -and ($content -eq $installShouldProcessMessage)) "Install script prompt for adding to PATH variable is not working, Expected:$installShouldProcessMessage, Actual:$content"

            $res = Get-InstalledScript Fabrikam-ServerScript
            AssertEquals $res.Name 'Fabrikam-ServerScript' "Install-Script should install a script even when prompt is not accepted, $res"
        }
        finally {
            # Set the PATH variable to not have the scripts install location in the PATH variable.
            Set-PATHVariableForScriptsInstallLocation -Scope CurrentUser
            Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
        }
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: InstallScript_CurrentUser_YES_toThePromptForAddingtoPATHVariable
    #
    # Action: Install-Script Fabrikam-ServerScript
    #
    # Expected Result: script install location should not be added to PATH varaible.
    #
    It "InstallScript_CurrentUser_YES_toThePromptForAddingtoPATHVariable" {
        try {
            # Remove PSGetSettings.xml file to get the prompt
            RemoveItem -Path $script:PSGetSettingsFilePath

            # Reset the PATH variable to not have the scripts install location in the PATH variable.
            Reset-PATHVariableForScriptsInstallLocation -Scope CurrentUser

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            # 0 is mapped to YES in ShouldProcess prompt
            $Global:proxy.UI.ChoiceToMake = 0

            $content = $null

            try {
                $result = ExecuteCommand $runspace 'Install-Script Fabrikam-ServerScript -Repository PSGallery -Scope CurrentUser'
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            $installShouldProcessMessage = $script:LocalizedData.ScriptPATHPromptQuery -f ($script:MyDocumentsScriptsPath)
            Assert ($content -and ($content -eq $installShouldProcessMessage)) "Install script prompt for adding to PATH variable is not working, Expected:$installShouldProcessMessage, Actual:$content"

            $res = Get-InstalledScript Fabrikam-ServerScript
            AssertEquals $res.Name 'Fabrikam-ServerScript' "Install-Script should install a script even when prompt is not accepted, $res"

            Assert (($env:PATH -split ';') -contains $script:MyDocumentsScriptsPath) "Install-Script should add CurrentUser scope path to PATH environment variable."
        }
        finally {
            # Set the PATH variable to not have the scripts install location in the PATH variable.
            Set-PATHVariableForScriptsInstallLocation -Scope CurrentUser
            Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
        }
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: InstallScriptWithWhatIf
    #
    # Action: Find-Script Fabrikam-ServerScript | Install-Script -WhatIf
    #
    # Expected Result: it should not install the script
    #
    It "InstallScriptWithWhatIf" {
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Install-Script -Name Fabrikam-ServerScript -WhatIf'
        }
        finally {
            $fileName = "WriteLine-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Script Fabrikam-ServerScript -Repository PSGallery
        $installShouldProcessMessage = $script:LocalizedData.InstallScriptwhatIfMessage -f ($itemInfo.Name, $itemInfo.Version)
        Assert ($content -and ($content -match $installShouldProcessMessage)) "Install script whatif message is missing, Expected:$installShouldProcessMessage, Actual:$content"

        $res = Get-InstalledScript Fabrikam-ServerScript -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        Assert (-not $res) "Install-Script should not install the script with -WhatIf option"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: InstallScriptWithConfirmAndNoToPrompt
    #
    # Action: Install-Script Fabrikam-ServerScript -Confirm
    #
    # Expected Result: script should not be installed after confirming NO
    #
    It "InstallScriptWithConfirmAndNoToPrompt" {
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 2 is mapped to NO in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake = 2
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Install-Script Fabrikam-ServerScript -Repository PSGallery -Confirm'
        }
        finally {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Script Fabrikam-ServerScript -Repository PSGallery

        $installShouldProcessMessage = $script:LocalizedData.InstallScriptwhatIfMessage -f ($itemInfo.Name, $itemInfo.Version)
        Assert ($content -and ($content -match $installShouldProcessMessage)) "Install script confirm prompt is not working, Expected:$installShouldProcessMessage, Actual:$content"

        $res = Get-InstalledScript Fabrikam-ServerScript -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        AssertNull $res "Install-Script should not install a script if Confirm is not accepted"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: InstallScriptWithConfirmAndYesToPrompt
    #
    # Action: Find-Script Fabrikam-ServerScript | Install-Script -Confirm
    #
    # Expected Result: script should be installed after confirming YES
    #
    It "InstallScriptWithConfirmAndYesToPrompt" {
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        # 0 is mapped to YES in ShouldProcess prompt
        $Global:proxy.UI.ChoiceToMake = 0
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Find-Script Fabrikam-ServerScript | Install-Script -Confirm'
        }
        finally {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Script Fabrikam-ServerScript -Repository PSGallery

        $installShouldProcessMessage = $script:LocalizedData.InstallScriptwhatIfMessage -f ($itemInfo.Name, $itemInfo.Version)
        Assert ($content -and ($content -match $installShouldProcessMessage)) "Install script confirm prompt is not working, Expected:$installShouldProcessMessage, Actual:$content"

        $res = Get-InstalledScript Fabrikam-ServerScript
        AssertEquals $res.Name 'Fabrikam-ServerScript' "Install-Script should install a script if Confirm is accepted, $res"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    <#
    Purpose: Validate the Get-InstalledScript

    Action: Install a script, get installed script count, update the script, get script count

    Expected Result: should be able to get the installed script.
    #>
    It ValidateGetInstalledScriptCmdlet {

        $serverScriptName = 'Fabrikam-ServerScript'
        $clientScriptName = 'Fabrikam-ClientScript'

        Install-Script -Name $clientScriptName
        $res = Get-InstalledScript -Name $clientScriptName
        AssertEquals $res.Name $clientScriptName "Get-InstalledScript results are not expected, $res"

        Install-Script -Name $serverScriptName -RequiredVersion 1.0 -Force
        $scripts1 = Get-InstalledScript
        Assert ($scripts1.Count -ge 2) "Get-InstalledScript is not working properly"

        $res = Get-InstalledScript -Name $serverScriptName
        AssertEquals $res.Name $serverScriptName "Get-InstalledScript returned wrong script, $res"
        AssertEquals $res.Version "1.0" "Get-InstalledScript returned wrong script version, $res"

        Update-Script -Name $serverScriptName -RequiredVersion 2.0
        $res2 = Get-InstalledScript -Name $serverScriptName -RequiredVersion "2.0"
        AssertEquals $res2.Name $serverScriptName "Get-InstalledScript returned wrong script after Update-Script, $res2"
        AssertEquals $res2.Version "2.0"  "Get-InstalledScript returned wrong script version  after Update-Script, $res2"

        $scripts2 = Get-InstalledScript
        AssertEquals $scripts1.count $scripts2.count "script count should be same before and after updating a script, before: $($scripts1.count), after: $($scripts2.count)"
    }
}

Describe PowerShell.PSGet.InstallScriptTests.P1 -Tags 'P1', 'OuterLoop' {

    # Not executing these tests on MacOS as
    # the total execution time is exceeding allowed 50 min in TravisCI daily builds.
    if ($IsMacOS) {
        return
    }

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    AfterEach {
        Get-InstalledScript -Name Fabrikam-Script -ErrorAction SilentlyContinue | Uninstall-Script -Force
        Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
        Get-InstalledScript -Name Fabrikam-ClientScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
    }

    # Purpose: Install a script with prefixed wildcard
    #
    # Action: Install-Script *kam-ServerScript
    #
    # Expected Result: should fail
    #
    It "InstallScriptWithPrefixWildCard" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Install-Script *kam-ServerScript } `
            -expectedFullyQualifiedErrorId 'NameShouldNotContainWildcardCharacters,Install-Script'
    }

    # Purpose: Install a script with postfixed wildcard
    #
    # Action: Install-Script Fabrikam-ServerScri*
    #
    # Expected Result: should fail
    #
    It "InstallScriptWithPostfixWildCard" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Install-Script Fabrikam-ServerScri* } `
            -expectedFullyQualifiedErrorId 'NameShouldNotContainWildcardCharacters,Install-Script'
    }

    # Purpose: Install a script with wildcard
    #
    # Action: Install-Script *abrikam-ServerScrip*
    #
    # Expected Result: should fail with an error
    #
    It "InstallScriptWithWildCards" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Install-Script *abrikam-ServerScrip* } `
            -expectedFullyQualifiedErrorId 'NameShouldNotContainWildcardCharacters,Install-Script'
    }

    # Purpose: InstallScriptWithVersionParams
    #
    # Action: Install-Script Fabrikam-ServerScript -MinimumVersion 1.0 -RequiredVersion 5.0
    #
    # Expected Result: Should fail with an error id
    #
    It "InstallScriptWithVersionParams" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Install-Script Fabrikam-ServerScript -MinimumVersion 1.0 -RequiredVersion 5.0 } `
            -expectedFullyQualifiedErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether,Install-Script"
    }

    # Purpose: InstallMultipleNamesWithReqVersion
    #
    # Action: Install-Script Fabrikam-ClientScript,Fabrikam-ServerScript -RequiredVersion 2.0
    #
    # Expected Result: Should fail with an error id
    #
    It "InstallMultipleNamesWithReqVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Install-Script Fabrikam-ClientScript, Fabrikam-ServerScript -RequiredVersion 2.0 } `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Install-Script"
    }

    # Purpose: InstallMultipleNamesWithMinVersion
    #
    # Action: Install-Script Fabrikam-ClientScript,Fabrikam-ServerScript -MinimumVersion 2.0
    #
    # Expected Result: Should fail with an error id
    #
    It "InstallMultipleNamesWithMinVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Install-Script Fabrikam-ClientScript, Fabrikam-ServerScript -MinimumVersion 2.0 } `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Install-Script"
    }

    # Purpose: InstallScriptShouldFailIfReqVersionNotAlreadyInstalled
    #
    # Action: install a script with 1.5 version, then try to install 2.0 as required version
    #
    # Expected Result: second install script cmdlet should fail with warning message
    #
    It "InstallScriptShouldFailIfReqVersionNotAlreadyInstalled" {
        $scriptName = 'Fabrikam-ServerScript'
        $version = '1.5'
        Install-Script $scriptName -RequiredVersion $version
        $InstalledScriptInfo = Get-InstalledScript -Name $scriptName -RequiredVersion $version
        $wv = $null
        Install-Script $scriptName -RequiredVersion 2.0 -WarningAction SilentlyContinue -WarningVariable wv

        $message = $script:LocalizedData.ScriptAlreadyInstalled -f ($InstalledScriptInfo.Version,
            $InstalledScriptInfo.Name,
            $InstalledScriptInfo.InstalledLocation,
            $InstalledScriptInfo.Version,
            '2.0')
        # WarningVariable value doesnt get the warning messages on PS 3.0 and 4.0, known issue.
        if ($PSVersionTable.PSVersion -ge '5.0.0') {
            AssertEqualsCaseInsensitive $wv.Message $message "Install-Script should not re-install a script if it is already installed"
        }
    } `
        -Skip:$($PSCulture -ne 'en-US')

    # Purpose: InstallScriptShouldFailIfMinVersionNotAlreadyInstalled
    #
    # Action: install a script with 1.5 version, then try to install 2.0 as minimum version
    #
    # Expected Result: second install script cmdlet should fail with warning message
    #
    It "InstallScriptShouldFailIfMinVersionNotAlreadyInstalled" {
        $scriptName = 'Fabrikam-ServerScript'
        $version = '1.5'
        Install-Script $scriptName -RequiredVersion $version
        $InstalledScriptInfo = Get-InstalledScript -Name $scriptName -RequiredVersion $version
        $wv = $null
        Install-Script $scriptName -MinimumVersion 2.0 -WarningAction SilentlyContinue -WarningVariable wv

        $message = $script:LocalizedData.ScriptAlreadyInstalled -f ($InstalledScriptInfo.Version,
            $InstalledScriptInfo.Name,
            $InstalledScriptInfo.InstalledLocation,
            $InstalledScriptInfo.Version,
            '2.0')
        Assert ($message -match $scriptName) "Install-Script should not re-install a script if it is already installed, $($wv.Message)"
    } `
        -Skip:$($PSCulture -ne 'en-US')

    # Purpose: InstallPackage_Script_AllUsers_NO_toThePromptForAddingtoPATHVariable
    #
    # Action: Install-Package -Provider PowerShellGet -Type Script -Name Fabrikam-ServerScript -Source PSGallery
    #
    # Expected Result: script install location should not be added to PATH varaible.
    #
    It "InstallPackage_Script_AllUsers_NO_toThePromptForAddingtoPATHVariable" {
        try {
            # Remove PSGetSettings.xml file to get the prompt
            RemoveItem -Path $script:PSGetSettingsFilePath

            # Reset the PATH variable to not have the scripts install location in the PATH variable.
            Reset-PATHVariableForScriptsInstallLocation -Scope AllUsers

            $null = PackageManagement\Import-PackageProvider -Name PowerShellGet -Force

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            # 1 is mapped to No in prompt
            $Global:proxy.UI.ChoiceToMake = 1

            $content = $null

            try {
                $result = ExecuteCommand $runspace 'Install-Package -Provider PowerShellGet -Type Script -Name Fabrikam-ServerScript -Source PSGallery'
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            $installShouldProcessMessage = $script:LocalizedData.ScriptPATHPromptQuery -f ($script:ProgramFilesScriptsPath)
            Assert ($content -and ($content -eq $installShouldProcessMessage)) "Install script prompt for adding to PATH variable is not working, Expected:$installShouldProcessMessage, Actual:$content"

            $res = Get-InstalledScript Fabrikam-ServerScript
            AssertEquals $res.Name 'Fabrikam-ServerScript' "Install-Script should install a script even when prompt is not accepted, $res"
        }
        finally {
            # Set the PATH variable to not have the scripts install location in the PATH variable.
            Set-PATHVariableForScriptsInstallLocation -Scope AllUsers

            Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
        }
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: InstallPackage_Script_AllUsers_YES_toThePromptForAddingtoPATHVariable
    #
    # Action: Install-Package -Provider PowerShellGet -Type Script -Name Fabrikam-ServerScript -Source PSGallery
    #
    # Expected Result: script install location should be added to PATH varaible.
    #
    It "InstallPackage_Script_AllUsers_YES_toThePromptForAddingtoPATHVariable" {
        try {
            # Remove PSGetSettings.xml file to get the prompt
            RemoveItem -Path $script:PSGetSettingsFilePath

            # Reset the PATH variable to not have the scripts install location in the PATH variable.
            Reset-PATHVariableForScriptsInstallLocation -Scope AllUsers

            $null = PackageManagement\Import-PackageProvider -Name PowerShellGet -Force

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            # 0 is mapped to YES in ShouldProcess prompt
            $Global:proxy.UI.ChoiceToMake = 0

            $content = $null

            try {
                $result = ExecuteCommand $runspace 'Install-Package -Provider PowerShellGet -Type Script -Name Fabrikam-ServerScript -Source PSGallery'
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            $installShouldProcessMessage = $script:LocalizedData.ScriptPATHPromptQuery -f ($script:ProgramFilesScriptsPath)
            Assert ($content -and ($content -eq $installShouldProcessMessage)) "Install script prompt for adding to PATH variable is not working, Expected:$installShouldProcessMessage, Actual:$content"

            $res = Get-InstalledScript Fabrikam-ServerScript
            AssertEquals $res.Name 'Fabrikam-ServerScript' "Install-Script should install a script even when prompt is not accepted, $res"

            Assert (($env:PATH -split ';') -contains $script:ProgramFilesScriptsPath) "Install-Package should add AllUsers scope path to PATH environment variable."
        }
        finally {
            # Set the PATH variable to not have the scripts install location in the PATH variable.
            Set-PATHVariableForScriptsInstallLocation -Scope AllUsers

            Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
        }
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: InstallPackage_Script_AllUsers_NoPathUpdate_NoPromptForAddingtoPATHVariable
    #
    # Action: Install-Package -Provider PowerShellGet -Type Script -Name Fabrikam-ServerScript -Source PSGallery -NoPathUpdate
    #
    # Expected Result: script install location should not be added to PATH varaible.
    #
    It "InstallPackage_Script_AllUsers_NoPathUpdate_NoPromptForAddingtoPATHVariable" {

        try {
            # Remove PSGetSettings.xml file to get the prompt
            RemoveItem -Path $script:PSGetSettingsFilePath

            # Reset the PATH variable to not have the scripts install location in the PATH variable.
            Reset-PATHVariableForScriptsInstallLocation -Scope AllUsers

            $null = PackageManagement\Import-PackageProvider -Name PowerShellGet -Force

            Install-Package -Provider PowerShellGet -Type Script -Name Fabrikam-ServerScript -Source PSGallery -NoPathUpdate -Force

            $res = Get-InstalledScript Fabrikam-ServerScript
            AssertEquals $res.Name 'Fabrikam-ServerScript' "Install-Script should install a script, $res"

            Assert (($env:PATH -split ';') -notcontains $script:ProgramFilesScriptsPath) "Install-Package should add AllUsers scope path to PATH environment variable."
        }
        finally {
            # Set the PATH variable to not have the scripts install location in the PATH variable.
            Set-PATHVariableForScriptsInstallLocation -Scope AllUsers

            Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
        }
    } `
        -Skip:$($IsWindows -eq $false)

    # Purpose: InstallPackage_Script_Default_User_Force_NoPromptForAddingtoPATHVariable
    #
    # Action: Install-Package -Provider PowerShellGet -Type Script -Name Fabrikam-ServerScript -Source PSGallery -Force
    #
    # Expected Result: script install location should not be added to PATH varaible.
    #
    It "InstallPackage_Script_Default_User_Force_NoPromptForAddingtoPATHVariable" {
        try {
            # Remove PSGetSettings.xml file to get the prompt
            RemoveItem -Path $script:PSGetSettingsFilePath

            # Reset the PATH variable to not have the scripts install location in the PATH variable.
            Reset-PATHVariableForScriptsInstallLocation -Scope AllUsers

            $null = PackageManagement\Import-PackageProvider -Name PowerShellGet -Force

            Install-Package -Provider PowerShellGet -Type Script -Name Fabrikam-ServerScript -Source PSGallery -Force

            $res = Get-InstalledScript Fabrikam-ServerScript
            AssertEquals $res.Name 'Fabrikam-ServerScript' "Install-Script should install a script, $res"

            if ($script:IsCoreCLR) {
                Assert (($env:PATH -split ';') -contains $script:MyDocumentsScriptsPath) "Install-Package should add CurrentUser scope path to PATH environment variable."
            }
            else {
                Assert (($env:PATH -split ';') -contains $script:ProgramFilesScriptsPath) "Install-Package should add AllUsers scope path to PATH environment variable."
            }
        }
        finally {
            # Set the PATH variable to not have the scripts install location in the PATH variable.
            Set-PATHVariableForScriptsInstallLocation -Scope AllUsers

            Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
        }
    } `
        -Skip:$($IsWindows -eq $false)

    # Purpose: InstallPackage_Script_CurrentUser_NO_toThePromptForAddingtoPATHVariable
    #
    # Action: Install-Package -Provider PowerShellGet -Type Script -Name Fabrikam-ServerScript -Source PSGallery -Scope CurrentUser
    #
    # Expected Result: script install location should not be added to PATH varaible.
    #
    It "InstallPackage_Script_CurrentUser_NO_toThePromptForAddingtoPATHVariable" {
        try {
            # Remove PSGetSettings.xml file to get the prompt
            RemoveItem -Path $script:PSGetSettingsFilePath

            # Reset the PATH variable to not have the scripts install location in the PATH variable.
            Reset-PATHVariableForScriptsInstallLocation -Scope CurrentUser
            $null = PackageManagement\Import-PackageProvider -Name PowerShellGet -Force

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            # 1 is mapped to No in prompt
            $Global:proxy.UI.ChoiceToMake = 1

            $content = $null

            try {
                $result = ExecuteCommand $runspace 'Install-Package -Provider PowerShellGet -Type Script -Name Fabrikam-ServerScript -Source PSGallery -Scope CurrentUser'
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            $installShouldProcessMessage = $script:LocalizedData.ScriptPATHPromptQuery -f ($script:MyDocumentsScriptsPath)
            Assert ($content -and ($content -eq $installShouldProcessMessage)) "Install script prompt for adding to PATH variable is not working, Expected:$installShouldProcessMessage, Actual:$content"

            $res = Get-InstalledScript Fabrikam-ServerScript
            AssertEquals $res.Name 'Fabrikam-ServerScript' "Install-Script should install a script even when prompt is not accepted, $res"
        }
        finally {
            # Set the PATH variable to not have the scripts install location in the PATH variable.
            Set-PATHVariableForScriptsInstallLocation -Scope CurrentUser
            Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
        }
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: InstallPackage_Script_CurrentUser_YES_toThePromptForAddingtoPATHVariable
    #
    # Action: Install-Package -Provider PowerShellGet -Type Script -Name Fabrikam-ServerScript -Source PSGallery -Scope CurrentUser
    #
    # Expected Result: script install location should be added to PATH varaible.
    #
    It "InstallPackage_Script_CurrentUser_YES_toThePromptForAddingtoPATHVariable" {
        try {
            # Remove PSGetSettings.xml file to get the prompt
            RemoveItem -Path $script:PSGetSettingsFilePath

            # Reset the PATH variable to not have the scripts install location in the PATH variable.
            Reset-PATHVariableForScriptsInstallLocation -Scope CurrentUser
            $null = PackageManagement\Import-PackageProvider -Name PowerShellGet -Force

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            # 0 is mapped to YES in ShouldProcess prompt
            $Global:proxy.UI.ChoiceToMake = 0

            $content = $null

            try {
                $result = ExecuteCommand $runspace 'Install-Package -Provider PowerShellGet -Type Script -Name Fabrikam-ServerScript -Source PSGallery -Scope CurrentUser'
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            $installShouldProcessMessage = $script:LocalizedData.ScriptPATHPromptQuery -f ($script:MyDocumentsScriptsPath)
            Assert ($content -and ($content -eq $installShouldProcessMessage)) "Install script prompt for adding to PATH variable is not working, Expected:$installShouldProcessMessage, Actual:$content"

            $res = Get-InstalledScript Fabrikam-ServerScript
            AssertEquals $res.Name 'Fabrikam-ServerScript' "Install-Script should install a script even when prompt is not accepted, $res"

            Assert (($env:PATH -split ';') -contains $script:MyDocumentsScriptsPath) "Install-Script should add CurrentUser scope path to PATH environment variable."
        }
        finally {
            # Set the PATH variable to not have the scripts install location in the PATH variable.
            Set-PATHVariableForScriptsInstallLocation -Scope CurrentUser
            Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
        }
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    # Purpose: Install a script from an untrusted repository and press No to the prompt
    #
    # Action: Install-Script Fabrikam-ServerScript -Repostory UntrustedTestRepo
    #
    # Expected Result: script should not be installed
    #
    It InstallAScriptFromUntrustedRepositoryAndNoToPrompt {
        try {
            #Register an untrusted test repository
            Register-PSRepository -Name UntrustedTestRepo -SourceLocation $script:TempPath -ScriptSourceLocation $script:UntrustedRepoSourceLocation
            $scriptRepo = Get-PSRepository -Name UntrustedTestRepo
            AssertEqualsCaseInsensitive $scriptRepo.ScriptSourceLocation $script:UntrustedRepoSourceLocation "Test repository 'UntrustedTestRepo' is not registered properly"

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            if ($PSVersionTable.PSVersion -ge '4.0.0') {
                # 2 is mapped to NO in ShouldProcess prompt
                $Global:proxy.UI.ChoiceToMake = 2
            }
            else {
                # 1 is mapped to No in prompt
                $Global:proxy.UI.ChoiceToMake = 1
            }

            $content = $null
            try {
                $result = ExecuteCommand $runspace "Install-Script Fabrikam-ServerScript -Repository UntrustedTestRepo"
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            $itemInfo = Find-Script Fabrikam-ServerScript
            $acceptPromptMessage = "Are you sure you want to install the scripts from"
            Assert ($content -and $content.Contains($acceptPromptMessage)) "Prompt for installing a script from an untrusted repository is not working, $content"
            $res = Get-InstalledScript Fabrikam-ServerScript -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            Assert (-not $res) "Install-Script should not install a script if prompt is not accepted"
        }
        finally {
            Get-PSRepository -Name UntrustedTestRepo -ErrorAction SilentlyContinue | Unregister-PSRepository -ErrorAction SilentlyContinue
        }
    } `
        -Skip:$(($PSCulture -ne 'en-US') -or ($PSVersionTable.PSVersion -lt '4.0.0') -or ($PSEdition -eq 'Core'))

    # Purpose: Install a script from an untrusted repository and press YES to the prompt
    #
    # Action: Install-Script Fabrikam-ServerScript -Repostory UntrustedTestRepo
    #
    # Expected Result: script should be installed
    #
    It InstallAScriptFromUntrustedRepositoryAndYesToPrompt {
        try {
            #Register an untrusted test repository
            Register-PSRepository -Name UntrustedTestRepo -SourceLocation $script:TempPath -ScriptSourceLocation $script:UntrustedRepoSourceLocation
            $scriptRepo = Get-PSRepository -Name UntrustedTestRepo
            AssertEqualsCaseInsensitive $scriptRepo.ScriptSourceLocation $script:UntrustedRepoSourceLocation "Test repository 'UntrustedTestRepo' is not registered properly"

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            # 0 is mapped to YES in prompt
            $Global:proxy.UI.ChoiceToMake = 0
            $content = $null
            try {
                $result = ExecuteCommand $runspace "Install-Script Fabrikam-ServerScript -Repository UntrustedTestRepo"
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            $acceptPromptMessage = "Are you sure you want to install the scripts from"
            Assert ($content -and $content.Contains($acceptPromptMessage)) "Prompt for installing a script from an untrusted repository is not working, $content"

            $res = Get-InstalledScript Fabrikam-ServerScript
            AssertEquals $res.Name 'Fabrikam-ServerScript' "Install-Script should install a script if prompt is accepted, $res"
        }
        finally {
            Get-PSRepository -Name UntrustedTestRepo -ErrorAction SilentlyContinue | Unregister-PSRepository -ErrorAction SilentlyContinue
        }
    } `
        -Skip:$(($PSCulture -ne 'en-US') -or ($PSVersionTable.PSVersion -lt '4.0.0') -or ($PSEdition -eq 'Core'))

    # Get-InstalledScript error cases
    It ValidateGetInstalledScriptWithMultiNamesAndRequiredVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Get-InstalledScript -Name Fabrikam-ClientScript, Fabrikam-ServerScript -RequiredVersion 3.0 } `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Get-InstalledScript"
    }

    It ValidateGetInstalledScriptWithMultiNamesAndMinVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Get-InstalledScript -Name Fabrikam-ClientScript, Fabrikam-ServerScript -MinimumVersion 3.0 } `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Get-InstalledScript"
    }

    It ValidateGetInstalledScriptWithMultiNamesAndMaxVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Get-InstalledScript -Name Fabrikam-ClientScript, Fabrikam-ServerScript -MaximumVersion 3.0 } `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Get-InstalledScript"
    }

    It ValidateGetInstalledScriptWithSingleWildcardNameAndRequiredVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Get-InstalledScript -Name Fabrikam-Client*ipt -RequiredVersion 3.0 } `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Get-InstalledScript"
    }

    It ValidateGetInstalledScriptWithSingleWildcardNameAndMinVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Get-InstalledScript -Name Fabrikam-Client*ipt -MinimumVersion 3.0 } `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Get-InstalledScript"
    }

    It ValidateGetInstalledScriptWithSingleWildcardNameAndMaxVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Get-InstalledScript -Name Fabrikam-Client*ipt -MaximumVersion 3.0 } `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Get-InstalledScript"
    }

    It ValidateGetInstalledScriptWithSingleNameRequiredandMinVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Get-InstalledScript -Name Fabrikam-ClientScript -RequiredVersion 3.0 -MinimumVersion 1.0 } `
            -expectedFullyQualifiedErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether,Get-InstalledScript"
    }

    It ValidateGetInstalledScriptWithSingleNameRequiredandMaxVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Get-InstalledScript -Name Fabrikam-ClientScript -RequiredVersion 3.0 -MaximumVersion 1.0 } `
            -expectedFullyQualifiedErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether,Get-InstalledScript"
    }

    It ValidateGetInstalledScriptWithSingleNameInvalidMinMaxRange {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Get-InstalledScript -Name Fabrikam-ClientScript -MinimumVersion 3.0 -MaximumVersion 1.0 } `
            -expectedFullyQualifiedErrorId "MinimumVersionIsGreaterThanMaximumVersion,Get-InstalledScript"
    }

    # Purpose: Validate Install-Script cmdlet with a script with dependencies
    #
    # Action: Install-Script -Name Script-WithDependencies1
    #
    # Expected Result: Should install the script along with its dependencies
    #
    It InstallScriptWithIncludeDependencies {
        $ScriptName = 'Script-WithDependencies1'
        $DepencyNames = @()
        $DepScriptDetails = $null
        $DepModuleDetails = $null

        try {
            $res1 = Find-Script -Name $ScriptName -MaximumVersion "1.0" -MinimumVersion "0.1"
            AssertEquals $res1.Name $ScriptName "Find-Script didn't find the exact script which has dependencies, $res1"

            $DepencyNames = $res1.Dependencies.Name

            $res2 = Find-Script -Name $ScriptName -IncludeDependencies -MaximumVersion "1.0" -MinimumVersion "0.1"
            Assert ($res2.Count -ge ($DepencyNames.Count + 1)) "Find-Script with -IncludeDependencies returned wrong results, $res2"

            Install-Script -Name $ScriptName -MaximumVersion "1.0" -MinimumVersion "0.1"
            $ActualScriptDetails = Get-InstalledScript -Name $ScriptName -RequiredVersion $res1.Version
            AssertNotNull $ActualScriptDetails "$ScriptName script with dependencies is not installed properly"

            $DepScriptDetails = Get-InstalledScript -Name $DepencyNames -ErrorAction SilentlyContinue
            $DepModuleDetails = Get-InstalledModule -Name $DepencyNames -ErrorAction SilentlyContinue

            $DepencyNames | ForEach-Object {
                if ((-not $DepScriptDetails -or $DepScriptDetails.Name -notcontains $_) -and
                    (-not $DepModuleDetails -or $DepModuleDetails.Name -notcontains $_)) {
                    Assert $false "Script dependency $_ is not installed"
                }
            }
        }
        finally {
            Uninstall-Script -ErrorAction SilentlyContinue $ScriptName
            $DepScriptDetails | ForEach-Object { Uninstall-Script $_.Name -Force -ErrorAction SilentlyContinue }
            $DepModuleDetails | ForEach-Object { PowerShellGet\Uninstall-Module $_.Name -Force -ErrorAction SilentlyContinue }
        }
    } `
        -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    # Purpose: Validate Save-Script cmdlet with a script with dependencies
    #
    # Action: Save-Script -Name Script-WithDependencies1
    #
    # Expected Result: Should save the script along with its dependencies
    #
    It SaveScriptNameWithDependencies {
        try {
            $ScriptName = 'Script-WithDependencies1'

            $res1 = Find-Script -Name $ScriptName -RequiredVersion '1.0' -IncludeDependencies

            Save-Script -Name $ScriptName -MaximumVersion '1.0' -MinimumVersion '0.1' $script:TempSavePath

            $res1.Name | ForEach-Object {
                $artifactPath = Join-Path -Path $script:TempSavePath -ChildPath $_
                if (-not (Test-Path -Path $artifactPath -PathType Container) -and
                    -not (Test-Path -Path "$artifactPath.ps1" -PathType Leaf)) {
                    Assert $false "$_ is not saved with the Save-Script -Name $ScriptName"
                }
            }
        }
        finally {
            Remove-Item -Path "$script:TempSavePath\*" -Recurse -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }

    # Purpose: Validate Save-Script cmdlet with a script with dependencies
    #
    # Action: Find-Script -Name Script-WithDependencies1 | Save-Script
    #
    # Expected Result: Should save the script along with its dependencies
    #
    It SaveScriptWithFindScriptOutput {
        try {
            $ScriptName = "Script-WithDependencies1"
            $res1 = Find-Script -Name $ScriptName -RequiredVersion '2.0' -IncludeDependencies
            Find-Script -Name $ScriptName -RequiredVersion '2.0' | Save-Script -LiteralPath $script:TempSavePath

            $res1.Name | ForEach-Object {
                $artifactPath = Join-Path -Path $script:TempSavePath -ChildPath $_
                if (-not (Test-Path -Path $artifactPath -PathType Container) -and
                    -not (Test-Path -Path "$artifactPath.ps1" -PathType Leaf)) {
                    Assert $false "$_ is not saved with the Save-Script -Name $ScriptName"
                }
            }
        }
        finally {
            Remove-Item -Path "$script:TempSavePath\*" -Recurse -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }

    # Purpose: Validate Get-InstalledScript cmdlet with and without wildcard in script name
    #
    # Action: Install-Script -Name Contoso,Fabrikam-ServerScript,Fabrikam-ClientScript; Get-InstalledScript -Name Contoso; Get-InstalledScript -Name Contoso*
    #
    # Expected Result: Should get the installed scripts with/without wildcards
    #
    It GetInstalledScriptWithWildcard {
        $ScriptNames = 'Fabrikam-Script', 'Fabrikam-ServerScript', 'Fabrikam-ClientScript'

        Install-Script -Name $ScriptNames

        # ScriptName without wildcards
        $res1 = Get-InstalledScript -Name $ScriptNames[0]
        AssertEquals $res1.Name $ScriptNames[0] "Get-InstalledScript didn't return the exact script, $res1"

        # ScriptName with wildcards
        $res2 = Get-InstalledScript -Name "Fabrikam*"
        AssertEquals $res2.count $ScriptNames.Count "Get-InstalledScript didn't return the $ScriptNames scripts, $res2"
    }

    # Purpose: Validate Install-Script cmdlet with same source location registered with NUGet provider
    #
    # Expected Result: Get-InstalledScript should return proper Repository and RepositorySourceLocation values
    #    from the PSScript provider only not from the NuGet provider
    #
    It InstallScriptWithSameLocationRegisteredWithNuGetProvider {
        $ScriptName = 'Fabrikam-ServerScript'
        $TempNuGetSourceName = "$(Get-Random)"
        $RepositoryName = "PSGallery"
        Register-PackageSource -Provider nuget -Name $TempNuGetSourceName -Location $Global:PSGallerySourceUri -Trusted
        try {
            Install-Script -Name $ScriptName -Repository $RepositoryName

            $res1 = Get-InstalledScript -Name $ScriptName
            AssertEquals $res1.Name $ScriptName "Get-InstalledScript didn't return the exact script, $res1"

            AssertEquals $res1.RepositorySourceLocation $Global:PSGallerySourceUri "PSGetItemInfo object was created with wrong RepositorySourceLocation"
            AssertEquals $res1.Repository $RepositoryName "PSGetItemInfo object was created with wrong repository name"

            $expectedInstalledLocation = $script:ProgramFilesScriptsPath
            if ($script:IsCoreCLR) {
                $expectedInstalledLocation = $script:MyDocumentsScriptsPath
            }
            AssertEquals $res1.InstalledLocation $expectedInstalledLocation "Invalid InstalledLocation value on PSGetItemInfo object"
        }
        finally {
            Unregister-PackageSource -ProviderName NuGet -Name $TempNuGetSourceName -Force
        }
    }

    # Purpose: Script cmdlets without ScriptSourceLocation value in Repository.
    #
    # Action: Find-Script, Install-Script, Save-Script and Find-Package with a repository which doesnt have ScriptSourceLocation value.
    #
    # Expected Result: *.Script cmdlets should fail with an error and Find-Package should throw a warning message.
    #
    It ScriptCmdletsWithoutScriptSourceLocation {
        try {
            Register-PSRepository -Name TestRepo -SourceLocation https://www.nuget.org/api/v2
            $scriptRepo = Get-PSRepository -Name TestRepo
            Assert (-not $scriptRepo.ScriptSourceLocation) "Test repository 'TestRepo' is not registered properly"
            Assert (-not $scriptRepo.ScriptPublishLocation) "Test repository 'TestRepo' is not registered properly"

            $repoName = 'TestRepo'

            AssertFullyQualifiedErrorIdEquals -scriptblock { Find-Script -Name TestScriptName -Repository $repoName } `
                -expectedFullyQualifiedErrorId 'ScriptSourceLocationIsMissing,Find-Script'

            AssertFullyQualifiedErrorIdEquals -scriptblock { Install-Script -Name TestScriptName -Repository $repoName } `
                -expectedFullyQualifiedErrorId 'ScriptSourceLocationIsMissing,Install-Script'

            AssertFullyQualifiedErrorIdEquals -scriptblock { Save-Script -Name TestScriptName -Repository $repoName -Path $script:TempPath } `
                -expectedFullyQualifiedErrorId 'ScriptSourceLocationIsMissing,Save-Script'
            $wv = $null
            Find-Package -Name TestScriptName -Source $repoName -ProviderName PowerShellGet -Type Script -WarningVariable wv -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            $message = $script:LocalizedData.ScriptSourceLocationIsMissing -f ($repoName)
            AssertEquals $wv.Message $message "Find-Package should throw a warning message when the specified source doesnt have a valid ScriptSourceLocation"
        }
        finally {
            Get-PSRepository -Name TestRepo -ErrorAction SilentlyContinue | Unregister-PSRepository -ErrorAction SilentlyContinue
        }
    } `
        -Skip:$($PSCulture -ne 'en-US')

    It "Get-InstalledScript cmdlet with leading zeros in RequiredVersion value" {
        $scriptName = 'Fabrikam-ServerScript'
        $version = '1.2'
        Install-Script $scriptName -RequiredVersion $version
        $res = Get-InstalledScript $scriptName -RequiredVersion '1.02'
        $res.Name | Should Be $scriptName
        $res.Version | Should Be $version

        $res = Get-InstalledScript $scriptName -RequiredVersion $version
        $res.Version | Should Be $version
    }
}
