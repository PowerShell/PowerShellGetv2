function Test-WildcardPattern
{
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        $Name
    )

    return [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Name)
}