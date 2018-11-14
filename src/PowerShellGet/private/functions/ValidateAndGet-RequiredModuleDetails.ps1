function ValidateAndGet-RequiredModuleDetails
{
    param(
        [Parameter()]
        $ModuleManifestRequiredModules,

        [Parameter()]
        [PSModuleInfo[]]
        $RequiredPSModuleInfos,

        [Parameter(Mandatory=$true)]
        [string]
        $Repository,

        [Parameter(Mandatory=$true)]
        [PSModuleInfo]
        $DependentModuleInfo,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet,

        [Parameter(Mandatory = $false)]
        [pscredential]
        $Credential
    )

    $RequiredModuleDetails = @()

    if(-not $RequiredPSModuleInfos)
    {
        return $RequiredModuleDetails
    }

    if($ModuleManifestRequiredModules)
    {
        ForEach($RequiredModule in $ModuleManifestRequiredModules)
        {
            $ModuleName = $null
            $VersionString = $null

            $ReqModuleInfo = @{}

            $FindModuleArguments = @{
                                        Repository = $Repository
                                        Verbose = $VerbosePreference
                                        ErrorAction = 'SilentlyContinue'
                                        WarningAction = 'SilentlyContinue'
                                        Debug = $DebugPreference
                                    }
            if ($PSBoundParameters.ContainsKey('Credential'))
            {
                $FindModuleArguments.Add('Credential',$Credential)
            }

            # ModuleSpecification case
            if($RequiredModule.GetType().ToString() -eq 'System.Collections.Hashtable')
            {
                $ModuleName = $RequiredModule.ModuleName

                # Version format in NuSpec:
                # "[2.0]" --> (== 2.0) Required Version
                # "2.0" --> (>= 2.0) Minimum Version
                if($RequiredModule.Keys -Contains "RequiredVersion")
                {
                    $FindModuleArguments['RequiredVersion'] = $RequiredModule.RequiredVersion
                    $ReqModuleInfo['RequiredVersion'] = $RequiredModule.RequiredVersion
                }
                elseif($RequiredModule.Keys -Contains "ModuleVersion")
                {
                    $FindModuleArguments['MinimumVersion'] = $RequiredModule.ModuleVersion
                    $ReqModuleInfo['MinimumVersion'] = $RequiredModule.ModuleVersion
                }

                if($RequiredModule.Keys -Contains 'MaximumVersion' -and $RequiredModule.MaximumVersion)
                {
                    # * can be specified in the MaximumVersion of a ModuleSpecification to convey that maximum possible value of that version part.
                    # like 1.0.0.* --> 1.0.0.99999999
                    # replace * with 99999999, PowerShell core takes care validating the * to be the last character in the version string.
                    $maximumVersion = $RequiredModule.MaximumVersion -replace '\*','99999999'

                    $FindModuleArguments['MaximumVersion'] = $maximumVersion
                    $ReqModuleInfo['MaximumVersion'] = $maximumVersion
                }
            }
            else
            {
                # Just module name was specified
                $ModuleName = $RequiredModule.ToString()
            }

            if((Get-ExternalModuleDependencies -PSModuleInfo $DependentModuleInfo) -contains $ModuleName)
            {
                Write-Verbose -Message ($LocalizedData.SkippedModuleDependency -f $ModuleName)

                continue
            }

            # Skip this module name if it's name is not in $RequiredPSModuleInfos.
            # This is required when a ModuleName is part of the NestedModules list of the actual module.
            # $ModuleName is packaged as part of the actual module When $RequiredPSModuleInfos doesn't contain it's name.
            if($RequiredPSModuleInfos.Name -notcontains $ModuleName)
            {
                continue
            }

            $ReqModuleInfo['Name'] = $ModuleName

            # Add the dependency only if the module is available on the gallery
            # Otherwise Module installation will fail as all required modules need to be available on
            # the same Repository
            $FindModuleArguments['Name'] = $ModuleName

            $psgetItemInfo = Find-Module @FindModuleArguments  |
                                        Microsoft.PowerShell.Core\Where-Object {$_.Name -eq $ModuleName} |
                                            Microsoft.PowerShell.Utility\Select-Object -Last 1 -ErrorAction Ignore

            if(-not $psgetItemInfo)
            {
                $message = $LocalizedData.UnableToResolveModuleDependency -f ($ModuleName, $DependentModuleInfo.Name, $Repository, $ModuleName, $Repository, $ModuleName, $ModuleName)
                ThrowError -ExceptionName "System.InvalidOperationException" `
                            -ExceptionMessage $message `
                            -ErrorId "UnableToResolveModuleDependency" `
                            -CallerPSCmdlet $CallerPSCmdlet `
                            -ErrorCategory InvalidOperation
            }

            $RequiredModuleDetails += $ReqModuleInfo
        }
    }
    else
    {
        # If Import-LocalizedData cmdlet was failed to read the .psd1 contents
        # use provided $RequiredPSModuleInfos (PSModuleInfo.RequiredModules or PSModuleInfo.NestedModules of the actual dependent module)

        $FindModuleArguments = @{
                                    Repository = $Repository
                                    Verbose = $VerbosePreference
                                    ErrorAction = 'SilentlyContinue'
                                    WarningAction = 'SilentlyContinue'
                                    Debug = $DebugPreference
                                }
        if ($PSBoundParameters.ContainsKey('Credential'))
        {
            $FindModuleArguments.Add('Credential',$Credential)
        }

        ForEach($RequiredModuleInfo in $RequiredPSModuleInfos)
        {
            $ModuleName = $requiredModuleInfo.Name

            if((Get-ExternalModuleDependencies -PSModuleInfo $DependentModuleInfo) -contains $ModuleName)
            {
                Write-Verbose -Message ($LocalizedData.SkippedModuleDependency -f $ModuleName)

                continue
            }

            $FindModuleArguments['Name'] = $ModuleName
            $FindModuleArguments['MinimumVersion'] = $requiredModuleInfo.Version

            $psgetItemInfo = Find-Module @FindModuleArguments |
                                        Microsoft.PowerShell.Core\Where-Object {$_.Name -eq $ModuleName} |
                                            Microsoft.PowerShell.Utility\Select-Object -Last 1 -ErrorAction Ignore

            if(-not $psgetItemInfo)
            {
                $message = $LocalizedData.UnableToResolveModuleDependency -f ($ModuleName, $DependentModuleInfo.Name, $Repository, $ModuleName, $Repository, $ModuleName, $ModuleName)
                ThrowError -ExceptionName "System.InvalidOperationException" `
                            -ExceptionMessage $message `
                            -ErrorId "UnableToResolveModuleDependency" `
                            -CallerPSCmdlet $PSCmdlet `
                            -ErrorCategory InvalidOperation
            }

            $RequiredModuleDetails += @{
                                            Name=$_.Name
                                            MinimumVersion=$_.Version
                                       }
        }
    }

    return $RequiredModuleDetails
}