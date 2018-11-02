function Resolve-Location
{
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $Location,

        [Parameter()]
        $Credential,

        [Parameter()]
        $Proxy,

        [Parameter()]
        $ProxyCredential,

        [Parameter()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet,

        [Parameter()]
        [switch]
        $SkipLocationWarning
    )

    # Ping and resolve the specified location
    if(-not (Test-WebUri -uri $Location))
    {
        if(Microsoft.PowerShell.Management\Test-Path -Path $Location)
        {
            return $Location
        }
        elseif($CallerPSCmdlet)
        {
            $message = $LocalizedData.PathNotFound -f ($Location)
            ThrowError -ExceptionName "System.ArgumentException" `
                       -ExceptionMessage $message `
                       -ErrorId "PathNotFound" `
                       -CallerPSCmdlet $CallerPSCmdlet `
                       -ErrorCategory InvalidArgument `
                       -ExceptionObject $Location
        }
    }
    else
    {
        $pingResult = Ping-Endpoint -Endpoint $Location -Credential $Credential -Proxy $Proxy -ProxyCredential $ProxyCredential
        $statusCode = $null
        $exception = $null
        $resolvedLocation = $null
        if($pingResult -and $pingResult.ContainsKey($Script:ResponseUri))
        {
            $resolvedLocation = $pingResult[$Script:ResponseUri]
        }

        if($pingResult -and $pingResult.ContainsKey($Script:StatusCode))
        {
            $statusCode = $pingResult[$Script:StatusCode]
        }

        Write-Debug -Message "Ping-Endpoint: location=$Location, statuscode=$statusCode, resolvedLocation=$resolvedLocation"

        if((($statusCode -eq 200) -or ($statusCode -eq 401)) -and $resolvedLocation)
        {
            return $resolvedLocation
        }
        else
        {
            # We couldn't reach the repo. Register it anyway but warn the user if we're able
            # We'd like to include the parameter name here, but Register-PSRepository calls Add-PackageSource, 
            # and both use different param names, so the parameter name becomes confusing
            if($CallerPSCmdlet -and -not $SkipLocationWarning) {
                $message = $LocalizedData.WarnUnableToReachWebUri -f ($Location)
                Write-Warning $message
            }
            return $Location
        }
    }
}