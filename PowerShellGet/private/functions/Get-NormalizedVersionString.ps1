function Get-NormalizedVersionString
{
    <#
    .DESCRIPTION
        Latest versions of nuget.exe and dotnet command generate the .nupkg file name with
        semantic version format for the modules/scripts with two part version.
        For example: package 1.0 --> package.1.0.0.nupkg
    #>
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Version
    )

    [Version]$ParsedVersion = $null
    if ([System.Version]::TryParse($Version, [ref]$ParsedVersion)) {
        $Build = $ParsedVersion.Build
        if ($Build -eq -1) {
            $Build = 0
        }

        return "$($ParsedVersion.Major).$($ParsedVersion.Minor).$Build"
    }

    return $Version
}