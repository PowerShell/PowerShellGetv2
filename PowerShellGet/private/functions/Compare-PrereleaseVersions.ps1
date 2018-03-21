function Compare-PrereleaseVersions
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $FirstItemVersion,

        [string]
        $FirstItemPrerelease,

        [ValidateNotNullOrEmpty()]
        [string]
        $SecondItemVersion,

        [string]
        $SecondItemPrerelease
    )

    <#
        This function compares one item to another to determine if it has a greater version (and/or prerelease).
        It returns true if item TWO is GREATER/newer than item ONE, it returns false otherwise.


        First Order:  Compare Versions
        ===========
        *** Version is never NULL.

        Item #1         Comparison      Item #2
        Version         of Values       Version         Notes about item #2
        -------         ----------      -------         -------------------
        Value           >               Value           An older release version
        Value           <               Value         * A newer release version
        Value           ==              Value           Inconclusive, must compare prerelease strings now



        Second Order:  Compare Prereleases
        =============
        *** Prerelease may be NULL, indicates a release version.

        Item #1         Comparison      Item #2
        Prerelease      of Values       Prerelease      Notes about item #2
        ----------      -----------     ----------      -------------------
        NULL                ==          NULL            Exact same release version
        NULL                >           Value           Older (prerelease) version
        Value               <           NULL          * A newer, release version
        Value               ==          Value           Exact same prerelease (and same version)
        Value               >           Value           An older prerelease
        Value               <           Value         * A newer prerelease


        Item #2 is newer/greater than item #1 in the starred (*) combinations.
        Those are the conditions tested for below.
    #>

    [version]$itemOneVersion = $null
    # try parsing version string
    if (-not ( [System.Version]::TryParse($FirstItemVersion.Trim(), [ref]$itemOneVersion) ))
    {
        $message = $LocalizedData.InvalidVersion -f ($FirstItemVersion)
        Write-Error -Message $message -ErrorId "InvalidVersion" -Category InvalidArgument
        return
    }

    [Version]$itemTwoVersion = $null
    # try parsing version string
    if (-not ( [System.Version]::TryParse($SecondItemVersion.Trim(), [ref]$itemTwoVersion) ))
    {
        $message = $LocalizedData.InvalidVersion -f ($SecondItemVersion)
        Write-Error -Message $message -ErrorId "InvalidVersion" -Category InvalidArgument
        return
    }

    return (($itemOneVersion -lt $itemTwoVersion) -or `
            (($itemOneVersion -eq $itemTwoVersion) -and `
             (($FirstItemPrerelease -and -not $SecondItemPrerelease) -or `
              ($FirstItemPrerelease -lt $SecondItemPrerelease))))
}