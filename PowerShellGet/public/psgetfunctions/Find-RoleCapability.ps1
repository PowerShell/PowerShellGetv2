function Find-RoleCapability
{
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(HelpUri = 'https://go.microsoft.com/fwlink/?LinkId=718029')]
    [outputtype('PSCustomObject[]')]
    Param
    (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleName,

        [Parameter()]
        [ValidateNotNull()]
        [string]
        $MinimumVersion,

        [Parameter()]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        [Parameter()]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        [Parameter()]
        [switch]
        $AllVersions,

        [Parameter()]
        [switch]
        $AllowPrerelease,

        [Parameter()]
        [ValidateNotNull()]
        [string[]]
        $Tag,

        [Parameter()]
        [ValidateNotNull()]
        [string]
        $Filter,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [PSCredential]
        $ProxyCredential,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Repository
    )


    Process
    {
        $PSBoundParameters['Includes'] = 'RoleCapability'

        if($PSBoundParameters.ContainsKey('Name'))
        {
            $PSBoundParameters['RoleCapability'] = $Name
            $null = $PSBoundParameters.Remove('Name')
        }

        if($PSBoundParameters.ContainsKey('ModuleName'))
        {
            $PSBoundParameters['Name'] = $ModuleName
            $null = $PSBoundParameters.Remove('ModuleName')
        }

        PowerShellGet\Find-Module @PSBoundParameters |
            Microsoft.PowerShell.Core\ForEach-Object {
                $psgetModuleInfo = $_
                $psgetModuleInfo.Includes.RoleCapability | Microsoft.PowerShell.Core\ForEach-Object {
                    if($Name -and ($Name -notcontains $_))
                    {
                        return
                    }

                    $psgetRoleCapabilityInfo = Microsoft.PowerShell.Utility\New-Object PSCustomObject -Property ([ordered]@{
                            Name            = $_
                            Version         = $psgetModuleInfo.Version
                            ModuleName      = $psgetModuleInfo.Name
                            Repository      = $psgetModuleInfo.Repository
                            PSGetModuleInfo = $psgetModuleInfo
                    })

                    $psgetRoleCapabilityInfo.PSTypeNames.Insert(0, 'Microsoft.PowerShell.Commands.PSGetRoleCapabilityInfo')
                    $psgetRoleCapabilityInfo
                }
            }
    }
}