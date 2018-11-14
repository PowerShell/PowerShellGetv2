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

    # For local dir or SMB-share locations, ScriptSourceLocation is SourceLocation.
    if($Location -and (Microsoft.PowerShell.Management\Test-Path -Path $Location))
    {
        return $Location
    }
}