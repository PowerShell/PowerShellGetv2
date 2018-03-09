function Test-ScriptInstalled
{
    [CmdletBinding(PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $RequiredVersion
    )

    $scriptInfo = $null
    $scriptFileName = "$Name.ps1"
    $scriptPaths = @($script:ProgramFilesScriptsPath, $script:MyDocumentsScriptsPath)
    $scriptInfos = @()

    if ($RequiredVersion)
    {
        $reqResult = ValidateAndGet-VersionPrereleaseStrings -Version $RequiredVersion -CallerPSCmdlet $PSCmdlet
        if (-not $reqResult)
        {
            return
        }
        $reqFullVersion = $reqResult["FullVersion"]
    }


    foreach ($location in $scriptPaths)
    {
        $scriptFilePath = Microsoft.PowerShell.Management\Join-Path -Path $location -ChildPath $scriptFileName

        if(Microsoft.PowerShell.Management\Test-Path -Path $scriptFilePath -PathType Leaf)
        {
            $scriptInfo = $null
            try
            {
                $scriptInfo = Test-ScriptFileInfo -Path $scriptFilePath -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }
            catch
            {
                # Ignore any terminating error from the Test-ScriptFileInfo cmdlet,
                # if it does not contain valid Script metadata
                Write-Verbose -Message "$_"
            }

            if($scriptInfo)
            {
                $scriptInfos += $scriptInfo
            }
            else
            {
                # Since the script file doesn't contain the valid script metadata,
                # create dummy PSScriptInfo object with 0.0 version
                $scriptInfo = New-PSScriptInfoObject -Path $scriptFilePath
                $scriptInfo.$script:Version = [Version]'0.0'

                $scriptInfos += $scriptInfo
            }
        }
    }

    $scriptInfo = $scriptInfos | Microsoft.PowerShell.Core\Where-Object {
                                                                $thisResult = ValidateAndGet-VersionPrereleaseStrings -Version $_.Version -CallerPSCmdlet $PSCmdlet
                                                                if (-not $thisResult)
                                                                {
                                                                    return
                                                                }
                                                                $thisFullVersion = $thisResult["FullVersion"]
                                                                (-not $RequiredVersion) -or ($reqFullVersion -eq $thisFullVersion)
                                                            } | Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

    return $scriptInfo
}