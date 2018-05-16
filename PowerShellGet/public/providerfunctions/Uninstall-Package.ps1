function Uninstall-Package
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $fastPackageReference
    )

    Write-Debug -Message ($LocalizedData.ProviderApiDebugMessage -f ('Uninstall-Package'))

    Write-Debug -Message ($LocalizedData.FastPackageReference -f $fastPackageReference)

    # take the fastPackageReference and get the package object again.
    $parts = $fastPackageReference -Split '[|]'
    $Force = $false

    $options = $request.Options
    if($options)
    {
        foreach( $o in $options.Keys )
        {
            Write-Debug -Message ("OPTION: {0} => {1}" -f ($o, $request.Options[$o]) )
        }
    }

    if($parts.Length -eq 5)
    {
        $providerName = $parts[0]
        $packageName = $parts[1]
        $version = $parts[2]
        $sourceLocation= $parts[3]
        $artifactType = $parts[4]

        if($request.IsCanceled)
        {
            return
        }

        if($options.ContainsKey('Force'))
        {
            $Force = $options['Force']

            if($Force.GetType().ToString() -eq 'System.String')
            {
                if($Force -eq 'false')
                {
                    $Force = $false
                }
                elseif($Force -eq 'true')
                {
                    $Force = $true
                }
            }
        }

        if($artifactType -eq $script:PSArtifactTypeModule)
        {
            $moduleName = $packageName
            $InstalledModuleInfo = $script:PSGetInstalledModules["$($moduleName)$($version)"]

            if(-not $InstalledModuleInfo)
            {
                $message = $LocalizedData.ModuleUninstallationNotPossibleAsItIsNotInstalledUsingPowerShellGet -f $moduleName

                ThrowError -ExceptionName "System.ArgumentException" `
                           -ExceptionMessage $message `
                           -ErrorId "ModuleUninstallationNotPossibleAsItIsNotInstalledUsingPowerShellGet" `
                           -CallerPSCmdlet $PSCmdlet `
                           -ErrorCategory InvalidArgument

                return
            }

            $moduleBase = $InstalledModuleInfo.PSGetItemInfo.InstalledLocation

            if(-not (Test-RunningAsElevated) -and $moduleBase.StartsWith($script:programFilesModulesPath, [System.StringComparison]::OrdinalIgnoreCase))
            {
                $message = $LocalizedData.AdminPrivilegesRequiredForUninstall -f ($moduleName, $moduleBase)

                ThrowError -ExceptionName "System.InvalidOperationException" `
                           -ExceptionMessage $message `
                           -ErrorId "AdminPrivilegesRequiredForUninstall" `
                           -CallerPSCmdlet $PSCmdlet `
                           -ErrorCategory InvalidOperation

                return
            }

            $dependentModuleScript = {
                                param ([string] $moduleName)
                                Microsoft.PowerShell.Core\Get-Module -ListAvailable |
                                Microsoft.PowerShell.Core\Where-Object {
                                    ($moduleName -ne $_.Name) -and (
                                    ($_.RequiredModules -and $_.RequiredModules.Name -contains $moduleName) -or
                                    ($_.NestedModules -and $_.NestedModules.Name -contains $moduleName))
                                }
                            }
            $dependentModulesJob =  Microsoft.PowerShell.Core\Start-Job -ScriptBlock $dependentModuleScript -ArgumentList $moduleName
            Microsoft.PowerShell.Core\Wait-Job -job $dependentModulesJob
            $dependentModules = Microsoft.PowerShell.Core\Receive-Job -job $dependentModulesJob -ErrorAction Ignore

            if(-not $Force -and $dependentModules)
            {
                $message = $LocalizedData.UnableToUninstallAsOtherModulesNeedThisModule -f ($moduleName, $version, $moduleBase, $(($dependentModules.Name | Select-Object -Unique -ErrorAction Ignore) -join ','), $moduleName)

                ThrowError -ExceptionName "System.InvalidOperationException" `
                           -ExceptionMessage $message `
                           -ErrorId "UnableToUninstallAsOtherModulesNeedThisModule" `
                           -CallerPSCmdlet $PSCmdlet `
                           -ErrorCategory InvalidOperation

                return
            }

            $moduleInUse = Test-ModuleInUse -ModuleBasePath $moduleBase `
                                            -ModuleName $InstalledModuleInfo.PSGetItemInfo.Name`
                                            -ModuleVersion $InstalledModuleInfo.PSGetItemInfo.Version `
                                            -Verbose:$VerbosePreference `
                                            -WarningAction $WarningPreference `
                                            -ErrorAction $ErrorActionPreference `
                                            -Debug:$DebugPreference

            if($moduleInUse)
            {
                $message = $LocalizedData.ModuleIsInUse -f ($moduleName)

                ThrowError -ExceptionName "System.InvalidOperationException" `
                           -ExceptionMessage $message `
                           -ErrorId "ModuleIsInUse" `
                           -CallerPSCmdlet $PSCmdlet `
                           -ErrorCategory InvalidOperation

                return
            }

            $ModuleBaseFolderToBeRemoved = $moduleBase

            # With SxS version support, more than one version of the module can be installed.
            # - Remove the parent directory of the module version base when only one version is installed
            # - Don't remove the modulebase when it was installed before SxS version support and
            #   other versions are installed under the module base folder
            #
            if(Test-ModuleSxSVersionSupport)
            {
                $ModuleBaseWithoutVersion = $moduleBase
                $IsModuleInstalledAsSxSVersion = $false

                if($moduleBase.EndsWith("$version", [System.StringComparison]::OrdinalIgnoreCase))
                {
                    $IsModuleInstalledAsSxSVersion = $true
                    $ModuleBaseWithoutVersion = Microsoft.PowerShell.Management\Split-Path -Path $moduleBase -Parent
                }

                $InstalledVersionsWithSameModuleBase = @()
                Get-Module -Name $moduleName -ListAvailable |
                    Microsoft.PowerShell.Core\ForEach-Object {
                        if($_.ModuleBase.StartsWith($ModuleBaseWithoutVersion, [System.StringComparison]::OrdinalIgnoreCase))
                        {
                            $InstalledVersionsWithSameModuleBase += $_.ModuleBase
                        }
                    }

                # Remove ..\ModuleName directory when only one module is installed with the same ..\ModuleName path
                # like ..\ModuleName\1.0 or ..\ModuleName
                if($InstalledVersionsWithSameModuleBase.Count -eq 1)
                {
                    $ModuleBaseFolderToBeRemoved = $ModuleBaseWithoutVersion
                }
                elseif($ModuleBaseWithoutVersion -eq $moduleBase)
                {
                    # There are version specific folders under the same module base dir
                    # Throw an error saying uninstall other versions then uninstall this current version
                    $message = $LocalizedData.UnableToUninstallModuleVersion -f ($moduleName, $version, $moduleBase)

                    ThrowError -ExceptionName "System.InvalidOperationException" `
                               -ExceptionMessage $message `
                               -ErrorId "UnableToUninstallModuleVersion" `
                               -CallerPSCmdlet $PSCmdlet `
                               -ErrorCategory InvalidOperation

                    return
                }
                # Otherwise specified version folder will be removed as current module base is assigned to $ModuleBaseFolderToBeRemoved
            }

            Microsoft.PowerShell.Management\Remove-Item -Path $ModuleBaseFolderToBeRemoved `
                                                        -Force -Recurse `
                                                        -ErrorAction SilentlyContinue `
                                                        -WarningAction SilentlyContinue `
                                                        -Confirm:$false -WhatIf:$false

            $message = $LocalizedData.ModuleUninstallationSucceeded -f $moduleName, $moduleBase
            Write-Verbose  $message

            Write-Output -InputObject $InstalledModuleInfo.SoftwareIdentity
        }
        elseif($artifactType -eq $script:PSArtifactTypeScript)
        {
            $scriptName = $packageName
            $InstalledScriptInfo = $script:PSGetInstalledScripts["$($scriptName)$($version)"]

            if(-not $InstalledScriptInfo)
            {
                $message = $LocalizedData.ScriptUninstallationNotPossibleAsItIsNotInstalledUsingPowerShellGet -f $scriptName
                ThrowError -ExceptionName "System.ArgumentException" `
                           -ExceptionMessage $message `
                           -ErrorId "ScriptUninstallationNotPossibleAsItIsNotInstalledUsingPowerShellGet" `
                           -CallerPSCmdlet $PSCmdlet `
                           -ErrorCategory InvalidArgument

                return
            }

            $scriptBase = $InstalledScriptInfo.PSGetItemInfo.InstalledLocation
            $installedScriptInfoPath = $script:MyDocumentsInstalledScriptInfosPath

            if($scriptBase.StartsWith($script:ProgramFilesScriptsPath, [System.StringComparison]::OrdinalIgnoreCase))
            {
                if(-not (Test-RunningAsElevated))
                {
                    $message = $LocalizedData.AdminPrivilegesRequiredForScriptUninstall -f ($scriptName, $scriptBase)

                    ThrowError -ExceptionName "System.InvalidOperationException" `
                               -ExceptionMessage $message `
                               -ErrorId "AdminPrivilegesRequiredForUninstall" `
                               -CallerPSCmdlet $PSCmdlet `
                               -ErrorCategory InvalidOperation

                    return
                }

                $installedScriptInfoPath = $script:ProgramFilesInstalledScriptInfosPath
            }

            # Check if there are any dependent scripts
            $dependentScriptDetails = $script:PSGetInstalledScripts.Values |
                                          Microsoft.PowerShell.Core\Where-Object {
                                              $_.PSGetItemInfo.Dependencies -contains $scriptName
                                          }

            $dependentScriptNames = $dependentScriptDetails |
                                        Microsoft.PowerShell.Core\ForEach-Object { $_.PSGetItemInfo.Name }

            if(-not $Force -and $dependentScriptNames)
            {
                $message = $LocalizedData.UnableToUninstallAsOtherScriptsNeedThisScript -f
                               ($scriptName,
                                $version,
                                $scriptBase,
                                $(($dependentScriptNames | Select-Object -Unique -ErrorAction Ignore) -join ','),
                                $scriptName)

                ThrowError -ExceptionName 'System.InvalidOperationException' `
                           -ExceptionMessage $message `
                           -ErrorId 'UnableToUninstallAsOtherScriptsNeedThisScript' `
                           -CallerPSCmdlet $PSCmdlet `
                           -ErrorCategory InvalidOperation
                return
            }

            $scriptFilePath = Microsoft.PowerShell.Management\Join-Path -Path $scriptBase `
                                                                        -ChildPath "$($scriptName).ps1"

            $installedScriptInfoFilePath = Microsoft.PowerShell.Management\Join-Path -Path $installedScriptInfoPath `
                                                                                      -ChildPath "$($scriptName)_$($script:InstalledScriptInfoFileName)"

            # Remove the script file and it's corresponding InstalledScriptInfo.xml
            if(Microsoft.PowerShell.Management\Test-Path -Path $scriptFilePath -PathType Leaf)
            {
                Microsoft.PowerShell.Management\Remove-Item -Path $scriptFilePath `
                                                            -Force `
                                                            -ErrorAction SilentlyContinue `
                                                            -WarningAction SilentlyContinue `
                                                            -Confirm:$false -WhatIf:$false
            }

            if(Microsoft.PowerShell.Management\Test-Path -Path $installedScriptInfoFilePath -PathType Leaf)
            {
                Microsoft.PowerShell.Management\Remove-Item -Path $installedScriptInfoFilePath `
                                                            -Force `
                                                            -ErrorAction SilentlyContinue `
                                                            -WarningAction SilentlyContinue `
                                                            -Confirm:$false -WhatIf:$false
            }

            $message = $LocalizedData.ScriptUninstallationSucceeded -f $scriptName, $scriptBase
            Write-Verbose $message

            Write-Output -InputObject $InstalledScriptInfo.SoftwareIdentity
        }
    }
}