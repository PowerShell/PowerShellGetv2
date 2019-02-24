
# Compare 2 strings, ignoring any trailing slashes or backslashes.
# This is not exactly the same as URL or path equivalence but it should work in practice
function Test-EquivalentLocation {
    [CmdletBinding()]
    [OutputType("bool")]
    param(
        [Parameter(Mandatory = $false)]
        [string]$LocationA,

        [Parameter(Mandatory = $false)]
        [string]$LocationB
    )

    $LocationA = $LocationA.TrimEnd("\/")
    $LocationB = $LocationB.TrimEnd("\/")
    return $LocationA -eq $LocationB
}
