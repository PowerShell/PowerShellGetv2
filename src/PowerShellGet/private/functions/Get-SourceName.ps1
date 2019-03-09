function Get-SourceName {
    [CmdletBinding()]
    [OutputType("string")]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Location
    )

    Set-ModuleSourcesVariable

    foreach ($psModuleSource in $script:PSGetModuleSources.Values) {
        if (($psModuleSource.Name -eq $Location) -or
            (Test-EquivalentLocation -LocationA $psModuleSource.SourceLocation -LocationB $Location) -or
            ((Get-Member -InputObject $psModuleSource -Name $script:ScriptSourceLocation) -and
                (Test-EquivalentLocation -LocationA $psModuleSource.ScriptSourceLocation -LocationB $Location))) {
            return $psModuleSource.Name
        }
    }
}
