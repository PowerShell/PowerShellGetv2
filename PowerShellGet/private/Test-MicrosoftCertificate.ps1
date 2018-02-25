function Test-MicrosoftCertificate
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.Signature]
        $AuthenticodeSignature
    )

    $IsMicrosoftCertificate = $false

    if($AuthenticodeSignature.SignerCertificate -and
       ('Microsoft.PowerShell.Commands.PowerShellGet.Win32Helpers' -as [Type]))
    {
        $X509Chain = $null
        $SafeX509ChainHandle = $null

        try
        {
            $X509Chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
            $null = $X509Chain.Build($AuthenticodeSignature.SignerCertificate)

            if($script:IsSafeX509ChainHandleAvailable)
            {
                $SafeX509ChainHandle = [Microsoft.PowerShell.Commands.PowerShellGet.Win32Helpers]::CertDuplicateCertificateChain($X509Chain.SafeHandle)
            }
            else
            {
                $SafeX509ChainHandle = [Microsoft.PowerShell.Commands.PowerShellGet.Win32Helpers]::CertDuplicateCertificateChain($X509Chain.ChainContext)
            }

            $IsMicrosoftCertificate = [Microsoft.PowerShell.Commands.PowerShellGet.Win32Helpers]::IsMicrosoftCertificate($SafeX509ChainHandle)
        }
        catch
        {
            Write-Debug "Exception in Test-MicrosoftCertificate function:  $_"
        }
        finally
        {
            if($SafeX509ChainHandle) { $SafeX509ChainHandle.Dispose() }

            # On .NET Framework 4.5.2 and earlier versions,
            # the X509Chain class does not implement the IDisposable interface and
            # therefore does not have a Dispose method.
            if($X509Chain -and (Get-Member -InputObject $X509Chain -Name Dispose -ErrorAction SilentlyContinue)) { $X509Chain.Dispose() }
        }
    }

    return $IsMicrosoftCertificate
}