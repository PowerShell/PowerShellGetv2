function Set-InstalledScriptsVariable
{
    # Initialize list of scripts installed by the PowerShellGet provider
    $script:PSGetInstalledScripts = [ordered]@{}
    $scriptPaths = @($script:ProgramFilesInstalledScriptInfosPath, $script:MyDocumentsInstalledScriptInfosPath)

    foreach ($location in $scriptPaths)
    {
        # find all scripts installed using PowerShellGet
        $scriptInfoFiles = Get-ChildItem -Path $location `
                                         -Filter "*$script:InstalledScriptInfoFileName" `
                                         -ErrorAction SilentlyContinue `
                                         -WarningAction SilentlyContinue

        if($scriptInfoFiles)
        {
            foreach ($scriptInfoFile in $scriptInfoFiles)
            {
                $psgetItemInfo = DeSerialize-PSObject -Path $scriptInfoFile.FullName

                $scriptFilePath = Microsoft.PowerShell.Management\Join-Path -Path $psgetItemInfo.InstalledLocation `
                                                                            -ChildPath "$($psgetItemInfo.Name).ps1"

                # Remove the InstalledScriptInfo.xml file if the actual script file was manually uninstalled by the user
                if(-not (Microsoft.PowerShell.Management\Test-Path -Path $scriptFilePath -PathType Leaf))
                {
                    Microsoft.PowerShell.Management\Remove-Item -Path $scriptInfoFile.FullName -Force -ErrorAction SilentlyContinue

                    continue
                }

                $package = New-SoftwareIdentityFromPSGetItemInfo -PSGetItemInfo $psgetItemInfo

                if($package)
                {
                    $script:PSGetInstalledScripts["$($psgetItemInfo.Name)$($psgetItemInfo.Version)"] = @{
                                                                                                            SoftwareIdentity = $package
                                                                                                            PSGetItemInfo = $psgetItemInfo
                                                                                                        }
                }
            }
        }
    }
}