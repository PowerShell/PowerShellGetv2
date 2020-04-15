function Save-Script {
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(DefaultParameterSetName = 'NameAndPathParameterSet',
        HelpUri = 'https://go.microsoft.com/fwlink/?LinkId=619786',
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
            ValueFromPipelineByPropertyName = $true,
            Position = 1,
            ParameterSetName = 'NameAndPathParameterSet')]

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1,
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

        # Script names already tried in the current pipeline for InputObject parameterset
        $scriptNamesInPipeline = @()
    }

    Process {
        $PSBoundParameters["Provider"] = $script:PSModuleProviderName
        $PSBoundParameters["MessageResolver"] = $script:PackageManagementSaveScriptMessageResolverScriptBlock
        $PSBoundParameters[$script:PSArtifactType] = $script:PSArtifactTypeScript
        if ($AllowPrerelease) {
            $PSBoundParameters[$script:AllowPrereleaseVersions] = $true
        }
        $null = $PSBoundParameters.Remove("AllowPrerelease")

        # When -Force is specified, Path will be created if not available.
        if (-not $Force) {
            if ($Path) {
                $destinationPath = Resolve-PathHelper -Path $Path -CallerPSCmdlet $PSCmdlet |
                Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

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
                $destinationPath = Resolve-PathHelper -Path $LiteralPath -IsLiteralPath -CallerPSCmdlet $PSCmdlet |
                Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

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
                $repositories = Get-PSRepository -Name $Repository -ErrorVariable ev -verbose:$false
                if ($ev) { return }

                $RepositoriesWithoutScriptSourceLocation = $false
                foreach ($repo in $repositories) {
                    if (-not $repo.ScriptSourceLocation) {
                        $message = $LocalizedData.ScriptSourceLocationIsMissing -f ($repo.Name)
                        Write-Error -Message $message `
                            -ErrorId 'ScriptSourceLocationIsMissing' `
                            -Category InvalidArgument `
                            -TargetObject $repo.Name `
                            -Exception 'System.ArgumentException'

                        $RepositoriesWithoutScriptSourceLocation = $true
                    }
                }

                if ($RepositoriesWithoutScriptSourceLocation) {
                    return
                }
            }

            $null = PackageManagement\Save-Package @PSBoundParameters
        }
        elseif ($InputObject) {
            $null = $PSBoundParameters.Remove("InputObject")

            foreach ($inputValue in $InputObject) {
                if (($inputValue.PSTypeNames -notcontains "Microsoft.PowerShell.Commands.PSRepositoryItemInfo") -and
                    ($inputValue.PSTypeNames -notcontains "Deserialized.Microsoft.PowerShell.Commands.PSRepositoryItemInfo")) {
                    ThrowError -ExceptionName "System.ArgumentException" `
                        -ExceptionMessage $LocalizedData.InvalidInputObjectValue `
                        -ErrorId "InvalidInputObjectValue" `
                        -CallerPSCmdlet $PSCmdlet `
                        -ErrorCategory InvalidArgument `
                        -ExceptionObject $inputValue
                }

                $psRepositoryItemInfo = $inputValue

                # Skip the script name if it is already tried in the current pipeline
                if ($scriptNamesInPipeline -contains $psRepositoryItemInfo.Name) {
                    continue
                }

                $scriptNamesInPipeline += $psRepositoryItemInfo.Name

                if ($psRepositoryItemInfo.PowerShellGetFormatVersion -and
                    ($script:SupportedPSGetFormatVersionMajors -notcontains $psRepositoryItemInfo.PowerShellGetFormatVersion.Major)) {
                    $message = $LocalizedData.NotSupportedPowerShellGetFormatVersionScripts -f ($psRepositoryItemInfo.Name, $psRepositoryItemInfo.PowerShellGetFormatVersion, $psRepositoryItemInfo.Name)
                    Write-Error -Message $message -ErrorId "NotSupportedPowerShellGetFormatVersion" -Category InvalidOperation
                    continue
                }

                $PSBoundParameters["Name"] = $psRepositoryItemInfo.Name
                $PSBoundParameters["RequiredVersion"] = $psRepositoryItemInfo.Version
                if (($psRepositoryItemInfo.AdditionalMetadata) -and
                    (Get-Member -InputObject $psRepositoryItemInfo.AdditionalMetadata -Name "IsPrerelease") -and
                    ($psRepositoryItemInfo.AdditionalMetadata.IsPrerelease -eq "true")) {
                    $PSBoundParameters[$script:AllowPrereleaseVersions] = $true
                }
                elseif ($PSBoundParameters.ContainsKey($script:AllowPrereleaseVersions)) {
                    $null = $PSBoundParameters.Remove($script:AllowPrereleaseVersions)
                }
                $PSBoundParameters['Source'] = $psRepositoryItemInfo.Repository
                $PSBoundParameters["PackageManagementProvider"] = (Get-ProviderName -PSCustomObject $psRepositoryItemInfo)

                $null = PackageManagement\Save-Package @PSBoundParameters
            }
        }
    }

    End {
        # Change back to user specified security protocol
        [Net.ServicePointManager]::SecurityProtocol = $script:securityProtocol
    }
}
