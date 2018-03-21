function New-PSScriptInfoObject
{
    [CmdletBinding(PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )

    $PSScriptInfo = Microsoft.PowerShell.Utility\New-Object PSCustomObject -Property ([ordered]@{})
    $script:PSScriptInfoProperties | Microsoft.PowerShell.Core\ForEach-Object {
                                            Microsoft.PowerShell.Utility\Add-Member -InputObject $PSScriptInfo `
                                                                                    -MemberType NoteProperty `
                                                                                    -Name $_ `
                                                                                    -Value $null
                                        }

    $PSScriptInfo.$script:Name = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    $PSScriptInfo.$script:Path = $Path
    $PSScriptInfo.$script:ScriptBase = (Microsoft.PowerShell.Management\Split-Path -Path $Path -Parent)

    return $PSScriptInfo
}