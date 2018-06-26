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

#    write-warning('--beginning of install-nugetclientbinaries')
#    Write-Warning('force is: ' + $Force)
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
#        write-warning('here 3')
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
#        write-warning('here 5 - bootstrapnugetexe: ' + $bootstrapNuGetExe + ' $script:NuGetExePath: ' + $script:NuGetExePath)

        ## if we should bootstrap, but there's no Nuget.exe path
        if($BootstrapNuGetExe -and 
        (-not $script:NuGetExePath -or
            -not (Microsoft.PowerShell.Management\Test-Path -Path $script:NuGetExePath)))
        {
            $programDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $script:NuGetExeName
            $applocalDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetAppLocalPath -ChildPath $script:NuGetExeName

            # Check if NuGet.exe is available under one of the predefined PowerShellGet locations under ProgramData or LocalAppData
            if(Microsoft.PowerShell.Management\Test-Path -Path $programDataExePath)
            {
#                write-warning('here 6')
                $script:NuGetExePath = $programDataExePath
                $script:NuGetExeVersion = (Get-Command $programDataExePath).FileVersionInfo.FileVersion
                $BootstrapNuGetExe = $false
            }
            elseif(Microsoft.PowerShell.Management\Test-Path -Path $applocalDataExePath)
            {
#                write-warning('here 7')
                $script:NuGetExePath = $applocalDataExePath
                $script:NuGetExeVersion = (Get-Command $applocalDataExePath).FileVersionInfo.FileVersion
                $BootstrapNuGetExe = $false
            }
            else
            {
#                write-warning('here 8')
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
            }

            ### probably need to move this stuff
#            Write-Warning('WE SHOULD BE GETTING HERE --- ' + $script:NuGetExeVersion)
            # When -Force is specified, bootstrap the latest version if the local version is less than the minimum version
            if ($script:NuGetExeVersion -and ($script:NuGetExeVersion -lt $script:NuGetExeMinRequiredVersion)) 
            {
#                Write-Warning('here 4')
                if ($Force)
                {
#                    Write-Warning('here 5')
                    $BootstrapNuGetExe = $true
                }
                else {
                    $BootstrapNuGetExe = $false
                    ## this was where old prompt to upgrade logic was
                }

            }

        } ###### we're getting here because we have a NuGet.exe path (b/c we have version 2.8 and need to upgrade) **************
        else
        {
#            Write-warning ('should not be here')
            # No need to bootstrap the NuGet.exe when $BootstrapNuGetExe is false or NuGet.exe path is already assigned.
            $BootstrapNuGetExe = $false
        }
    }


    if($BootstrapNuGetExe) {
#        write-warning('we should be here - dotnetcmd nme: ' + $script:DotnetCommandName)
        $DotnetCmd = Microsoft.PowerShell.Core\Get-Command -Name $script:DotnetCommandName -ErrorAction Ignore -WarningAction SilentlyContinue |
            Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

        if ($DotnetCmd -and $DotnetCmd.Path) {  
#            Write-Warning('we should NOT be here')
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
#                    Write-Warning('we do not want to be here....')
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

#    Write-Warning('HERE 0 - bootstrapNuGetProvider: ' + $bootstrapNuGetProvider + ' bootstrpNuGetExe: ' + $bootstrapNuGetExe)
    if(-not $bootstrapNuGetProvider -and -not $BootstrapNuGetExe)
    {
        return
    }

#    Write-warning('???')
    # We should prompt only once for bootstrapping the NuGet provider and/or NuGet.exe

#    Write-Warning('HERE 1')
    if($bootstrapNuGetProvider -and $BootstrapNuGetExe)
    {
        # Should continue message for bootstrapping both NuGet provider and NuGet.exe
        $shouldContinueQueryMessage = $LocalizedData.InstallNuGetBinariesShouldContinueQuery2 -f @('111111111111111111',$script:NuGetBinaryProgramDataPath,$script:NuGetBinaryLocalAppDataPath, $script:PSGetProgramDataPath, $script:PSGetAppLocalPath)
        $shouldContinueCaption = $LocalizedData.InstallNuGetBinariesShouldContinueCaption2
    }
   # elseif($bootstrapNuGetProvider -and ($script:NuGetExeVersion -and ($script:NuGetExeVersion -lt $script:NuGetExeMinRequiredVersion)))
   # {
   #     # Should continue message for bootstrapping both NuGet provider and NuGet.exe
   #     $shouldContinueQueryMessage = $LocalizedData.InstallNuGetBinariesShouldContinueQuery2 -f @('2222222222222222222',$script:NuGetBinaryProgramDataPath,$script:NuGetBinaryLocalAppDataPath, $script:PSGetProgramDataPath, $script:PSGetAppLocalPath)
   #     $shouldContinueCaption = $LocalizedData.InstallNuGetBinariesShouldContinueCaption2
  #  }
    elseif($bootstrapNuGetProvider) {
        # Should continue message for bootstrapping only NuGet provider
        $shouldContinueQueryMessage = $LocalizedData.InstallNuGetProviderShouldContinueQuery -f @('3333333333333333333333',$script:NuGetBinaryProgramDataPath,$script:NuGetBinaryLocalAppDataPath)
        $shouldContinueCaption = $LocalizedData.InstallNuGetProviderShouldContinueCaption
    }
    elseif($BootstrapNuGetExe)
    {
        # Should continue message for bootstrapping only NuGet.exe
        $shouldContinueQueryMessage = $LocalizedData.InstallNuGetExeShouldContinueQuery -f ('555555555555555555555', $script:PSGetAppLocalPath)
        $shouldContinueCaption = $LocalizedData.InstallNuGetExeShouldContinueCaption
    }
   # elseif($BootstrapNuGetExe -and ($script:NuGetExeVersion -and ($script:NuGetExeVersion -lt $script:NuGetExeMinRequiredVersion)))
   # {
   #     # Should continue message for bootstrapping both NuGet provider and NuGet.exe
   #     $shouldContinueQueryMessage = $LocalizedData.InstallNuGetBinariesShouldContinueQuery2 -f @('444444444444444444444',$script:NuGetBinaryProgramDataPath,$script:NuGetBinaryLocalAppDataPath, $script:PSGetProgramDataPath, $script:PSGetAppLocalPath)
   #     $shouldContinueCaption = $LocalizedData.InstallNuGetBinariesShouldContinueCaption2
   # }
    

#    Write-Warning('HERE 2')
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
                #$script:NuGetExeVersion = (Get-Command $programDataExePath).FileVersionInfo.FileVersion
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