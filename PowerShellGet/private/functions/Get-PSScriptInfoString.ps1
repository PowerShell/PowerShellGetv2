function Get-PSScriptInfoString
{
    [CmdletBinding(PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Version,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Guid]
        $Guid,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Author,

        [Parameter()]
        [String]
        $CompanyName,

        [Parameter()]
        [string]
        $Copyright,

        [Parameter()]
        [String[]]
        $ExternalModuleDependencies,

        [Parameter()]
        [string[]]
        $RequiredScripts,

        [Parameter()]
        [String[]]
        $ExternalScriptDependencies,

        [Parameter()]
        [string[]]
        $Tags,

        [Parameter()]
        [Uri]
        $ProjectUri,

        [Parameter()]
        [Uri]
        $LicenseUri,

        [Parameter()]
        [Uri]
        $IconUri,

        [Parameter()]
        [string[]]
        $ReleaseNotes,

		[Parameter()]
        [string]
        $PrivateData
    )

    Process
    {
        $PSScriptInfoString = @"

<#PSScriptInfo

.VERSION $Version

.GUID $Guid

.AUTHOR $Author

.COMPANYNAME $CompanyName

.COPYRIGHT $Copyright

.TAGS $Tags

.LICENSEURI $LicenseUri

.PROJECTURI $ProjectUri

.ICONURI $IconUri

.EXTERNALMODULEDEPENDENCIES $($ExternalModuleDependencies -join ',')

.REQUIREDSCRIPTS $($RequiredScripts -join ',')

.EXTERNALSCRIPTDEPENDENCIES $($ExternalScriptDependencies -join ',')

.RELEASENOTES
$($ReleaseNotes -join "`r`n")

.PRIVATEDATA $PrivateData

#>
"@
        return $PSScriptInfoString
    }
}