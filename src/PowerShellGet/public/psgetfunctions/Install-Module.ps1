function Install-Module {
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(DefaultParameterSetName = 'NameParameterSet',
        HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=398573',
        SupportsShouldProcess = $true)]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'InputObject')]
        [ValidateNotNull()]
        [PSCustomObject[]]
        $InputObject,

        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNull()]
        [string]
        $MinimumVersion,

        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        [Parameter(ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Repository,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        [Parameter()]
        [ValidateSet("CurrentUser", "AllUsers")]
        [string]
        $Scope,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $ProxyCredential,

        [Parameter()]
        [switch]
        $AllowClobber,

        [Parameter()]
        [switch]
        $SkipPublisherCheck,

        [Parameter()]
        [switch]
        $Force,

        [Parameter(ParameterSetName = 'NameParameterSet')]
        [switch]
        $AllowPrerelease,

        [Parameter()]
        [switch]
        $AcceptLicense,

        [Parameter()]
        [switch]
        $PassThru
    )

    Begin {
        # Change security protocol to TLS 1.2
        $script:securityProtocol = [Net.ServicePointManager]::SecurityProtocol
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        if ($Scope -eq "AllUsers" -and -not (Test-RunningAsElevated)) {
            # Throw an error when Install-Module is used as a non-admin user and '-Scope AllUsers'
            $message = $LocalizedData.InstallModuleAdminPrivilegeRequiredForAllUsersScope -f @($script:programFilesModulesPath, $script:MyDocumentsModulesPath)

            ThrowError -ExceptionName "System.ArgumentException" `
                -ExceptionMessage $message `
                -ErrorId "InstallModuleAdminPrivilegeRequiredForAllUsersScope" `
                -CallerPSCmdlet $PSCmdlet `
                -ErrorCategory InvalidArgument
        }

        # If no scope is specified, default installation will be to AllUsers only
        # If running admin on Windows with PowerShell less than v6.
        if (-not $Scope) {
            $Scope = "CurrentUser"
            if (-not $script:IsCoreCLR -and (Test-RunningAsElevated)) {
                $Scope = "AllUsers"
            }
        }

        Install-NuGetClientBinaries -CallerPSCmdlet $PSCmdlet -Proxy $Proxy -ProxyCredential $ProxyCredential

        # Module names already tried in the current pipeline for InputObject parameterset
        $moduleNamesInPipeline = @()
        $YesToAll = $false
        $NoToAll = $false
        $SourceSGrantedTrust = @()
        $SourcesDeniedTrust = @()
    }

    Process {
        $RepositoryIsNotTrusted = $LocalizedData.RepositoryIsNotTrusted
        $QueryInstallUntrustedPackage = $LocalizedData.QueryInstallUntrustedPackage
        $PackageTarget = $LocalizedData.InstallModulewhatIfMessage

        $PSBoundParameters["Provider"] = $script:PSModuleProviderName
        $PSBoundParameters["MessageResolver"] = $script:PackageManagementInstallModuleMessageResolverScriptBlock
        $PSBoundParameters[$script:PSArtifactType] = $script:PSArtifactTypeModule
        $PSBoundParameters['Scope'] = $Scope
        if ($AllowPrerelease) {
            $PSBoundParameters[$script:AllowPrereleaseVersions] = $true
        }
        $null = $PSBoundParameters.Remove("AllowPrerelease")
        $null = $PSBoundParameters.Remove("PassThru")

        if ($PSCmdlet.ParameterSetName -eq "NameParameterSet") {
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

            $installedPackages = PackageManagement\Install-Package @PSBoundParameters

            if ($PassThru) {
                $installedPackages | Microsoft.PowerShell.Core\ForEach-Object { New-PSGetItemInfo -SoftwareIdentity $_ -Type $script:PSArtifactTypeModule }
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq "InputObject") {
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

                #Check if module is already installed
                $InstalledModuleInfo = Test-ModuleInstalled -Name $psgetModuleInfo.Name -RequiredVersion $psgetModuleInfo.Version
                if (-not $Force -and $null -ne $InstalledModuleInfo) {
                    $message = $LocalizedData.ModuleAlreadyInstalledVerbose -f ($InstalledModuleInfo.Version, $InstalledModuleInfo.Name, $InstalledModuleInfo.ModuleBase)
                    Write-Verbose -Message $message
                }
                else {
                    $source = $psgetModuleInfo.Repository
                    $installationPolicy = (Get-PSRepository -Name $source).InstallationPolicy
                    $ShouldProcessMessage = $PackageTarget -f ($psgetModuleInfo.Name, $psgetModuleInfo.Version)

                    if ($psCmdlet.ShouldProcess($ShouldProcessMessage)) {
                        if ($installationPolicy.Equals("Untrusted", [StringComparison]::OrdinalIgnoreCase)) {
                            if (-not($YesToAll -or $NoToAll -or $SourceSGrantedTrust.Contains($source) -or $sourcesDeniedTrust.Contains($source) -or $Force)) {
                                $message = $QueryInstallUntrustedPackage -f ($psgetModuleInfo.Name, $psgetModuleInfo.RepositorySourceLocation)
                                if ($PSVersionTable.PSVersion -ge '5.0.0') {
                                    $sourceTrusted = $psCmdlet.ShouldContinue("$message", "$RepositoryIsNotTrusted", $true, [ref]$YesToAll, [ref]$NoToAll)
                                }
                                else {
                                    $sourceTrusted = $psCmdlet.ShouldContinue("$message", "$RepositoryIsNotTrusted", [ref]$YesToAll, [ref]$NoToAll)
                                }

                                if ($sourceTrusted) {
                                    $SourceSGrantedTrust += $source
                                }
                                else {
                                    $SourcesDeniedTrust += $source
                                }
                            }
                        }

                        if ($installationPolicy.Equals("trusted", [StringComparison]::OrdinalIgnoreCase) -or $SourceSGrantedTrust.Contains($source) -or $YesToAll -or $Force) {
                            $PSBoundParameters["Force"] = $true
                            $installedPackages = PackageManagement\Install-Package @PSBoundParameters

                            if ($PassThru) {
                                $installedPackages | Microsoft.PowerShell.Core\ForEach-Object { New-PSGetItemInfo -SoftwareIdentity $_ -Type $script:PSArtifactTypeModule }
                            }
                        }
                    }
                }
            }
        }
    }

    End {
        # Change back to user specified security protocol
        [Net.ServicePointManager]::SecurityProtocol = $script:securityProtocol
    }
}
