function Install-Module
{
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(DefaultParameterSetName='NameParameterSet',
                   HelpUri='https://go.microsoft.com/fwlink/?LinkID=398573',
                   SupportsShouldProcess=$true)]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName='NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name,

        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName='InputObject')]
        [ValidateNotNull()]
        [PSCustomObject[]]
        $InputObject,

        [Parameter(ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='NameParameterSet')]
        [ValidateNotNull()]
        [string]
        $MinimumVersion,

        [Parameter(ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='NameParameterSet')]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        [Parameter(ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='NameParameterSet')]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        [Parameter(ParameterSetName='NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Repository,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [PSCredential]
        $Credential,

        [Parameter()]
        [ValidateSet("CurrentUser","AllUsers")]
        [string]
        $Scope = "AllUsers",

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
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

        [Parameter(ParameterSetName='NameParameterSet')]
        [switch]
        $AllowPrerelease,

        [Parameter()]
        [switch]
        $AcceptLicense
    )

    Begin
    {
        Get-PSGalleryApiAvailability -Repository $Repository

        if(-not (Test-RunningAsElevated) -and ($Scope -ne "CurrentUser"))
        {
            # Throw an error when Install-Module is used as a non-admin user and '-Scope CurrentUser' is not specified
            $message = $LocalizedData.InstallModuleNeedsCurrentUserScopeParameterForNonAdminUser -f @($script:programFilesModulesPath, $script:MyDocumentsModulesPath)

            ThrowError -ExceptionName "System.ArgumentException" `
                        -ExceptionMessage $message `
                        -ErrorId "InstallModuleNeedsCurrentUserScopeParameterForNonAdminUser" `
                        -CallerPSCmdlet $PSCmdlet `
                        -ErrorCategory InvalidArgument
        }

        Install-NuGetClientBinaries -CallerPSCmdlet $PSCmdlet -Proxy $Proxy -ProxyCredential $ProxyCredential

        # Module names already tried in the current pipeline for InputObject parameterset
        $moduleNamesInPipeline = @()
        $YesToAll = $false
        $NoToAll = $false
        $SourceSGrantedTrust = @()
        $SourcesDeniedTrust = @()
    }

    Process
    {
        $RepositoryIsNotTrusted = $LocalizedData.RepositoryIsNotTrusted
        $QueryInstallUntrustedPackage = $LocalizedData.QueryInstallUntrustedPackage
        $PackageTarget = $LocalizedData.InstallModulewhatIfMessage

        $PSBoundParameters["Provider"] = $script:PSModuleProviderName
        $PSBoundParameters["MessageResolver"] = $script:PackageManagementInstallModuleMessageResolverScriptBlock
        $PSBoundParameters[$script:PSArtifactType] = $script:PSArtifactTypeModule
        $PSBoundParameters['Scope'] = $Scope
        if($AllowPrerelease) {
            $PSBoundParameters[$script:AllowPrereleaseVersions] = $true
        }
        $null = $PSBoundParameters.Remove("AllowPrerelease")

        if($PSCmdlet.ParameterSetName -eq "NameParameterSet")
        {
            $ValidationResult = Validate-VersionParameters -CallerPSCmdlet $PSCmdlet `
                                                           -Name $Name `
                                                           -TestWildcardsInName `
                                                           -MinimumVersion $MinimumVersion `
                                                           -MaximumVersion $MaximumVersion `
                                                           -RequiredVersion $RequiredVersion `
                                                           -AllowPrerelease:$AllowPrerelease

            if(-not $ValidationResult)
            {
                # Validate-VersionParameters throws the error.
                # returning to avoid further execution when different values are specified for -ErrorAction parameter
                return
            }

            if($PSBoundParameters.ContainsKey("Repository"))
            {
                $PSBoundParameters["Source"] = $Repository
                $null = $PSBoundParameters.Remove("Repository")

                $ev = $null
                $null = Get-PSRepository -Name $Repository -ErrorVariable ev -verbose:$false
                if($ev) { return }
            }

            $null = PackageManagement\Install-Package @PSBoundParameters
        }
        elseif($PSCmdlet.ParameterSetName -eq "InputObject")
        {
            $null = $PSBoundParameters.Remove("InputObject")

            foreach($inputValue in $InputObject)
            {
                if (($inputValue.PSTypeNames -notcontains "Microsoft.PowerShell.Commands.PSRepositoryItemInfo") -and
                    ($inputValue.PSTypeNames -notcontains "Deserialized.Microsoft.PowerShell.Commands.PSRepositoryItemInfo") -and
                    ($inputValue.PSTypeNames -notcontains "Microsoft.PowerShell.Commands.PSGetCommandInfo") -and
                    ($inputValue.PSTypeNames -notcontains "Deserialized.Microsoft.PowerShell.Commands.PSGetCommandInfo") -and
                    ($inputValue.PSTypeNames -notcontains "Microsoft.PowerShell.Commands.PSGetDscResourceInfo") -and
                    ($inputValue.PSTypeNames -notcontains "Deserialized.Microsoft.PowerShell.Commands.PSGetDscResourceInfo") -and
                    ($inputValue.PSTypeNames -notcontains "Microsoft.PowerShell.Commands.PSGetRoleCapabilityInfo") -and
                    ($inputValue.PSTypeNames -notcontains "Deserialized.Microsoft.PowerShell.Commands.PSGetRoleCapabilityInfo"))
                {
                    ThrowError -ExceptionName "System.ArgumentException" `
                                -ExceptionMessage $LocalizedData.InvalidInputObjectValue `
                                -ErrorId "InvalidInputObjectValue" `
                                -CallerPSCmdlet $PSCmdlet `
                                -ErrorCategory InvalidArgument `
                                -ExceptionObject $inputValue
                }

                if( ($inputValue.PSTypeNames -contains "Microsoft.PowerShell.Commands.PSGetDscResourceInfo") -or
                    ($inputValue.PSTypeNames -contains "Deserialized.Microsoft.PowerShell.Commands.PSGetDscResourceInfo") -or
                    ($inputValue.PSTypeNames -contains "Microsoft.PowerShell.Commands.PSGetCommandInfo") -or
                    ($inputValue.PSTypeNames -contains "Deserialized.Microsoft.PowerShell.Commands.PSGetCommandInfo") -or
                    ($inputValue.PSTypeNames -contains "Microsoft.PowerShell.Commands.PSGetRoleCapabilityInfo") -or
                    ($inputValue.PSTypeNames -contains "Deserialized.Microsoft.PowerShell.Commands.PSGetRoleCapabilityInfo"))
                {
                    $psgetModuleInfo = $inputValue.PSGetModuleInfo
                }
                else
                {
                    $psgetModuleInfo = $inputValue
                }

                # Skip the module name if it is already tried in the current pipeline
                if($moduleNamesInPipeline -contains $psgetModuleInfo.Name)
                {
                    continue
                }

                $moduleNamesInPipeline += $psgetModuleInfo.Name

                if ($psgetModuleInfo.PowerShellGetFormatVersion -and
                    ($script:SupportedPSGetFormatVersionMajors -notcontains $psgetModuleInfo.PowerShellGetFormatVersion.Major))
                {
                    $message = $LocalizedData.NotSupportedPowerShellGetFormatVersion -f ($psgetModuleInfo.Name, $psgetModuleInfo.PowerShellGetFormatVersion, $psgetModuleInfo.Name)
                    Write-Error -Message $message -ErrorId "NotSupportedPowerShellGetFormatVersion" -Category InvalidOperation
                    continue
                }

                $PSBoundParameters["Name"] = $psgetModuleInfo.Name
                $PSBoundParameters["RequiredVersion"] = $psgetModuleInfo.Version
                $PSBoundParameters['Source'] = $psgetModuleInfo.Repository
                $PSBoundParameters["PackageManagementProvider"] = (Get-ProviderName -PSCustomObject $psgetModuleInfo)

                #Check if module is already installed
                $InstalledModuleInfo = Test-ModuleInstalled -Name $psgetModuleInfo.Name -RequiredVersion $psgetModuleInfo.Version
                if(-not $Force -and $InstalledModuleInfo -ne $null)
                {
                    $message = $LocalizedData.ModuleAlreadyInstalledVerbose -f ($InstalledModuleInfo.Version, $InstalledModuleInfo.Name, $InstalledModuleInfo.ModuleBase)
                    Write-Verbose -Message $message
                }
                else
                {
                    $source =  $psgetModuleInfo.Repository
                    $installationPolicy = (Get-PSRepository -Name $source).InstallationPolicy
                    $ShouldProcessMessage = $PackageTarget -f ($psgetModuleInfo.Name, $psgetModuleInfo.Version)

                    if($psCmdlet.ShouldProcess($ShouldProcessMessage))
                    {
                        if($installationPolicy.Equals("Untrusted", [StringComparison]::OrdinalIgnoreCase))
                        {
    	                    if(-not($YesToAll -or $NoToAll -or $SourceSGrantedTrust.Contains($source) -or $sourcesDeniedTrust.Contains($source) -or $Force))
                            {
	                            $message = $QueryInstallUntrustedPackage -f ($psgetModuleInfo.Name, $psgetModuleInfo.RepositorySourceLocation)
                                if($PSVersionTable.PSVersion -ge '5.0.0')
                                {
                                     $sourceTrusted = $psCmdlet.ShouldContinue("$message", "$RepositoryIsNotTrusted",$true, [ref]$YesToAll, [ref]$NoToAll)
                                }
                                else
                                {
                                     $sourceTrusted = $psCmdlet.ShouldContinue("$message", "$RepositoryIsNotTrusted", [ref]$YesToAll, [ref]$NoToAll)
                                }

                                if($sourceTrusted)
                                {
                                    $SourceSGrantedTrust+=$source
                                }
                                else
                                {
                                    $SourcesDeniedTrust+=$source
                                }
                            }
                        }

                        if($installationPolicy.Equals("trusted", [StringComparison]::OrdinalIgnoreCase) -or $SourceSGrantedTrust.Contains($source) -or $YesToAll -or $Force)
                        {
                            $PSBoundParameters["Force"] = $true
	                        $null = PackageManagement\Install-Package @PSBoundParameters
                        }
                    }
                }
            }
        }
    }
}