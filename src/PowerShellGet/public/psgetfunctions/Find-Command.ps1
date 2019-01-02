function Find-Command
{
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(HelpUri = 'https://go.microsoft.com/fwlink/?LinkId=733636')]
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
        if($PSBoundParameters.ContainsKey('Name'))
        {
            $PSBoundParameters['Command'] = $Name
            $null = $PSBoundParameters.Remove('Name')
        }
        else
        {
            $PSBoundParameters['Includes'] = @('Cmdlet','Function')
        }

        if($PSBoundParameters.ContainsKey('ModuleName'))
        {
            $PSBoundParameters['Name'] = $ModuleName
            $null = $PSBoundParameters.Remove('ModuleName')
        }


        PowerShellGet\Find-Module @PSBoundParameters |
            Microsoft.PowerShell.Core\ForEach-Object {
                $psgetModuleInfo = $_
                $psgetModuleInfo.Includes.Command | Microsoft.PowerShell.Core\ForEach-Object {
                    if(($_ -eq "*") -or ($Name -and ($Name -notcontains $_)))
                    {
                        return
                    }

                    $psgetCommandInfo = Microsoft.PowerShell.Utility\New-Object PSCustomObject -Property ([ordered]@{
                            Name            = $_
                            Version         = $psgetModuleInfo.Version
                            ModuleName      = $psgetModuleInfo.Name
                            Repository      = $psgetModuleInfo.Repository
                            PSGetModuleInfo = $psgetModuleInfo
                    })

                    $psgetCommandInfo.PSTypeNames.Insert(0, 'Microsoft.PowerShell.Commands.PSGetCommandInfo')
                    $psgetCommandInfo
                }
            }
    }
}