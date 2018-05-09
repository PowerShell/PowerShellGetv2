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
                                                Microsoft.PowerShell.Core\Where-Object { $_.Subject -eq $element.Subject } | 
                                                Select-Object -First 1 -ErrorAction ignore
                if($rootCertificateAuthority -and $rootCertificateAuthority.Subject)
                {   
                    $publisherInfo = @{
                        publisher = $AuthenticodeSignature.SignerCertificate.Subject
                        publisherRootCA = $rootCertificateAuthority.Subject
                    } 

                    write-output $publisherInfo
                    return
                }
            }
        }
    }
}