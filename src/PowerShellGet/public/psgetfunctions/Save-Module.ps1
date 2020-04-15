function Save-Module {
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(DefaultParameterSetName = 'NameAndPathParameterSet',
        HelpUri = 'https://go.microsoft.com/fwlink/?LinkId=531351',
        SupportsShouldProcess = $true)]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'InputObjectAndPathParameterSet')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'InputObjectAndLiteralPathParameterSet')]
        [ValidateNotNull()]
        [PSCustomObject[]]
        $InputObject,

        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateNotNull()]
        [string]
        $MinimumVersion,

        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Repository,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'InputObjectAndPathParameterSet')]
        [string]
        $Path,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'InputObjectAndLiteralPathParameterSet')]
        [Alias('PSPath')]
        [string]
        $LiteralPath,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $ProxyCredential,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        [Parameter()]
        [switch]
        $Force,

        [Parameter(ParameterSetName = 'NameAndPathParameterSet')]
        [Parameter(ParameterSetName = 'NameAndLiteralPathParameterSet')]
        [switch]
        $AllowPrerelease,

        [Parameter()]
        [switch]
        $AcceptLicense
    )

    Begin {
        # Change security protocol to TLS 1.2
        $script:securityProtocol = [Net.ServicePointManager]::SecurityProtocol
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        Install-NuGetClientBinaries -CallerPSCmdlet $PSCmdlet -Proxy $Proxy -ProxyCredential $ProxyCredential

        # Module names already tried in the current pipeline for InputObject parameterset
        $moduleNamesInPipeline = @()
    }

    Process {
        $PSBoundParameters["Provider"] = $script:PSModuleProviderName
        $PSBoundParameters["MessageResolver"] = $script:PackageManagementSaveModuleMessageResolverScriptBlock
        $PSBoundParameters[$script:PSArtifactType] = $script:PSArtifactTypeModule
        if ($AllowPrerelease) {
            $PSBoundParameters[$script:AllowPrereleaseVersions] = $true
        }
        $null = $PSBoundParameters.Remove("AllowPrerelease")

        # When -Force is specified, Path will be created if not available.
        if (-not $Force) {
            if ($Path) {
                $destinationPath = Resolve-PathHelper -Path $Path -CallerPSCmdlet $PSCmdlet | Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

                if (-not $destinationPath -or -not (Microsoft.PowerShell.Management\Test-path $destinationPath)) {
                    $errorMessage = ($LocalizedData.PathNotFound -f $Path)
                    ThrowError  -ExceptionName "System.ArgumentException" `
                        -ExceptionMessage $errorMessage `
                        -ErrorId "PathNotFound" `
                        -CallerPSCmdlet $PSCmdlet `
                        -ExceptionObject $Path `
                        -ErrorCategory InvalidArgument
                }

                $PSBoundParameters['Path'] = $destinationPath
            }
            else {
                $destinationPath = Resolve-PathHelper -Path $LiteralPath -IsLiteralPath -CallerPSCmdlet $PSCmdlet | Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

                if (-not $destinationPath -or -not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $destinationPath)) {
                    $errorMessage = ($LocalizedData.PathNotFound -f $LiteralPath)
                    ThrowError  -ExceptionName "System.ArgumentException" `
                        -ExceptionMessage $errorMessage `
                        -ErrorId "PathNotFound" `
                        -CallerPSCmdlet $PSCmdlet `
                        -ExceptionObject $LiteralPath `
                        -ErrorCategory InvalidArgument
                }

                $PSBoundParameters['LiteralPath'] = $destinationPath
            }
        }

        if ($Name) {
            $ValidationResult = Validate-VersionParameters -CallerPSCmdlet $PSCmdlet `
                -Name $Name `
                -TestWildcardsInName `
                -MinimumVersion $MinimumVersion `
                -MaximumVersion $MaximumVersion `
                -RequiredVersion $RequiredVersion `
                -AllowPrerelease:$AllowPrerelease

            if (-not $ValidationResult) {
                # Validate-VersionParameters throws the error.
                # returning to avoid further execution when different values are specified for -ErrorAction parameter
                return
            }

            if ($PSBoundParameters.ContainsKey("Repository")) {
                $PSBoundParameters["Source"] = $Repository
                $null = $PSBoundParameters.Remove("Repository")

                $ev = $null
                $null = Get-PSRepository -Name $Repository -ErrorVariable ev -verbose:$false
                if ($ev) { return }
            }

            $null = PackageManagement\Save-Package @PSBoundParameters
        }
        elseif ($InputObject) {
            $null = $PSBoundParameters.Remove("InputObject")

            foreach ($inputValue in $InputObject) {
                if (($inputValue.PSTypeNames -notcontains "Microsoft.PowerShell.Commands.PSRepositoryItemInfo") -and
                    ($inputValue.PSTypeNames -notcontains "Deserialized.Microsoft.PowerShell.Commands.PSRepositoryItemInfo") -and
                    ($inputValue.PSTypeNames -notcontains "Microsoft.PowerShell.Commands.PSGetCommandInfo") -and
                    ($inputValue.PSTypeNames -notcontains "Deserialized.Microsoft.PowerShell.Commands.PSGetCommandInfo") -and
                    ($inputValue.PSTypeNames -notcontains "Microsoft.PowerShell.Commands.PSGetDscResourceInfo") -and
                    ($inputValue.PSTypeNames -notcontains "Deserialized.Microsoft.PowerShell.Commands.PSGetDscResourceInfo") -and
                    ($inputValue.PSTypeNames -notcontains "Microsoft.PowerShell.Commands.PSGetRoleCapabilityInfo") -and
                    ($inputValue.PSTypeNames -notcontains "Deserialized.Microsoft.PowerShell.Commands.PSGetRoleCapabilityInfo")) {
                    ThrowError -ExceptionName "System.ArgumentException" `
                        -ExceptionMessage $LocalizedData.InvalidInputObjectValue `
                        -ErrorId "InvalidInputObjectValue" `
                        -CallerPSCmdlet $PSCmdlet `
                        -ErrorCategory InvalidArgument `
                        -ExceptionObject $inputValue
                }

                if ( ($inputValue.PSTypeNames -contains "Microsoft.PowerShell.Commands.PSGetDscResourceInfo") -or
                    ($inputValue.PSTypeNames -contains "Deserialized.Microsoft.PowerShell.Commands.PSGetDscResourceInfo") -or
                    ($inputValue.PSTypeNames -contains "Microsoft.PowerShell.Commands.PSGetCommandInfo") -or
                    ($inputValue.PSTypeNames -contains "Deserialized.Microsoft.PowerShell.Commands.PSGetCommandInfo") -or
                    ($inputValue.PSTypeNames -contains "Microsoft.PowerShell.Commands.PSGetRoleCapabilityInfo") -or
                    ($inputValue.PSTypeNames -contains "Deserialized.Microsoft.PowerShell.Commands.PSGetRoleCapabilityInfo")) {
                    $psgetModuleInfo = $inputValue.PSGetModuleInfo
                }
                else {
                    $psgetModuleInfo = $inputValue
                }

                # Skip the module name if it is already tried in the current pipeline
                if ($moduleNamesInPipeline -contains $psgetModuleInfo.Name) {
                    continue
                }

                $moduleNamesInPipeline += $psgetModuleInfo.Name

                if ($psgetModuleInfo.PowerShellGetFormatVersion -and
                    ($script:SupportedPSGetFormatVersionMajors -notcontains $psgetModuleInfo.PowerShellGetFormatVersion.Major)) {
                    $message = $LocalizedData.NotSupportedPowerShellGetFormatVersion -f ($psgetModuleInfo.Name, $psgetModuleInfo.PowerShellGetFormatVersion, $psgetModuleInfo.Name)
                    Write-Error -Message $message -ErrorId "NotSupportedPowerShellGetFormatVersion" -Category InvalidOperation
                    continue
                }

                $PSBoundParameters["Name"] = $psgetModuleInfo.Name
                $PSBoundParameters["RequiredVersion"] = $psgetModuleInfo.Version
                if (($psgetModuleInfo.AdditionalMetadata) -and
                    (Get-Member -InputObject $psgetModuleInfo.AdditionalMetadata -Name "IsPrerelease") -and
                    ($psgetModuleInfo.AdditionalMetadata.IsPrerelease -eq "true")) {
                    $PSBoundParameters[$script:AllowPrereleaseVersions] = $true
                }
                elseif ($PSBoundParameters.ContainsKey($script:AllowPrereleaseVersions)) {
                    $null = $PSBoundParameters.Remove($script:AllowPrereleaseVersions)
                }
                $PSBoundParameters['Source'] = $psgetModuleInfo.Repository
                $PSBoundParameters["PackageManagementProvider"] = (Get-ProviderName -PSCustomObject $psgetModuleInfo)

                $null = PackageManagement\Save-Package @PSBoundParameters
            }
        }
    }

    End {
        # Change back to user specified security protocol
        [Net.ServicePointManager]::SecurityProtocol = $script:securityProtocol
    }
}
