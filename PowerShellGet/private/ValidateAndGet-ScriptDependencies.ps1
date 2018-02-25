function ValidateAndGet-ScriptDependencies
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Repository,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $DependentScriptInfo,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet,

        [Parameter()]
        [PSCredential]
        $Credential
    )

    $DependenciesDetails = @()

    # Validate dependent modules
    $RequiredModuleSpecification = $DependentScriptInfo.RequiredModules
    if($RequiredModuleSpecification)
    {
        ForEach($moduleSpecification in $RequiredModuleSpecification)
        {
            $ModuleName = $moduleSpecification.Name

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

            if($DependentScriptInfo.ExternalModuleDependencies -contains $ModuleName)
            {
                Write-Verbose -Message ($LocalizedData.SkippedModuleDependency -f $ModuleName)

                continue
            }

            $FindModuleArguments['Name'] = $ModuleName
            $ReqModuleInfo = @{}
            $ReqModuleInfo['Name'] = $ModuleName

            if($moduleSpecification.Version)
            {
                $FindModuleArguments['MinimumVersion'] = $moduleSpecification.Version
                $ReqModuleInfo['MinimumVersion'] = $moduleSpecification.Version
            }
            elseif((Get-Member -InputObject $moduleSpecification -Name RequiredVersion) -and $moduleSpecification.RequiredVersion)
            {
                $FindModuleArguments['RequiredVersion'] = $moduleSpecification.RequiredVersion
                $ReqModuleInfo['RequiredVersion'] = $moduleSpecification.RequiredVersion
            }

            if((Get-Member -InputObject $moduleSpecification -Name MaximumVersion) -and $moduleSpecification.MaximumVersion)
            {
                # * can be specified in the MaximumVersion of a ModuleSpecification to convey that maximum possible value of that version part.
                # like 1.0.0.* --> 1.0.0.99999999
                # replace * with 99999999, PowerShell core takes care validating the * to be the last character in the version string.
                $maximumVersion = $moduleSpecification.MaximumVersion -replace '\*','99999999'
                $FindModuleArguments['MaximumVersion'] = $maximumVersion
                $ReqModuleInfo['MaximumVersion'] = $maximumVersion
            }

            $psgetItemInfo = Find-Module @FindModuleArguments  |
                                        Microsoft.PowerShell.Core\Where-Object {$_.Name -eq $ModuleName} |
                                            Microsoft.PowerShell.Utility\Select-Object -Last 1 -ErrorAction Ignore

            if(-not $psgetItemInfo)
            {
                $message = $LocalizedData.UnableToResolveScriptDependency -f ('module', $ModuleName, $DependentScriptInfo.Name, $Repository, 'ExternalModuleDependencies')
                ThrowError -ExceptionName "System.InvalidOperationException" `
                            -ExceptionMessage $message `
                            -ErrorId "UnableToResolveScriptDependency" `
                            -CallerPSCmdlet $CallerPSCmdlet `
                            -ErrorCategory InvalidOperation
            }

            $DependenciesDetails += $ReqModuleInfo
        }
    }

    # Validate dependent scrips
    $RequiredScripts = $DependentScriptInfo.RequiredScripts
    if($RequiredScripts)
    {
        ForEach($requiredScript in $RequiredScripts)
        {
            $FindScriptArguments = @{
                                        Repository = $Repository
                                        Verbose = $VerbosePreference
                                        ErrorAction = 'SilentlyContinue'
                                        WarningAction = 'SilentlyContinue'
                                        Debug = $DebugPreference
                                    }
            $ReqScriptInfo = @{}

            if ($PSBoundParameters.ContainsKey('Credential'))
            {
                $FindScriptArguments.Add('Credential',$Credential)
            }

            if (-not ($requiredScript -match '^(?<ScriptName>[^:]+)(:(?<Version>[^:\s]+))?$'))
            {
                $message = $LocalizedData.FailedToParseRequiredScripts -f ($requiredScript)

                ThrowError `
                    -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId "FailedToParseRequiredScripts" `
                    -CallerPSCmdlet $CallerPSCmdlet `
                    -ErrorCategory InvalidOperation
            }

            $scriptName = $Matches['ScriptName']
            if ($DependentScriptInfo.ExternalScriptDependencies -contains $scriptName)
            {
                Write-Verbose -Message ($LocalizedData.SkippedScriptDependency -f $scriptName)

                continue
            }

            if ($Matches.Keys -Contains 'Version')
            {
                $ReqScriptInfo = ValidateAndGet-NuspecVersionString -Version $Matches['Version']

                if($ReqScriptInfo.Keys -Contains 'RequiredVersion')
                {
                    $FindScriptArguments['RequiredVersion'] = $ReqScriptInfo['RequiredVersion']
                }
                elseif($ReqScriptInfo.Keys -Contains 'MinimumVersion')
                {
                    $FindScriptArguments['MinimumVersion'] = $ReqScriptInfo['MinimumVersion']
                }
                if($ReqScriptInfo.Keys -Contains 'MaximumVersion')
                {
                    $FindScriptArguments['MaximumVersion'] = $ReqScriptInfo['MaximumVersion']
                }
            }

            $ReqScriptInfo['Name'] = $scriptName
            $FindScriptArguments['Name'] = $scriptName
            $psgetItemInfo = Find-Script @FindScriptArguments  |
                                        Microsoft.PowerShell.Core\Where-Object {$_.Name -eq $scriptName} |
                                            Microsoft.PowerShell.Utility\Select-Object -Last 1 -ErrorAction Ignore

            if(-not $psgetItemInfo)
            {
                $message = $LocalizedData.UnableToResolveScriptDependency -f ('script', $scriptName, $DependentScriptInfo.Name, $Repository, 'ExternalScriptDependencies')
                ThrowError -ExceptionName "System.InvalidOperationException" `
                            -ExceptionMessage $message `
                            -ErrorId "UnableToResolveScriptDependency" `
                            -CallerPSCmdlet $CallerPSCmdlet `
                            -ErrorCategory InvalidOperation
            }

            $DependenciesDetails += $ReqScriptInfo
        }
    }

    return $DependenciesDetails
}