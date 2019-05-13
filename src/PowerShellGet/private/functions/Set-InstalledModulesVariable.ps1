function Set-InstalledModulesVariable
{
    # Initialize list of modules installed by the PowerShellGet provider
    $script:PSGetInstalledModules = [ordered]@{}

    $modulePaths = @($script:ProgramFilesModulesPath, $script:MyDocumentsModulesPath)

    foreach ($location in $modulePaths)
    {
        # find all modules installed using PowerShellGet
        $GetChildItemParams = @{
            Path = $location
            Recurse = $true
            Force = $true
            Filter = $script:PSGetItemInfoFileName
            ErrorAction = 'SilentlyContinue'
            WarningAction = 'SilentlyContinue'
        }

        if($script:IsWindows)
        {
            $GetChildItemParams['Attributes'] = 'Hidden'
        }

        $moduleBases = Get-ChildItem @GetChildItemParams | Foreach-Object { $_.Directory }


        foreach ($moduleBase in $moduleBases)
        {
            $PSGetItemInfoPath = Microsoft.PowerShell.Management\Join-Path $moduleBase.FullName $script:PSGetItemInfoFileName

            # Check if this module got installed using PSGet, read its contents to create a SoftwareIdentity object
            if (Microsoft.PowerShell.Management\Test-Path $PSGetItemInfoPath)
            {
                $psgetItemInfo = DeSerialize-PSObject -Path $PSGetItemInfoPath

                # Add InstalledLocation if this module was installed with older version of PowerShellGet
                if(-not (Get-Member -InputObject $psgetItemInfo -Name $script:InstalledLocation))
                {
                    Microsoft.PowerShell.Utility\Add-Member -InputObject $psgetItemInfo `
                                                            -MemberType NoteProperty `
                                                            -Name $script:InstalledLocation `
                                                            -Value $moduleBase.FullName
                }

                $package = New-SoftwareIdentityFromPSGetItemInfo -PSGetItemInfo $psgetItemInfo

                if($package)
                {
                    $script:PSGetInstalledModules["$($psgetItemInfo.Name)$($psgetItemInfo.Version)"] = @{
                                                                                                            SoftwareIdentity = $package
                                                                                                            PSGetItemInfo = $psgetItemInfo
                                                                                                        }
                }
            }
        }
    }
}