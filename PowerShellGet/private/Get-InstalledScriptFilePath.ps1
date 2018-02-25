function Get-InstalledScriptFilePath
{
    [CmdletBinding(PositionalBinding=$false)]
    Param
    (
        [Parameter()]
        [string]
        $Name
    )

    $installedScriptFilePaths = @()
    $scriptFilePaths = Get-AvailableScriptFilePath @PSBoundParameters

    foreach ($scriptFilePath in $scriptFilePaths)
    {
        $scriptInfo = Test-ScriptInstalled -Name ([System.IO.Path]::GetFileNameWithoutExtension($scriptFilePath))

        if($scriptInfo)
        {
            $installedScriptInfoFilePath = $null
            $installedScriptInfoFileName = "$($scriptInfo.Name)_$script:InstalledScriptInfoFileName"

            if($scriptInfo.Path.StartsWith($script:ProgramFilesScriptsPath, [System.StringComparison]::OrdinalIgnoreCase))
            {
                $installedScriptInfoFilePath = Microsoft.PowerShell.Management\Join-Path -Path $script:ProgramFilesInstalledScriptInfosPath `
                                                                                         -ChildPath $installedScriptInfoFileName
            }
            elseif($scriptInfo.Path.StartsWith($script:MyDocumentsScriptsPath, [System.StringComparison]::OrdinalIgnoreCase))
            {
                $installedScriptInfoFilePath = Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsInstalledScriptInfosPath `
                                                                                         -ChildPath $installedScriptInfoFileName
            }

            if($installedScriptInfoFilePath -and (Microsoft.PowerShell.Management\Test-Path -Path $installedScriptInfoFilePath -PathType Leaf))
            {
                $installedScriptFilePaths += $scriptInfo.Path
            }
        }
    }

    return $installedScriptFilePaths
}