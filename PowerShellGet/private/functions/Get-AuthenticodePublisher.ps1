function Get-AuthenticodePublisher
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.Signature]
        $AuthenticodeSignature
    )

    if($AuthenticodeSignature.SignerCertificate)
    {
        $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
        $null = $chain.Build($AuthenticodeSignature.SignerCertificate)

        $certStoreLocations = @('cert:\LocalMachine\Root',
                                'cert:\LocalMachine\AuthRoot',
                                'cert:\CurrentUser\Root',
                                'cert:\CurrentUser\AuthRoot')

        foreach($element in $chain.ChainElements.Certificate)
        {
            foreach($certStoreLocation in $certStoreLocations)
            {
                $rootCertificateAuthority = Microsoft.PowerShell.Management\Get-ChildItem -Path $certStoreLocation |
                                                Microsoft.PowerShell.Core\Where-Object { ($_.Subject -eq $element.Subject) -and ($_.thumbprint -eq $element.thumbprint) }
                if($rootCertificateAuthority)
                {
                    # Select-Object writes an error 'System Error' into the error stream.
                    # Using below workaround for getting the first element when there are multiple certificates with the same subject name.
                    if($rootCertificateAuthority.PSTypeNames -contains 'System.Array') {
                        $rootCertificateAuthority = $rootCertificateAuthority[0]
                    }
                    
                    $publisherInfo = @{
                        publisher = $AuthenticodeSignature.SignerCertificate.Subject
                        publisherRootCA = $rootCertificateAuthority.Subject
                    } 

                    Write-Output -InputObject $publisherInfo
                    return
                }
            }
        }
    }
}