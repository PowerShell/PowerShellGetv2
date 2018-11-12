function Get-ScriptSourceLocation
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [String]
        $Location,

        [Parameter()]
        $Credential,

        [Parameter()]
        $Proxy,

        [Parameter()]
        $ProxyCredential
    )

    $scriptLocation = $null

    if($Location)
    {
        # For local dir or SMB-share locations, ScriptSourceLocation is SourceLocation.
        if(Microsoft.PowerShell.Management\Test-Path -Path $Location)
        {
            $scriptLocation = $Location
        }
    }

    return $scriptLocation
}