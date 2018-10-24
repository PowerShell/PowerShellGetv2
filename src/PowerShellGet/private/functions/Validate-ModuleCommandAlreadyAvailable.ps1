function Validate-ModuleCommandAlreadyAvailable
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [PSModuleInfo]
        $CurrentModuleInfo,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InstallLocation,

        [Parameter()]
        [Switch]
        $AllowClobber,

        [Parameter()]
        [Switch]
        $IsUpdateOperation
    )

    <#
        Install-Module must generate an error message when there is a conflict.
        User can specify -AllowClobber to avoid the message.
        Scenario: A large module could be separated into 2 smaller modules.
        Reason 1: the consumer might have to change code (aka: import-module) to use the command from the new module.
        Reason 2: it is too confusing to troubleshoot this problem if the user isn't informed right away.
    #>
    # When new module has some commands, no clobber error if
    # - AllowClobber is specified, or
    # - Installing to the same module base, or
    # - Update operation
    if($CurrentModuleInfo.ExportedCommands.Keys.Count -and
       -not $AllowClobber -and
       -not $IsUpdateOperation)
    {
        # Remove the version folder on 5.0 to get the actual module base folder without version
        if(Test-ModuleSxSVersionSupport)
        {
            $InstallLocation = Microsoft.PowerShell.Management\Split-Path -Path $InstallLocation
        }

        $InstalledModuleInfo = Test-ModuleInstalled -Name $CurrentModuleInfo.Name
        if(-not $InstalledModuleInfo -or -not $InstalledModuleInfo.ModuleBase.StartsWith($InstallLocation, [System.StringComparison]::OrdinalIgnoreCase))
        {
            # Throw an error if there is a command with the same name from a different source.
            # Get-Command loads the module if a command is already available.
            # To avoid that, appending '*' at the end for each name then comparing the results.
            $CommandNames = $CurrentModuleInfo.ExportedCommands.Values.Name

            # construct a regex matching any of the commands in this module.
            $Matcher = [regex](($CommandNames | % { "($_)" }) -join "|")
            
            $AvailableCommands = Microsoft.PowerShell.Core\Get-Command -Name *  `
                                                                      -ErrorAction Ignore `
                                                                      -WarningAction SilentlyContinue |
                                    Microsoft.PowerShell.Core\Where-Object { ($Matcher.IsMatch($_.Name)) -and
                                                                             ($_.ModuleName -ne $script:PSModuleProviderName) -and
                                                                             ($_.ModuleName -ne 'PSModule') -and
                                                                             ($_.ModuleName -ne $CurrentModuleInfo.Name) }
            if($AvailableCommands)
            {
                $AvailableCommandsList = ($AvailableCommands.Name | Microsoft.PowerShell.Utility\Select-Object -Unique -ErrorAction Ignore) -join ","
                $message = $LocalizedData.ModuleCommandAlreadyAvailable -f ($AvailableCommandsList, $CurrentModuleInfo.Name)
                ThrowError -ExceptionName 'System.InvalidOperationException' `
                           -ExceptionMessage $message `
                           -ErrorId 'CommandAlreadyAvailable' `
                           -CallerPSCmdlet $PSCmdlet `
                           -ErrorCategory InvalidOperation

                return $false
            }
        }
    }

    return $true
}