function Get-OrderedPSScriptInfoObject
{
    [CmdletBinding(PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]
        $PSScriptInfo
    )

    $NewPSScriptInfo = Microsoft.PowerShell.Utility\New-Object PSCustomObject -Property ([ordered]@{
                            $script:Name = $PSScriptInfo.$script:Name
                            $script:Version = $PSScriptInfo.$script:Version
                            $script:Guid = $PSScriptInfo.$script:Guid
                            $script:Path = $PSScriptInfo.$script:Path
                            $script:ScriptBase = $PSScriptInfo.$script:ScriptBase
                            $script:Description = $PSScriptInfo.$script:Description
                            $script:Author = $PSScriptInfo.$script:Author
                            $script:CompanyName = $PSScriptInfo.$script:CompanyName
                            $script:Copyright = $PSScriptInfo.$script:Copyright
                            $script:Tags = $PSScriptInfo.$script:Tags
                            $script:ReleaseNotes = $PSScriptInfo.$script:ReleaseNotes
                            $script:RequiredModules = $PSScriptInfo.$script:RequiredModules
                            $script:ExternalModuleDependencies = $PSScriptInfo.$script:ExternalModuleDependencies
                            $script:RequiredScripts = $PSScriptInfo.$script:RequiredScripts
                            $script:ExternalScriptDependencies = $PSScriptInfo.$script:ExternalScriptDependencies
                            $script:LicenseUri = $PSScriptInfo.$script:LicenseUri
                            $script:ProjectUri = $PSScriptInfo.$script:ProjectUri
                            $script:IconUri = $PSScriptInfo.$script:IconUri
                            $script:DefinedCommands = $PSScriptInfo.$script:DefinedCommands
                            $script:DefinedFunctions = $PSScriptInfo.$script:DefinedFunctions
                            $script:DefinedWorkflows = $PSScriptInfo.$script:DefinedWorkflows
							$script:PrivateData = $PSScriptInfo.$script:PrivateData
                        })

    $NewPSScriptInfo.PSTypeNames.Insert(0, "Microsoft.PowerShell.Commands.PSScriptInfo")

    return $NewPSScriptInfo
}