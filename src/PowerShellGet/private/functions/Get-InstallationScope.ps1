
# Determine scope. We prefer CurrentUser scope even if the older module is installed for AllUsers, unless:
# old module is installed for all users, we are elevated, AND using Windows PowerShell
# This is to mirror newer behavior of Install-Module.
function Get-InstallationScope()
{
    [CmdletBinding()]
    param(
        [string]$PreviousInstallLocation
    )

    if ( -not $PreviousInstallLocation.ToString().StartsWith($script:MyDocumentsModulesPath, [System.StringComparison]::OrdinalIgnoreCase) -and
         -not $script:IsCoreCLR -and
         (Test-RunningAsElevated)) {
        $Scope = "AllUsers"
    }
    else {
        $Scope = "CurrentUser"
    }

    Write-Debug "Get-InstallationScope: $PreviousInstallLocation $($script:IsCoreCLR) $(Test-RunningAsElevated) : $Scope"
    return $Scope
}
