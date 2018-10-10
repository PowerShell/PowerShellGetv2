function Test-ItemPrereleaseVersionRequirements
# Returns true if it meets the Required, Minimum, and Maximum version bounds.
{
    [CmdletBinding()]
    param(

        [ValidateNotNullOrEmpty()]
        [string]
        $Version,

        [string]
        $RequiredVersion,

        [string]
        $MinimumVersion,

        [string]
        $MaximumVersion
    )

    $result = ValidateAndGet-VersionPrereleaseStrings -Version $Version -CallerPSCmdlet $PSCmdlet
    if (-not $result)
    {
        # ValidateAndGet-VersionPrereleaseStrings throws the error.
        # returning to avoid further execution when different values are specified for -ErrorAction parameter
        return
    }
    $psgetitemVersion = $result["Version"]
    $psgetitemPrerelease = $result["Prerelease"]
    $psgetitemFullVersion = $result["FullVersion"]

    if($RequiredVersion)
    {
        $reqResult = ValidateAndGet-VersionPrereleaseStrings -Version $RequiredVersion -CallerPSCmdlet $PSCmdlet
        if (-not $reqResult)
        {
            # ValidateAndGet-VersionPrereleaseStrings throws the error.
            # returning to avoid further execution when different values are specified for -ErrorAction parameter
            return
        }
        $reqFullVersion = $reqResult["FullVersion"]

        return ($reqFullVersion -eq $psgetitemFullVersion)
    }
    else
    {
        $minimumBoundMet = $false
        if ($MinimumVersion)
        {
            $minResult = ValidateAndGet-VersionPrereleaseStrings -Version $MinimumVersion -CallerPSCmdlet $PSCmdlet
            if (-not $minResult)
            {
                # ValidateAndGet-VersionPrereleaseStrings throws the error.
                # returning to avoid further execution when different values are specified for -ErrorAction parameter
                return
            }
            $minVersion = $minResult["Version"]
            $minPrerelease = $minResult["Prerelease"]

            # minimum bound is met if PSGet item version is greater than or equal to minimum version
            if (-not (Compare-PrereleaseVersions -FirstItemVersion $psgetitemVersion `
                                                 -FirstItemPrerelease $psgetitemPrerelease `
                                                 -SecondItemVersion $minVersion `
                                                 -SecondItemPrerelease $minPrerelease ))
            {
                $minimumBoundMet = $true
            }
        }
        else
        {
            $minimumBoundMet = $true
        }

        $maximumBoundMet = $false
        if ($MaximumVersion)
        {
            $maxResult = ValidateAndGet-VersionPrereleaseStrings -Version $MaximumVersion -CallerPSCmdlet $PSCmdlet
            if (-not $maxResult)
            {
                # ValidateAndGet-VersionPrereleaseStrings throws the error.
                # returning to avoid further execution when different values are specified for -ErrorAction parameter
                return
            }
            $maxVersion = $maxResult["Version"]
            $maxPrerelease = $maxResult["Prerelease"]

            # maximum bound is met if PSGet item version is less than or equal to maximum version
            if (-not (Compare-PrereleaseVersions -FirstItemVersion $maxVersion `
                                                 -FirstItemPrerelease $maxPrerelease `
                                                 -SecondItemVersion $psgetitemVersion `
                                                 -SecondItemPrerelease $psgetitemPrerelease ))
            {
                $maximumBoundMet = $true
            }
        }
        else
        {
            $maximumBoundMet = $true
        }

        return ($minimumBoundMet -and $maximumBoundMet)
    }
}