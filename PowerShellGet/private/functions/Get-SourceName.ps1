function Get-SourceName
{
    [CmdletBinding()]
    [OutputType("string")]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Location
    )

    Set-ModuleSourcesVariable

    foreach($psModuleSource in $script:PSGetModuleSources.Values)
    {
        if(($psModuleSource.Name -eq $Location) -or
           ($psModuleSource.SourceLocation -eq $Location) -or
           ((Get-Member -InputObject $psModuleSource -Name $script:ScriptSourceLocation) -and
           ($psModuleSource.ScriptSourceLocation -eq $Location)))
        {
            return $psModuleSource.Name
        }
    }
}