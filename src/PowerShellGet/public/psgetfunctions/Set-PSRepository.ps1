function Set-PSRepository {
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(PositionalBinding = $false,
        HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=517128')]
    Param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $SourceLocation,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $PublishLocation,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $ScriptSourceLocation,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $ScriptPublishLocation,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $Credential,

        [Parameter()]
        [ValidateSet('Trusted', 'Untrusted')]
        [string]
        $InstallationPolicy,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $ProxyCredential,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $PackageManagementProvider
    )

    DynamicParam {
        if (Get-Variable -Name Name -ErrorAction SilentlyContinue) {
            $moduleSource = Get-PSRepository -Name $Name -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

            if ($moduleSource) {
                $providerName = (Get-ProviderName -PSCustomObject $moduleSource)

                $loc = $moduleSource.SourceLocation

                if (Get-Variable -Name SourceLocation -ErrorAction SilentlyContinue) {
                    $loc = $SourceLocation
                }

                if (Get-Variable -Name PackageManagementProvider -ErrorAction SilentlyContinue) {
                    $providerName = $PackageManagementProvider
                }

                $null = Get-DynamicParameters -Location $loc -PackageManagementProvider ([REF]$providerName)
            }
        }
    }

    Begin {
        Install-NuGetClientBinaries -CallerPSCmdlet $PSCmdlet -Proxy $Proxy -ProxyCredential $ProxyCredential

        if ($PackageManagementProvider) {
            $providers = PackageManagement\Get-PackageProvider | Where-Object { $_.Name -ne $script:PSModuleProviderName -and $_.Features.ContainsKey($script:SupportsPSModulesFeatureName) }

            if (-not $providers -or $providers.Name -notcontains $PackageManagementProvider) {
                $possibleProviderNames = $script:NuGetProviderName

                if ($providers) {
                    $possibleProviderNames = ($providers.Name -join ',')
                }

                $message = $LocalizedData.InvalidPackageManagementProviderValue -f ($PackageManagementProvider, $possibleProviderNames, $script:NuGetProviderName)
                ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId "InvalidPackageManagementProviderValue" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidArgument `
                    -ExceptionObject $PackageManagementProvider
                return
            }
        }
    }

    Process {
        # Ping and resolve the specified location
        if ($SourceLocation) {
            # Ping and resolve the specified location
            $SourceLocation = Resolve-Location -Location (Get-LocationString -LocationUri $SourceLocation) `
                -LocationParameterName 'SourceLocation' `
                -Credential $Credential `
                -Proxy $Proxy `
                -ProxyCredential $ProxyCredential `
                -CallerPSCmdlet $PSCmdlet
            if (-not $SourceLocation) {
                # Above Resolve-Location function throws an error when it is not able to resolve a location
                return
            }
        }

        $ModuleSource = Get-PSRepository -Name $Name -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

        if (-not $ModuleSource) {
            $message = $LocalizedData.RepositoryNotFound -f ($Name)

            ThrowError -ExceptionName "System.InvalidOperationException" `
                -ExceptionMessage $message `
                -ErrorId "RepositoryNotFound" `
                -CallerPSCmdlet $PSCmdlet `
                -ErrorCategory InvalidOperation `
                -ExceptionObject $Name
        }

        if (-not $PackageManagementProvider) {
            $PackageManagementProvider = (Get-ProviderName -PSCustomObject $ModuleSource)
        }

        $Trusted = $ModuleSource.Trusted
        if ($InstallationPolicy) {
            if ($InstallationPolicy -eq "Trusted") {
                $Trusted = $true
            }
            else {
                $Trusted = $false
            }

            $null = $PSBoundParameters.Remove("InstallationPolicy")
        }

        if ($PublishLocation) {
            $PSBoundParameters[$script:PublishLocation] = Get-LocationString -LocationUri $PublishLocation
        }

        if ($ScriptPublishLocation) {
            $PSBoundParameters[$script:ScriptPublishLocation] = Get-LocationString -LocationUri $ScriptPublishLocation
        }

        if ($ScriptSourceLocation) {
            $PSBoundParameters[$script:ScriptSourceLocation] = Get-LocationString -LocationUri $ScriptSourceLocation
        }

        if ($SourceLocation) {
            $PSBoundParameters["NewLocation"] = Get-LocationString -LocationUri $SourceLocation

            $null = $PSBoundParameters.Remove("SourceLocation")
        }

        $PSBoundParameters[$script:PackageManagementProviderParam] = $PackageManagementProvider
        $PSBoundParameters["Trusted"] = $Trusted
        $PSBoundParameters["Provider"] = $script:PSModuleProviderName
        $PSBoundParameters["MessageResolver"] = $script:PackageManagementMessageResolverScriptBlock

        $null = PackageManagement\Set-PackageSource @PSBoundParameters
    }
}
