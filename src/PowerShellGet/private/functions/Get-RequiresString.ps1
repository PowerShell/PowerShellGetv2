function Get-RequiresString
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [Object[]]
        $RequiredModules
    )

    Process
    {
        if($RequiredModules)
        {
            $RequiredModuleStrings = @()

            foreach($requiredModuleObject in $RequiredModules)
            {
                if($requiredModuleObject.GetType().ToString() -eq 'System.Collections.Hashtable')
                {
                    if(($requiredModuleObject.Keys.Count -eq 1) -and
                        (Microsoft.PowerShell.Utility\Get-Member -InputObject $requiredModuleObject -Name 'ModuleName'))
                    {
                        $RequiredModuleStrings += $requiredModuleObject['ModuleName'].ToString()
                    }
                    else
                    {
                        $moduleSpec = New-Object Microsoft.PowerShell.Commands.ModuleSpecification -ArgumentList $requiredModuleObject
                        if (-not (Microsoft.PowerShell.Utility\Get-Variable -Name moduleSpec -ErrorAction SilentlyContinue))
                        {
                            return
                        }

                        $keyvalueStrings = $requiredModuleObject.Keys | Microsoft.PowerShell.Core\ForEach-Object {"$_ = '$( $requiredModuleObject[$_])'"}
                        $RequiredModuleStrings += "@{$($keyvalueStrings -join '; ')}"
                    }
                }
                elseif(($PSVersionTable.PSVersion -eq '3.0.0') -and
                       ($requiredModuleObject.GetType().ToString() -eq 'Microsoft.PowerShell.Commands.ModuleSpecification'))
                {
                    # ModuleSpecification.ToString() is not implemented on PowerShell 3.0.

                    $optionalString = " "

                    if($requiredModuleObject.Version)
                    {
                        $optionalString += "ModuleVersion = '$($requiredModuleObject.Version.ToString())'; "
                    }

                    if($requiredModuleObject.Guid)
                    {
                        $optionalString += "Guid = '$($requiredModuleObject.Guid.ToString())'; "
                    }

                    if($optionalString.Trim())
                    {
                        $moduleSpecString = "@{ ModuleName = '$($requiredModuleObject.Name.ToString())';$optionalString}"
                    }
                    else
                    {
                        $moduleSpecString = $requiredModuleObject.Name.ToString()
                    }

                    $RequiredModuleStrings += $moduleSpecString
                }
                else
                {
                    $RequiredModuleStrings += $requiredModuleObject.ToString()
                }
            }

            $hashRequiresStrings = $RequiredModuleStrings |
                                       Microsoft.PowerShell.Core\ForEach-Object { "#Requires -Module $_" }

            return $hashRequiresStrings
        }
        else
        {
            return ""
        }
    }
}