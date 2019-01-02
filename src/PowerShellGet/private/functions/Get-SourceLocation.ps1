function Get-SourceLocation
{
    [CmdletBinding()]
    [OutputType("string")]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourceName
    )

    Set-ModuleSourcesVariable

    if($script:PSGetModuleSources.Contains($SourceName))
    {
        return $script:PSGetModuleSources[$SourceName].SourceLocation
    }
    else
    {
        return $SourceName
    }
}