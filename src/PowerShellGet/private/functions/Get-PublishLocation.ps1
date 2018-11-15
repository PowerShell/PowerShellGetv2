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
        else
        {
            $tempPublishLocation = $null

            if($Location.EndsWith('/api/v2', [System.StringComparison]::OrdinalIgnoreCase))
            {
                $tempPublishLocation = $Location + '/package/'
            }
            elseif($Location.EndsWith('/api/v2/', [System.StringComparison]::OrdinalIgnoreCase))
            {
                $tempPublishLocation = $Location + 'package/'
            }

            if($tempPublishLocation)
            {
                $PublishLocation = $tempPublishLocation
            }
        }
    }
    return $PublishLocation
}