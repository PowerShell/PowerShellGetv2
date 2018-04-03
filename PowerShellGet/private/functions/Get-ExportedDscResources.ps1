function Get-ExportedDscResources
{
    [CmdletBinding(PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSModuleInfo]
        $PSModuleInfo
    )

    $dscResources = @()

    if(-not $script:IsCoreCLR -and (Get-Command -Name Get-DscResource -Module PSDesiredStateConfiguration -ErrorAction Ignore))
    {
        $OldPSModulePath = $env:PSModulePath

        try
        {
            $env:PSModulePath = Join-Path -Path $PSHOME -ChildPath "Modules"
            $env:PSModulePath = "$env:PSModulePath;$(Split-Path -Path $PSModuleInfo.ModuleBase -Parent)"

            $dscResources = PSDesiredStateConfiguration\Get-DscResource -ErrorAction SilentlyContinue -WarningAction SilentlyContinue |
                                Microsoft.PowerShell.Core\ForEach-Object {
                                    if($_.Module -and ($_.Module.Name -eq $PSModuleInfo.Name))
                                    {
                                        $_.Name
                                    }
                                }
        }
        finally
        {
            $env:PSModulePath = $OldPSModulePath
        }
    }
    else
    {
        $dscResourcesDir = Join-PathUtility -Path $PSModuleInfo.ModuleBase -ChildPath "DscResources" -PathType Directory
        if(Microsoft.PowerShell.Management\Test-Path $dscResourcesDir)
        {
            $dscResources = Microsoft.PowerShell.Management\Get-ChildItem -Path $dscResourcesDir -Directory -Name
        }
    }

    return $dscResources
}