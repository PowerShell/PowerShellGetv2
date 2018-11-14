function Get-AvailableScriptFilePath
{
    [CmdletBinding(PositionalBinding=$false)]
    Param
    (
        [Parameter()]
        [string]
        $Name
    )

    $scriptInfo = $null
    $scriptFileName = '*.ps1'
    $scriptBasePaths = @($script:ProgramFilesScriptsPath, $script:MyDocumentsScriptsPath)
    $scriptFilePaths = @()
    $wildcardPattern = $null

    if($Name)
    {
        if(Test-WildcardPattern -Name $Name)
        {
            $wildcardPattern = New-Object System.Management.Automation.WildcardPattern $Name,$script:wildcardOptions
        }
        else
        {
            $scriptFileName = "$Name.ps1"
        }

    }

    foreach ($location in $scriptBasePaths)
    {
        $scriptFiles = Get-ChildItem -Path $location `
                                     -Filter $scriptFileName `
                                     -ErrorAction SilentlyContinue `
                                     -WarningAction SilentlyContinue

        if($wildcardPattern)
        {
            $scriptFiles | Microsoft.PowerShell.Core\ForEach-Object {
                                if($wildcardPattern.IsMatch($_.BaseName))
                                {
                                    $scriptFilePaths += $_.FullName
                                }
                           }
        }
        else
        {
            $scriptFiles | Microsoft.PowerShell.Core\ForEach-Object { $scriptFilePaths += $_.FullName }
        }
    }

    return $scriptFilePaths
}