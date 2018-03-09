function Get-AvailableRoleCapabilityName
{
    [CmdletBinding(PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSModuleInfo]
        $PSModuleInfo
    )

    $RoleCapabilityNames = @()

    $RoleCapabilitiesDir = Join-PathUtility -Path $PSModuleInfo.ModuleBase -ChildPath 'RoleCapabilities' -PathType Directory
    if(Microsoft.PowerShell.Management\Test-Path -Path $RoleCapabilitiesDir -PathType Container)
    {
        $RoleCapabilityNames = Microsoft.PowerShell.Management\Get-ChildItem -Path $RoleCapabilitiesDir `
                                  -Name -Filter *.psrc |
                                      ForEach-Object {[System.IO.Path]::GetFileNameWithoutExtension($_)}
    }

    return $RoleCapabilityNames
}