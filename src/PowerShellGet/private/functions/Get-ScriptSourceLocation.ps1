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
        else
        {
            $tempScriptLocation = $null

            if($Location.EndsWith('/api/v2', [System.StringComparison]::OrdinalIgnoreCase))
            {
                $tempScriptLocation = $Location + '/items/psscript/'
            }
            elseif($Location.EndsWith('/api/v2/', [System.StringComparison]::OrdinalIgnoreCase))
            {
                $tempScriptLocation = $Location + 'items/psscript/'
            }

            if($tempScriptLocation)
            {
                # Ping and resolve the specified location
                $scriptLocation = Resolve-Location -Location $tempScriptLocation `
                                                   -LocationParameterName 'ScriptSourceLocation' `
                                                   -Credential $Credential `
                                                   -Proxy $Proxy `
                                                   -ProxyCredential $ProxyCredential `
                                                   -ErrorAction SilentlyContinue `
                                                   -WarningAction SilentlyContinue
            }
        }
    }
    return $scriptLocation
}