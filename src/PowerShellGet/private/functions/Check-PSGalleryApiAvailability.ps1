function Check-PSGalleryApiAvailability
{
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $PSGalleryV2ApiUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $PSGalleryV3ApiUri
    )

    # check internet availability first
    $connected = $false
    $microsoftDomain = 'www.microsoft.com'
    if((-not $script:IsCoreCLR) -and (Get-Command Microsoft.PowerShell.Management\Test-Connection -ErrorAction Ignore))
    {
        try
        {
            $connected = Microsoft.PowerShell.Management\Test-Connection -ComputerName $microsoftDomain -Count 1 -Quiet
        } 
        catch 
        {
            # Test-Connection throws an exception even with -EA SilentlyIgnore, we must use try catch to suppress it
        } 
    }
    if(( -not $connected) -and (Get-Command NetTCPIP\Test-Connection -ErrorAction Ignore))
    {
        try 
        {
            $connected = NetTCPIP\Test-NetConnection -ComputerName $microsoftDomain -InformationLevel Quiet
        } 
        catch 
        {
            # $connected is already set to $false, this applies on all three empty catch blocks   
        } 
    }
    if ( -not $connected) 
    {
        try 
        {
            $connected = [System.Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable()
        } 
        catch 
        {
            # there is no -ErrorAction on method call, we must use empty catch block to suppress error
        } 
    }

    if ( -not $connected)
    {
        return
    }

    $statusCode_v2 = $null
    $resolvedUri_v2 = $null
    $statusCode_v3 = $null
    $resolvedUri_v3 = $null

    # ping V2
    $res_v2 = Ping-Endpoint -Endpoint $PSGalleryV2ApiUri
    if ($res_v2 -and $res_v2.ContainsKey($Script:ResponseUri))
    {
        $resolvedUri_v2 = $res_v2[$Script:ResponseUri]
    }
    if ($res_v2 -and $res_v2.ContainsKey($Script:StatusCode))
    {
        $statusCode_v2 = $res_v2[$Script:StatusCode]
    }


    # ping V3
    $res_v3 = Ping-Endpoint -Endpoint $PSGalleryV3ApiUri
    if ($res_v3 -and $res_v3.ContainsKey($Script:ResponseUri))
    {
        $resolvedUri_v3 = $res_v3[$Script:ResponseUri]
    }
    if ($res_v3 -and $res_v3.ContainsKey($Script:StatusCode))
    {
        $statusCode_v3 = $res_v3[$Script:StatusCode]
    }


    $Script:PSGalleryV2ApiAvailable = (($statusCode_v2 -eq 200) -and ($resolvedUri_v2))
    $Script:PSGalleryV3ApiAvailable = (($statusCode_v3 -eq 200) -and ($resolvedUri_v3))
    $Script:PSGalleryApiChecked = $true
}