function Validate-VersionParameters
{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet,

        [Parameter()]
        [String[]]
        $Name,

        [Parameter()]
        [string]
        $MinimumVersion,

        [Parameter()]
        [string]
        $RequiredVersion,

        [Parameter()]
        [string]
        $MaximumVersion,

        [Parameter()]
        [Switch]
        $AllVersions,

        [Parameter()]
        [Switch]
        $AllowPrerelease,

        [Parameter()]
        [Switch]
        $TestWildcardsInName
    )

    if ($MinimumVersion)
    {
        $minResult = ValidateAndGet-VersionPrereleaseStrings -Version $MinimumVersion -CallerPSCmdlet $PSCmdlet
        if (-not $minResult)
        {
            # ValidateAndGet-VersionPrereleaseStrings throws the error.
            # returning to avoid further execution when different values are specified for -ErrorAction parameter
            return
        }

        $minimumVersionVer = $minResult["Version"]
        $minimumVersionPrerelease = $minResult["Prerelease"]
    }
    if ($MaximumVersion)
    {
        $maxResult = ValidateAndGet-VersionPrereleaseStrings -Version $MaximumVersion -CallerPSCmdlet $PSCmdlet
        if (-not $maxResult)
        {
            # ValidateAndGet-VersionPrereleaseStrings throws the error.
            # returning to avoid further execution when different values are specified for -ErrorAction parameter
            return
        }

        $maximumVersionVer = $maxResult["Version"]
        $maximumVersionPrerelease = $maxResult["Prerelease"]
    }
    if ($RequiredVersion)
    {
        $reqResult = ValidateAndGet-VersionPrereleaseStrings -Version $RequiredVersion -CallerPSCmdlet $PSCmdlet
        if (-not $reqResult)
        {
            # ValidateAndGet-VersionPrereleaseStrings throws the error.
            # returning to avoid further execution when different values are specified for -ErrorAction parameter
            return
        }
    }

    if($TestWildcardsInName -and $Name -and (Test-WildcardPattern -Name "$Name"))
    {
        ThrowError -ExceptionName "System.ArgumentException" `
                   -ExceptionMessage ($LocalizedData.NameShouldNotContainWildcardCharacters -f "$($Name -join ',')") `
                   -ErrorId 'NameShouldNotContainWildcardCharacters' `
                   -CallerPSCmdlet $CallerPSCmdlet `
                   -ErrorCategory InvalidArgument `
                   -ExceptionObject $Name
    }
    elseif($AllVersions -and ($RequiredVersion -or $MinimumVersion -or $MaximumVersion))
    {
        ThrowError -ExceptionName "System.ArgumentException" `
                   -ExceptionMessage $LocalizedData.AllVersionsCannotBeUsedWithOtherVersionParameters `
                   -ErrorId 'AllVersionsCannotBeUsedWithOtherVersionParameters' `
                   -CallerPSCmdlet $CallerPSCmdlet `
                   -ErrorCategory InvalidArgument
    }
    elseif($RequiredVersion -and ($MinimumVersion -or $MaximumVersion))
    {
        ThrowError -ExceptionName "System.ArgumentException" `
                   -ExceptionMessage $LocalizedData.VersionRangeAndRequiredVersionCannotBeSpecifiedTogether `
                   -ErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether" `
                   -CallerPSCmdlet $CallerPSCmdlet `
                   -ErrorCategory InvalidArgument
    }
    elseif($MinimumVersion -and $MaximumVersion -and (Compare-PrereleaseVersions -FirstItemVersion $maximumVersionVer `
                                                                                 -FirstItemPrerelease $maximumVersionPrerelease `
                                                                                 -SecondItemVersion $minimumVersionVer `
                                                                                 -SecondItemPrerelease $minimumVersionPrerelease))
    {
        $Message = $LocalizedData.MinimumVersionIsGreaterThanMaximumVersion -f ($MinimumVersion, $MaximumVersion)
        ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $Message `
                    -ErrorId "MinimumVersionIsGreaterThanMaximumVersion" `
                    -CallerPSCmdlet $CallerPSCmdlet `
                    -ErrorCategory InvalidArgument
    }
    elseif( (($MinimumVersion -match '-') -or ($MaximumVersion -match '-') -or ($RequiredVersion -match '-')) -and -not $AllowPrerelease)
    {
        ThrowError -ExceptionName "System.ArgumentException" `
                   -ExceptionMessage $LocalizedData.AllowPrereleaseRequiredToUsePrereleaseStringInVersion `
                   -ErrorId "AllowPrereleaseRequiredToUsePrereleaseStringInVersion" `
                   -CallerPSCmdlet $CallerPSCmdlet `
                   -ErrorCategory InvalidArgument
    }
    elseif($AllVersions -or $AllowPrerelease -or $RequiredVersion -or $MinimumVersion -or $MaximumVersion)
    {
        if(-not $Name -or $Name.Count -ne 1 -or (Test-WildcardPattern -Name $Name[0]))
        {
            ThrowError -ExceptionName "System.ArgumentException" `
                       -ExceptionMessage $LocalizedData.VersionParametersAreAllowedOnlyWithSingleName `
                       -ErrorId "VersionParametersAreAllowedOnlyWithSingleName" `
                       -CallerPSCmdlet $CallerPSCmdlet `
                       -ErrorCategory InvalidArgument
        }
    }

    return $true
}