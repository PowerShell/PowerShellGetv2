function Install-NuGetClientBinaries
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet,

        [parameter()]
        [switch]
        $BootstrapNuGetExe,

        [Parameter()]
        $Proxy,

        [Parameter()]
        $ProxyCredential,

        [parameter()]
        [switch]
        $Force
    )

    #write-warning('here 1')
    if ($script:NuGetProvider -and
        ($script:NuGetExeVersion -and ($script:NuGetExeVersion -ge $script:NuGetExeMinRequiredVersion))   -and
         (-not $BootstrapNuGetExe -or
         (($script:NuGetExePath -and (Microsoft.PowerShell.Management\Test-Path -Path $script:NuGetExePath)) -or
          ($script:DotnetCommandPath -and (Microsoft.PowerShell.Management\Test-Path -Path $script:DotnetCommandPath)))))
    {
        return
    }

    #write-warning('here 2')
    $bootstrapNuGetProvider = (-not $script:NuGetProvider)

    if($bootstrapNuGetProvider)
    {
       # write-warning('here 3')
        # Bootstrap the NuGet provider only if it is not available.
        # By default PackageManagement loads the latest version of the NuGet provider.
        $nugetProvider = PackageManagement\Get-PackageProvider -ErrorAction SilentlyContinue -WarningAction SilentlyContinue |
                            Microsoft.PowerShell.Core\Where-Object {
                                                                     $_.Name -eq $script:NuGetProviderName -and
                                                                     $_.Version -ge $script:NuGetProviderVersion
                                                                   }
        if($nugetProvider)
        {
            $script:NuGetProvider = $nugetProvider

            $bootstrapNuGetProvider = $false
        }
        else
        {
           # write-warning('here 4')
            # User might have installed it in an another console or in the same process, check available NuGet providers and import the required provider.
            $availableNugetProviders = PackageManagement\Get-PackageProvider -Name $script:NuGetProviderName `
                                                                             -ListAvailable `
                                                                             -ErrorAction SilentlyContinue `
                                                                             -WarningAction SilentlyContinue |
                                            Microsoft.PowerShell.Core\Where-Object {
                                                                                       $_.Name -eq $script:NuGetProviderName -and
                                                                                       $_.Version -ge $script:NuGetProviderVersion
                                                                                   }
            if($availableNugetProviders)
            {
                # Force import ensures that nuget provider with minimum version got loaded.
                $null = PackageManagement\Import-PackageProvider -Name $script:NuGetProviderName `
                                                                 -MinimumVersion $script:NuGetProviderVersion `
                                                                 -Force

                $nugetProvider = PackageManagement\Get-PackageProvider -ErrorAction SilentlyContinue -WarningAction SilentlyContinue |
                                    Microsoft.PowerShell.Core\Where-Object {
                                                                             $_.Name -eq $script:NuGetProviderName -and
                                                                             $_.Version -ge $script:NuGetProviderVersion
                                                                           }
                if($nugetProvider)
                {
                    $script:NuGetProvider = $nugetProvider

                    $bootstrapNuGetProvider = $false
                }
            }
        }
    }

    if($script:IsWindows -and -not $script:IsNanoServer) {
       # write-warning('here 5')
        if($BootstrapNuGetExe -and
        (-not $script:NuGetExePath -or
            -not (Microsoft.PowerShell.Management\Test-Path -Path $script:NuGetExePath)))
        {
            $programDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $script:NuGetExeName
            $applocalDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetAppLocalPath -ChildPath $script:NuGetExeName

            # Check if NuGet.exe is available under one of the predefined PowerShellGet locations under ProgramData or LocalAppData
            if(Microsoft.PowerShell.Management\Test-Path -Path $programDataExePath)
            {
                #write-warning('here 6')
                $script:NuGetExePath = $programDataExePath
                $script:NuGetExeVersion = (Get-Command $programDataExePath).FileVersionInfo.FileVersion
                $BootstrapNuGetExe = $false
            }
            elseif(Microsoft.PowerShell.Management\Test-Path -Path $applocalDataExePath)
            {
               # write-warning('here 7')
                $script:NuGetExePath = $applocalDataExePath
                $script:NuGetExeVersion = (Get-Command $applocalDataExePath).FileVersionInfo.FileVersion
                $BootstrapNuGetExe = $false
            }
            else
            {
               # write-warning('here 8')
                # Using Get-Command cmdlet, get the location of NuGet.exe if it is available under $env:PATH.
                # NuGet.exe does not work if it is under $env:WINDIR, so skip it from the Get-Command results.
                $nugetCmd = Microsoft.PowerShell.Core\Get-Command -Name $script:NuGetExeName `
                                                                -ErrorAction Ignore `
                                                                -WarningAction SilentlyContinue |
                                Microsoft.PowerShell.Core\Where-Object {
                                    $_.Path -and
                                    ((Microsoft.PowerShell.Management\Split-Path -Path $_.Path -Leaf) -eq $script:NuGetExeName) -and
                                    (-not $_.Path.StartsWith($env:windir, [System.StringComparison]::OrdinalIgnoreCase))
                                } | Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

                if($nugetCmd -and $nugetCmd.Path -and $nugetCmd.FileVersionInfo.FileVersion)
                {
                    $script:NuGetExePath = $nugetCmd.Path
                    $script:NuGetExeVersion = $nugetCmd.FileVersionInfo.FileVersion
                    $BootstrapNuGetExe = $false
                }
                else 
                {
                    ### else check if dotnet cli is installed, if dotnet cli is installed,
                    ### check make sure min required version is fine, right now bootstrapNuGetExe is still true.  $bootstrapNuGetExe = false
                   # write-warning ('we got here! 1  --- bootstrapNuuGetExe is: ' + $bootstrapNuGetExe)
                   #$bootstrapNuGetExe = $false

                }
            }

            # When -Force is specified, bootstrap the latest version if the local version is less than the minimum version
            if ($script:NuGetExeVersion -and ($script:NuGetExeVersion -lt $script:NuGetExeMinRequiredVersion)) 
            {
                #write-warning('did we get here??')
                if ($Force)
                {
                    $BootstrapNuGetExe = $true
                }
                else 
                {
                    # prompt for an upgrade
                    $upgradeShouldContinueQueryMessage = $LocalizedData.InstallNugetExeUpgradeShouldContinueQuery -f @($script:NuGetExeMinRequiredVersion, $script:PSGetProgramDataPath, $script:PSGetAppLocalPath)
                    $upgradeShouldContinueCaption = $LocalizedData.InstallNuGetExeShouldContinueCaption

                    $AdditionalParams = Get-ParametersHashtable -Proxy $Proxy -ProxyCredential $ProxyCredential

                    if($Force -or $psCmdlet.ShouldContinue($upgradeShouldContinueQueryMessage, $upgradeShouldContinueCaption))
                    {
                        if($bootstrapNuGetProvider)
                        {
                            Write-Verbose -Message $LocalizedData.DownloadingNugetProvider
                
                            $scope = 'CurrentUser'
                            if(Test-RunningAsElevated)
                            {
                                $scope = 'AllUsers'
                            }
                
                            # Bootstrap the NuGet provider
                            $null = PackageManagement\Install-PackageProvider -Name $script:NuGetProviderName `
                                                                              -MinimumVersion $script:NuGetProviderVersion `
                                                                              -Scope $scope `
                                                                              -Force @AdditionalParams
                
                            # Force import ensures that nuget provider with minimum version got loaded.
                            $null = PackageManagement\Import-PackageProvider -Name $script:NuGetProviderName `
                                                                             -MinimumVersion $script:NuGetProviderVersion `
                                                                             -Force
                
                            $nugetProvider = PackageManagement\Get-PackageProvider -Name $script:NuGetProviderName
                
                            if ($nugetProvider)
                            {
                                $script:NuGetProvider = $nugetProvider
                            }
                        }

                        Write-Verbose -Message $LocalizedData.DownloadingNugetExe
                
                        $nugetExeBasePath = $script:PSGetAppLocalPath
                
                        # if the current process is running with elevated privileges,
                        # install NuGet.exe to $script:PSGetProgramDataPath
                        if(Test-RunningAsElevated)
                        {
                            $nugetExeBasePath = $script:PSGetProgramDataPath
                        }

                        if(-not (Microsoft.PowerShell.Management\Test-Path -Path $nugetExeBasePath))
                        {
                            $null = Microsoft.PowerShell.Management\New-Item -Path $nugetExeBasePath `
                                                                             -ItemType Directory -Force `
                                                                             -ErrorAction SilentlyContinue `
                                                                             -WarningAction SilentlyContinue `
                                                                             -Confirm:$false -WhatIf:$false
                        }
                
                        $nugetExeFilePath = Microsoft.PowerShell.Management\Join-Path -Path $nugetExeBasePath -ChildPath $script:NuGetExeName
                
                        # Download the NuGet.exe from https://dist.nuget.org/win-x86-commandline/latest/nuget.exe
                        $null = Microsoft.PowerShell.Utility\Invoke-WebRequest -Uri $script:NuGetClientSourceURL `
                                                                               -OutFile $nugetExeFilePath `
                                                                                @AdditionalParams
                
                        if (Microsoft.PowerShell.Management\Test-Path -Path $nugetExeFilePath)
                        {
                            $script:NuGetExePath = $nugetExeFilePath
                            $script:NuGetExeVersion = (Get-Command $programDataExePath).FileVersionInfo.FileVersion
                        }
                        #else 
                        #{
                        #    #write-warning ('we got here! 2')
                        #    return
                        #}
                    }
                }
            }
        }
        else
        {
            # No need to bootstrap the NuGet.exe when $BootstrapNuGetExe is false or NuGet.exe path is already assigned.
            $BootstrapNuGetExe = $false
        }
    }

    if($BootstrapNuGetExe) {
        #write-warning('we should not be here')
        $DotnetCmd = Microsoft.PowerShell.Core\Get-Command -Name $script:DotnetCommandName -ErrorAction Ignore -WarningAction SilentlyContinue |
            Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

        if ($DotnetCmd -and $DotnetCmd.Path) {  
            $script:DotnetCommandPath = $DotnetCmd.Path
            $BootstrapNuGetExe = $false
        }
        else {
            if($script:IsWindows) {
                $DotnetCommandPath = Microsoft.PowerShell.Management\Join-Path -Path $env:LocalAppData -ChildPath Microsoft |
                    Microsoft.PowerShell.Management\Join-Path -ChildPath dotnet |
                        Microsoft.PowerShell.Management\Join-Path -ChildPath dotnet.exe

                if($DotnetCommandPath -and
                   -not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $DotnetCommandPath -PathType Leaf)) {
                    $DotnetCommandPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath dotnet |
                        Microsoft.PowerShell.Management\Join-Path -ChildPath dotnet.exe
                }
            }
            else {
                $DotnetCommandPath = '/usr/local/bin/dotnet'
            }

            if($DotnetCommandPath -and (Microsoft.PowerShell.Management\Test-Path -LiteralPath $DotnetCommandPath -PathType Leaf)) {
                $DotnetCommandVersion,$null = (& $DotnetCommandPath '--version') -split '-',2
                if($DotnetCommandVersion -and ($script:MinimumDotnetCommandVersion -le $DotnetCommandVersion)) {
                    $script:DotnetCommandPath = $DotnetCommandPath
                    $BootstrapNuGetExe = $false
                }
            }
        }
    }

    # On non-Windows, dotnet should be installed by the user, throw an error if dotnet is not found using above logic.
    if ($BootstrapNuGetExe -and (-not $script:IsWindows -or $script:IsNanoServer)) {
        $ThrowError_params = @{
            ExceptionName    = 'System.InvalidOperationException'
            ExceptionMessage = ($LocalizedData.CouldNotFindDotnetCommand -f $script:MinimumDotnetCommandVersion, $script:DotnetInstallUrl)
            ErrorId          = 'CouldNotFindDotnetCommand'
            CallerPSCmdlet   = $CallerPSCmdlet
            ErrorCategory    = 'InvalidOperation'
        }

        ThrowError @ThrowError_params
        return
    }

    if(-not $bootstrapNuGetProvider -and -not $BootstrapNuGetExe)
    {
        return
    }

    # We should prompt only once for bootstrapping the NuGet provider and/or NuGet.exe

    # Should continue message for bootstrapping only NuGet provider
    $shouldContinueQueryMessage = $LocalizedData.InstallNuGetProviderShouldContinueQuery -f @($script:NuGetProviderVersion,$script:NuGetBinaryProgramDataPath,$script:NuGetBinaryLocalAppDataPath)
    $shouldContinueCaption = $LocalizedData.InstallNuGetProviderShouldContinueCaption

    # Should continue message for bootstrapping both NuGet provider and NuGet.exe
    if($bootstrapNuGetProvider -and $BootstrapNuGetExe)
    {
        $shouldContinueQueryMessage = $LocalizedData.InstallNuGetBinariesShouldContinueQuery2 -f @($script:NuGetProviderVersion,$script:NuGetBinaryProgramDataPath,$script:NuGetBinaryLocalAppDataPath, $script:PSGetProgramDataPath, $script:PSGetAppLocalPath)
        $shouldContinueCaption = $LocalizedData.InstallNuGetBinariesShouldContinueCaption2
    }
    elseif($BootstrapNuGetExe)
    {
        # Should continue message for bootstrapping only NuGet.exe
        $shouldContinueQueryMessage = $LocalizedData.InstallNuGetExeShouldContinueQuery -f ($script:PSGetProgramDataPath, $script:PSGetAppLocalPath)
        $shouldContinueCaption = $LocalizedData.InstallNuGetExeShouldContinueCaption
    }

    $AdditionalParams = Get-ParametersHashtable -Proxy $Proxy -ProxyCredential $ProxyCredential

    if($Force -or $psCmdlet.ShouldContinue($shouldContinueQueryMessage, $shouldContinueCaption))
    {
        if($bootstrapNuGetProvider)
        {
            Write-Verbose -Message $LocalizedData.DownloadingNugetProvider

            $scope = 'CurrentUser'
            if(Test-RunningAsElevated)
            {
                $scope = 'AllUsers'
            }

            # Bootstrap the NuGet provider
            $null = PackageManagement\Install-PackageProvider -Name $script:NuGetProviderName `
                                                              -MinimumVersion $script:NuGetProviderVersion `
                                                              -Scope $scope `
                                                              -Force @AdditionalParams

            # Force import ensures that nuget provider with minimum version got loaded.
            $null = PackageManagement\Import-PackageProvider -Name $script:NuGetProviderName `
                                                             -MinimumVersion $script:NuGetProviderVersion `
                                                             -Force

            $nugetProvider = PackageManagement\Get-PackageProvider -Name $script:NuGetProviderName

            if ($nugetProvider)
            {
                $script:NuGetProvider = $nugetProvider
            }
        }

        if($BootstrapNuGetExe -and $script:IsWindows)
        {
            Write-Verbose -Message $LocalizedData.DownloadingNugetExe

            $nugetExeBasePath = $script:PSGetAppLocalPath

            # if the current process is running with elevated privileges,
            # install NuGet.exe to $script:PSGetProgramDataPath
            if(Test-RunningAsElevated)
            {
                $nugetExeBasePath = $script:PSGetProgramDataPath
            }

            if(-not (Microsoft.PowerShell.Management\Test-Path -Path $nugetExeBasePath))
            {
                $null = Microsoft.PowerShell.Management\New-Item -Path $nugetExeBasePath `
                                                                 -ItemType Directory -Force `
                                                                 -ErrorAction SilentlyContinue `
                                                                 -WarningAction SilentlyContinue `
                                                                 -Confirm:$false -WhatIf:$false
            }

            $nugetExeFilePath = Microsoft.PowerShell.Management\Join-Path -Path $nugetExeBasePath -ChildPath $script:NuGetExeName

            # Download the NuGet.exe from https://dist.nuget.org/win-x86-commandline/latest/nuget.exe
            $null = Microsoft.PowerShell.Utility\Invoke-WebRequest -Uri $script:NuGetClientSourceURL `
                                                                   -OutFile $nugetExeFilePath `
                                                                   @AdditionalParams

            if (Microsoft.PowerShell.Management\Test-Path -Path $nugetExeFilePath)
            {
                $script:NuGetExePath = $nugetExeFilePath
            }
        }
    }

    $message = $null
    $errorId = $null
    $failedToBootstrapNuGetProvider = $false
    $failedToBootstrapNuGetExe = $false

    if($bootstrapNuGetProvider -and -not $script:NuGetProvider)
    {
        $failedToBootstrapNuGetProvider = $true

        $message = $LocalizedData.CouldNotInstallNuGetProvider -f @($script:NuGetProviderVersion)
        $errorId = 'CouldNotInstallNuGetProvider'
    }

    if($BootstrapNuGetExe -and
       (-not $script:NuGetExePath -or
        -not (Microsoft.PowerShell.Management\Test-Path -Path $script:NuGetExePath)))
    {
        $failedToBootstrapNuGetExe = $true

        $message = $LocalizedData.CouldNotInstallNuGetExe -f @($script:MinimumDotnetCommandVersion)
        $errorId = 'CouldNotInstallNuGetExe'
    }

    # Change the error id and message if both NuGet provider and NuGet.exe are not installed.
    if($failedToBootstrapNuGetProvider -and $failedToBootstrapNuGetExe)
    {
        $message = $LocalizedData.CouldNotInstallNuGetBinaries2 -f @($script:NuGetProviderVersion)
        $errorId = 'CouldNotInstallNuGetBinaries'
    }

    # Throw the error message if one of the above conditions are met
    if($message -and $errorId)
    {
        ThrowError -ExceptionName "System.InvalidOperationException" `
                    -ExceptionMessage $message `
                    -ErrorId $errorId `
                    -CallerPSCmdlet $CallerPSCmdlet `
                    -ErrorCategory InvalidOperation
    }
}