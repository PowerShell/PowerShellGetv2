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
        return $AuthenticodeSignature.SignerCertificate.Subject
    }
}