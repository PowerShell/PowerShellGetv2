function ValidateAndAdd-PSScriptInfoEntry
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $PSScriptInfo,

        [Parameter(Mandatory=$true)]
        [string]
        $PropertyName,

        [Parameter()]
        $PropertyValue,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet
    )

    $Value = $PropertyValue
    $KeyName = $PropertyName

    # return if $KeyName value is not null in $PSScriptInfo
    if(-not $value -or -not $KeyName -or (Get-Member -InputObject $PSScriptInfo -Name $KeyName) -and $PSScriptInfo."$KeyName")
    {
        return
    }

    switch($PropertyName)
    {
        # Validate the property value and also use proper key name as users can specify the property name in any case.
        $script:Version {
                            $KeyName = $script:Version
                            $result = ValidateAndGet-VersionPrereleaseStrings -Version $Value -CallerPSCmdlet $CallerPSCmdlet
                            if (-not $result)
                            {
                                # ValidateAndGet-VersionPrereleaseStrings throws the error.
                                # returning to avoid further execution when different values are specified for -ErrorAction parameter
                                return
                            }
                            $Version = $result["Version"]
                            $Prerelease = $result["Prerelease"]
                            $fullVersion = $result["FullVersion"]
                            $Value = if ($Prerelease) { $fullVersion } else { $Version }
                            break
                        }

        $script:Author  { $KeyName = $script:Author }

        $script:Guid  {
                        $KeyName = $script:Guid

                        [Guid]$guid = [System.Guid]::Empty
                        if([System.Guid]::TryParse($Value, ([ref]$guid)))
                        {
                            $Value = $guid
                        }
                        else
                        {
                            $message = $LocalizedData.InvalidGuid -f ($Value)
                            ThrowError -ExceptionName 'System.ArgumentException' `
                                       -ExceptionMessage $message `
                                       -ErrorId 'InvalidGuid' `
                                       -CallerPSCmdlet $CallerPSCmdlet `
                                       -ErrorCategory InvalidArgument `
                                       -ExceptionObject $Value
                            return
                        }

                        break
                     }

        $script:Description { $KeyName = $script:Description }

        $script:CompanyName { $KeyName = $script:CompanyName }

        $script:Copyright { $KeyName = $script:Copyright }

        $script:Tags {
                        $KeyName = $script:Tags
                        $Value = $Value -split '[,\s+]' | Microsoft.PowerShell.Core\Where-Object {$_}
                        break
                     }

        $script:LicenseUri {
                                $KeyName = $script:LicenseUri
                                if(-not (Test-WebUri -Uri $Value))
                                {
                                    $message = $LocalizedData.InvalidWebUri -f ($LicenseUri, "LicenseUri")
                                    ThrowError -ExceptionName "System.ArgumentException" `
                                                -ExceptionMessage $message `
                                                -ErrorId "InvalidWebUri" `
                                                -CallerPSCmdlet $CallerPSCmdlet `
                                                -ErrorCategory InvalidArgument `
                                                -ExceptionObject $Value
                                    return
                                }

                                $Value = [Uri]$Value
                           }

        $script:ProjectUri {
                                $KeyName = $script:ProjectUri
                                if(-not (Test-WebUri -Uri $Value))
                                {
                                    $message = $LocalizedData.InvalidWebUri -f ($ProjectUri, "ProjectUri")
                                    ThrowError -ExceptionName "System.ArgumentException" `
                                                -ExceptionMessage $message `
                                                -ErrorId "InvalidWebUri" `
                                                -CallerPSCmdlet $CallerPSCmdlet `
                                                -ErrorCategory InvalidArgument `
                                                -ExceptionObject $Value
                                    return
                                }

                                $Value = [Uri]$Value
                           }

        $script:IconUri {
                            $KeyName = $script:IconUri
                            if(-not (Test-WebUri -Uri $Value))
                            {
                                $message = $LocalizedData.InvalidWebUri -f ($IconUri, "IconUri")
                                ThrowError -ExceptionName "System.ArgumentException" `
                                            -ExceptionMessage $message `
                                            -ErrorId "InvalidWebUri" `
                                            -CallerPSCmdlet $CallerPSCmdlet `
                                            -ErrorCategory InvalidArgument `
                                            -ExceptionObject $Value
                                return
                            }

                            $Value = [Uri]$Value
                        }

        $script:ExternalModuleDependencies {
                                               $KeyName = $script:ExternalModuleDependencies
                                               $Value = $Value -split '[,\s+]' | Microsoft.PowerShell.Core\Where-Object {$_}
                                           }

        $script:ReleaseNotes { $KeyName = $script:ReleaseNotes }

        $script:RequiredModules { $KeyName = $script:RequiredModules }

        $script:RequiredScripts {
                                    $KeyName = $script:RequiredScripts
                                    $Value = $Value -split ',(?=[^\[^\(]\w(?!\w+[\)\]]))|\s' | Microsoft.PowerShell.Core\Where-Object {$_}
                                }

        $script:ExternalScriptDependencies {
                                               $KeyName = $script:ExternalScriptDependencies
                                               $Value = $Value -split '[,\s+]' | Microsoft.PowerShell.Core\Where-Object {$_}
                                           }

        $script:DefinedCommands  { $KeyName = $script:DefinedCommands }

        $script:DefinedFunctions { $KeyName = $script:DefinedFunctions }

        $script:DefinedWorkflows { $KeyName = $script:DefinedWorkflows }

		$script:PrivateData { $KeyName = $script:PrivateData }
    }

    Microsoft.PowerShell.Utility\Add-Member -InputObject $PSScriptInfo `
                                            -MemberType NoteProperty `
                                            -Name $KeyName `
                                            -Value $Value `
                                            -Force
}