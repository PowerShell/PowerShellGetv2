function Get-PublishLocation
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [String]
        $Location
    )

    $PublishLocation = $null

    if($Location)
    {
        # For local dir or SMB-share locations, ScriptPublishLocation is PublishLocation.
        if(Microsoft.PowerShell.Management\Test-Path -Path $Location)
        {
            $PublishLocation = $Location
        }
    }

    return $PublishLocation
}