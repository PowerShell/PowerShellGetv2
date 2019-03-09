function Validate-ModuleAuthenticodeSignature
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $CurrentModuleInfo,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InstallLocation,

        [Parameter()]
        [Switch]
        $IsUpdateOperation,

        [Parameter()]
        [Switch]
        $SkipPublisherCheck
    )

    # Skip the publisher check when -SkipPublisherCheck is specified and
    # it is not an update operation.
    if(-not $IsUpdateOperation -and $SkipPublisherCheck)
    {
        $Message = $LocalizedData.SkippingPublisherCheck -f ($CurrentModuleInfo.Version, $CurrentModuleInfo.Name)
        Write-Verbose -Message $message

        return $true
    }

    $InstalledModuleDetails = $null
    $InstalledModuleInfo = Test-ModuleInstalled -Name $CurrentModuleInfo.Name
    if($InstalledModuleInfo)
    {
        $InstalledModuleDetails = Get-InstalledModuleAuthenticodeSignature -InstalledModuleInfo $InstalledModuleInfo `
                                                                           -InstallLocation $InstallLocation
    }

    # Validate the catalog signature for the current module being installed.
    $ev = $null
    $CurrentModuleDetails = ValidateAndGet-AuthenticodeSignature -ModuleInfo $CurrentModuleInfo -ErrorVariable ev

    if($ev)
    {
        Write-Debug "$ev"
        return $false
    }

    if($InstalledModuleInfo)
    {
        $CurrentModuleAuthenticodePublisher = $null
        $CurrentModuleRootCA = $null
        $IsCurrentModuleSignedByMicrosoft = $false

        if($CurrentModuleDetails)
        {
            $CurrentModuleAuthenticodePublisher = $CurrentModuleDetails.Publisher
            $CurrentModuleRootCA = $CurrentModuleDetails.RootCertificateAuthority
            $IsCurrentModuleSignedByMicrosoft = $CurrentModuleDetails.IsMicrosoftCertificate

            $message = $LocalizedData.NewModuleVersionDetailsForPublisherValidation -f ($CurrentModuleInfo.Name,
                                                                                        $CurrentModuleInfo.Version,
                                                                                        $CurrentModuleDetails.Publisher,
                                                                                        $CurrentModuleDetails.RootCertificateAuthority,
                                                                                        $CurrentModuleDetails.IsMicrosoftCertificate)
            Write-Verbose $message
        }

        $InstalledModuleAuthenticodePublisher = $null
        $InstalledModuleRootCA = $null
        $IsInstalledModuleSignedByMicrosoft = $false
        $InstalledModuleVersion = [Version]'0.0'

        if($InstalledModuleDetails)
        {
            $InstalledModuleAuthenticodePublisher = $InstalledModuleDetails.Publisher
            $InstalledModuleRootCA = $InstalledModuleDetails.RootCertificateAuthority
            $IsInstalledModuleSignedByMicrosoft = $InstalledModuleDetails.IsMicrosoftCertificate
            $InstalledModuleVersion = $InstalledModuleDetails.Version

            $message = $LocalizedData.SourceModuleDetailsForPublisherValidation -f ($CurrentModuleInfo.Name,
                                                                                    $InstalledModuleDetails.Version,
                                                                                    $InstalledModuleDetails.ModuleBase,
                                                                                    $InstalledModuleDetails.Publisher,
                                                                                    $InstalledModuleDetails.RootCertificateAuthority,
                                                                                    $InstalledModuleDetails.IsMicrosoftCertificate)
            Write-Verbose $message
        }

        Write-Debug -Message "Previously-installed module publisher: $InstalledModuleAuthenticodePublisher"
        Write-Debug -Message "Current module publisher: $CurrentModuleAuthenticodePublisher"
        Write-Debug -Message "Is previously-installed module signed by Microsoft: $IsInstalledModuleSignedByMicrosoft"
        Write-Debug -Message "Is current module signed by Microsoft: $IsCurrentModuleSignedByMicrosoft"

        if($InstalledModuleAuthenticodePublisher)
        {
            if(-not $CurrentModuleAuthenticodePublisher)
            {
                $Message = $LocalizedData.ModuleIsNotCatalogSigned -f ($CurrentModuleInfo.Version, $CurrentModuleInfo.Name, "$($CurrentModuleInfo.Name).cat", $InstalledModuleAuthenticodePublisher, $InstalledModuleDetails.Version, $InstalledModuleDetails.ModuleBase)
                ThrowError -ExceptionName 'System.InvalidOperationException' `
                            -ExceptionMessage $message `
                            -ErrorId 'ModuleIsNotCatalogSigned' `
                            -CallerPSCmdlet $PSCmdlet `
                            -ErrorCategory InvalidOperation
                return $false
            }
            elseif(($InstalledModuleAuthenticodePublisher -eq $CurrentModuleAuthenticodePublisher) -and
                    $InstalledModuleRootCA -and $CurrentModuleRootCA -and 
                    ($InstalledModuleRootCA -eq $CurrentModuleRootCA))
            {
                $Message = $LocalizedData.AuthenticodeIssuerMatch -f ($CurrentModuleAuthenticodePublisher, $CurrentModuleInfo.Name, $CurrentModuleInfo.Version, $InstalledModuleAuthenticodePublisher, $InstalledModuleInfo.Name, $InstalledModuleVersion)
                Write-Verbose -Message $message
            }
            elseif($IsInstalledModuleSignedByMicrosoft)
            {
                if($IsCurrentModuleSignedByMicrosoft)
                {
                    $Message = $LocalizedData.PublishersMatch -f ($CurrentModuleAuthenticodePublisher, $CurrentModuleInfo.Name, $CurrentModuleInfo.Version, $InstalledModuleAuthenticodePublisher, $InstalledModuleInfo.Name, $InstalledModuleVersion)
                    Write-Verbose -Message $message
                }
                else
                {
                    if (-not $script:WhitelistedModules.ContainsKey($CurrentModuleInfo.Name)) {
                        $Message = $LocalizedData.PublishersMismatch -f ($InstalledModuleInfo.Name, $InstalledModuleVersion, $CurrentModuleInfo.Name, $CurrentModuleAuthenticodePublisher, $CurrentModuleInfo.Version)
                        ThrowError -ExceptionName 'System.InvalidOperationException' `
                                -ExceptionMessage $message `
                                -ErrorId 'PublishersMismatch' `
                                -CallerPSCmdlet $PSCmdlet `
                                -ErrorCategory InvalidOperation

                        return $false
                    }

                    $Message = $LocalizedData.PublishersMismatchAsWarning -f ($InstalledModuleInfo.Name, $InstalledModuleVersion, $InstalledModuleAuthenticodePublisher, $CurrentModuleInfo.Version, $CurrentModuleAuthenticodePublisher)
                    Write-Warning $Message
                    return $true
                }
            }
            else
            {
                $Message = $LocalizedData.AuthenticodeIssuerMismatch -f ($CurrentModuleAuthenticodePublisher, $CurrentModuleInfo.Name, $CurrentModuleInfo.Version, $CurrentModuleRootCA, $InstalledModuleAuthenticodePublisher, $InstalledModuleInfo.Name, $InstalledModuleVersion, $InstalledModuleRootCA)
                ThrowError -ExceptionName 'System.InvalidOperationException' `
                            -ExceptionMessage $message `
                            -ErrorId 'AuthenticodeIssuerMismatch' `
                            -CallerPSCmdlet $PSCmdlet `
                            -ErrorCategory InvalidOperation
                return $false
            }
        }
    }

    return $true
}