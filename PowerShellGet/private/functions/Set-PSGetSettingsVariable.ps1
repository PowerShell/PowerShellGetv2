function Set-PSGetSettingsVariable
{
    [CmdletBinding()]
    param([switch]$Force)

    if(-not $script:PSGetSettings -or $Force)
    {
        if(Microsoft.PowerShell.Management\Test-Path -Path $script:PSGetSettingsFilePath)
        {
            $script:PSGetSettings = DeSerialize-PSObject -Path $script:PSGetSettingsFilePath
        }
        else
        {
            $script:PSGetSettings = [ordered]@{}
        }
    }
}