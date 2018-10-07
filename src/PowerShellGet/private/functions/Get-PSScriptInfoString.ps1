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

.VERSION$(if ($Version) {" $Version"})

.GUID$(if ($Guid) {" $Guid"})

.AUTHOR$(if ($Author) {" $Author"})

.COMPANYNAME$(if ($CompanyName) {" $CompanyName"})

.COPYRIGHT$(if ($Copyright) {" $Copyright"})

.TAGS$(if ($Tags) {" $Tags"})

.LICENSEURI$(if ($LicenseUri) {" $LicenseUri"})

.PROJECTURI$(if ($ProjectUri) {" $ProjectUri"})

.ICONURI$(if ($IconUri) {" $IconUri"})

.EXTERNALMODULEDEPENDENCIES$(if ($ExternalModuleDependencies) {" $($ExternalModuleDependencies -join ',')"}) 

.REQUIREDSCRIPTS$(if ($RequiredScripts) {" $($RequiredScripts -join ',')"})

.EXTERNALSCRIPTDEPENDENCIES$(if ($ExternalScriptDependencies) {" $($ExternalScriptDependencies -join ',')"})

.RELEASENOTES
$($ReleaseNotes -join "`r`n")

.PRIVATEDATA$(if ($PrivateData) {" $PrivateData"})

#>
"@
        return $PSScriptInfoString
    }
}
