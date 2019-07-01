function Register-PSRepository {
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(DefaultParameterSetName = 'NameParameterSet',
        HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=517129')]
    Param
    (
        [Parameter(Mandatory = $true,
            Position = 0,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(Mandatory = $true,
            Position = 1,
            ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $SourceLocation,

        [Parameter(ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $PublishLocation,

        [Parameter(ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $ScriptSourceLocation,

        [Parameter(ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $ScriptPublishLocation,

        [Parameter(ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NameParameterSet')]
        [PSCredential]
        $Credential,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'PSGalleryParameterSet')]
        [Switch]
        $Default,

        [Parameter()]
        [ValidateSet('Trusted', 'Untrusted')]
        [string]
        $InstallationPolicy = 'Untrusted',

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]
        $ProxyCredential,

        [Parameter(ParameterSetName = 'NameParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string]
        $PackageManagementProvider
    )

    DynamicParam {
        if (Get-Variable -Name SourceLocation -ErrorAction SilentlyContinue) {
            Set-Variable -Name selectedProviderName -value $null -Scope 1

            if (Get-Variable -Name PackageManagementProvider -ErrorAction SilentlyContinue) {
                $selectedProviderName = $PackageManagementProvider
                $null = Get-DynamicParameters -Location $SourceLocation -PackageManagementProvider ([REF]$selectedProviderName)
            }
            else {
                $dynamicParameters = Get-DynamicParameters -Location $SourceLocation -PackageManagementProvider ([REF]$selectedProviderName)
                Set-Variable -Name PackageManagementProvider -Value $selectedProviderName -Scope 1
                $null = $dynamicParameters
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
        if ($PSCmdlet.ParameterSetName -eq 'PSGalleryParameterSet') {
            if (-not $Default) {
                return
            }

            $PSBoundParameters['Name'] = $Script:PSGalleryModuleSource
            $null = $PSBoundParameters.Remove('Default')
        }
        else {
            if ($Name -eq $Script:PSGalleryModuleSource) {
                $message = $LocalizedData.UseDefaultParameterSetOnRegisterPSRepository
                ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId 'UseDefaultParameterSetOnRegisterPSRepository' `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidArgument `
                    -ExceptionObject $Name
                return
            }

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

            $pingResult = Ping-Endpoint -Endpoint (Get-LocationString -LocationUri $SourceLocation) -Credential $Credential -Proxy $Proxy -ProxyCredential $ProxyCredential

            $retrievedCredential = $null
            if (!$Credential -and $pingResult -and $pingResult.ContainsKey($Script:StatusCode) `
                    -and ($pingResult[$Script:StatusCode] -eq 401)) {

                # Try pulling credentials from credential provider
                $retrievedCredential = Get-CredsFromCredentialProvider -SourceLocation $SourceLocation

                # Ping and resolve the specified location
                $SourceLocation = Resolve-Location -Location (Get-LocationString -LocationUri $SourceLocation) `
                    -LocationParameterName 'SourceLocation' `
                    -Credential $retrievedCredential `
                    -Proxy $Proxy `
                    -ProxyCredential $ProxyCredential `
                    -CallerPSCmdlet $PSCmdlet
                if (-not $SourceLocation) {
                    # Above Resolve-Location function throws an error when it is not able to resolve a location
                    return
                }

                $pingResult = Ping-Endpoint -Endpoint (Get-LocationString -LocationUri $SourceLocation) -Credential $retrievedCredential -Proxy $Proxy -ProxyCredential $ProxyCredential

                if (!$retrievedCredential -or ($pingResult -and $pingResult.ContainsKey($Script:StatusCode) `
                            -and ($pingResult[$Script:StatusCode] -eq 401))) {

                    # Try again
                    $retriedRetrievedCredential = Get-CredsFromCredentialProvider -SourceLocation $SourceLocation -IsRetry $true

                    # Ping and resolve the specified location
                    $SourceLocation = Resolve-Location -Location (Get-LocationString -LocationUri $SourceLocation) `
                        -LocationParameterName 'SourceLocation' `
                        -Credential $retriedRetrievedCredential `
                        -Proxy $Proxy `
                        -ProxyCredential $ProxyCredential `
                        -CallerPSCmdlet $PSCmdlet

                    if (-not $SourceLocation) {
                        # Above Resolve-Location function throws an error when it is not able to resolve a location
                        return
                    }

                    $pingResult = Ping-Endpoint -Endpoint (Get-LocationString -LocationUri $SourceLocation) -Credential $retrievedCredential -Proxy $Proxy -ProxyCredential $ProxyCredential

                    if (!$retriedRetrievedCredential -or ($pingResult -and $pingResult.ContainsKey($Script:StatusCode) `
                                -and ($pingResult[$Script:StatusCode] -eq 401))) {

                        $message = $LocalizedData.RepositoryCannotBeRegistered -f ($Name)
                        Write-Error -Message $message -ErrorId "RepositoryCannotBeRegistered" -Category InvalidOperation

                        return
                    }
                }
            }

            $providerName = $null

            if ($PackageManagementProvider) {
                $providerName = $PackageManagementProvider
            }
            elseif ($selectedProviderName) {
                $providerName = $selectedProviderName
            }
            else {
                $providerName = Get-PackageManagementProviderName -Location $SourceLocation
            }

            if ($providerName) {
                $PSBoundParameters[$script:PackageManagementProviderParam] = $providerName
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

            $PSBoundParameters["Location"] = Get-LocationString -LocationUri $SourceLocation
            $null = $PSBoundParameters.Remove("SourceLocation")
        }

        if ($InstallationPolicy -eq "Trusted") {
            $PSBoundParameters['Trusted'] = $true
        }
        $null = $PSBoundParameters.Remove("InstallationPolicy")

        $PSBoundParameters["Provider"] = $script:PSModuleProviderName
        $PSBoundParameters["MessageResolver"] = $script:PackageManagementMessageResolverScriptBlock

        $null = PackageManagement\Register-PackageSource @PSBoundParameters

        # add nuget based repo as a nuget source
        $nugetCmd = Microsoft.PowerShell.Core\Get-Command -Name $script:NuGetExeName `
            -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

        if ($nugetCmd) {
            $nugetSourceExists = nuget sources list | where-object { $_.Trim() -in $SourceLocation }
            if (!$nugetSourceExists) {
                nuget sources add -name $Name -source $SourceLocation
            }
        }
    }
}
