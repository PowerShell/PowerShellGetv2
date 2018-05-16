function Save-PSGetSettings
{
    if($script:PSGetSettings)
    {
        if(-not (Microsoft.PowerShell.Management\Test-Path -Path $script:PSGetAppLocalPath))
        {
            $null = Microsoft.PowerShell.Management\New-Item -Path $script:PSGetAppLocalPath `
                                                             -ItemType Directory `
                                                             -Force `
                                                             -ErrorAction SilentlyContinue `
                                                             -WarningAction SilentlyContinue `
                                                             -Confirm:$false `
                                                             -WhatIf:$false
        }

        Microsoft.PowerShell.Utility\Out-File -FilePath $script:PSGetSettingsFilePath -Force `
            -InputObject ([System.Management.Automation.PSSerializer]::Serialize($script:PSGetSettings))

        Write-Debug "In Save-PSGetSettings, persisted the $script:PSGetSettingsFilePath file"
   }
}