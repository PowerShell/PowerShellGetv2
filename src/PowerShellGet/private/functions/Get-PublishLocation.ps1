function Get-PublishLocation
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [String]
        $Location
    )

    # For local dir or SMB-share locations, ScriptPublishLocation is PublishLocation.
    if($Location -and (Microsoft.PowerShell.Management\Test-Path -Path $Location))
    {
        return $Location
    }
}