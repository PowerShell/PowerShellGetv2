function Copy-ScriptFile
{
    [CmdletBinding(PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourcePath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [PSCustomObject]
        $PSGetItemInfo,

        [Parameter()]
        [string]
        $Scope
    )

    $ev = $null
    $message = $LocalizedData.AdministratorRightsNeededOrSpecifyCurrentUserScope

    # Copy the script file to destination
    if(-not (Microsoft.PowerShell.Management\Test-Path -Path $DestinationPath))
    {
        $null = Microsoft.PowerShell.Management\New-Item -Path $DestinationPath `
                                                         -ItemType Directory `
                                                         -Force `
                                                         -ErrorVariable ev `
                                                         -ErrorAction SilentlyContinue `
                                                         -WarningAction SilentlyContinue `
                                                         -Confirm:$false `
                                                         -WhatIf:$false

        if($ev)
        {
            $script:IsRunningAsElevated = $false
            ThrowError -ExceptionName "System.ArgumentException" `
                       -ExceptionMessage $message `
                       -ErrorId "AdministratorRightsNeededOrSpecifyCurrentUserScope" `
                       -CallerPSCmdlet $PSCmdlet `
                       -ErrorCategory InvalidArgument `
                       -ExceptionObject $ev
        }
    }

    Microsoft.PowerShell.Management\Copy-Item -Path $SourcePath `
                                              -Destination $DestinationPath `
                                              -Force `
                                              -Confirm:$false `
                                              -WhatIf:$false `
                                              -ErrorVariable ev `
                                              -ErrorAction SilentlyContinue

    if($ev)
    {
        $script:IsRunningAsElevated = $false
        ThrowError -ExceptionName "System.ArgumentException" `
                   -ExceptionMessage $message `
                   -ErrorId "AdministratorRightsNeededOrSpecifyCurrentUserScope" `
                   -CallerPSCmdlet $PSCmdlet `
                   -ErrorCategory InvalidArgument `
                   -ExceptionObject $ev
    }

    if($Scope)
    {
        # Create <Name>_InstalledScriptInfo.xml
        $InstalledScriptInfoFileName = "$($PSGetItemInfo.Name)_$script:InstalledScriptInfoFileName"

        if($scope -eq 'AllUsers')
        {
            $scriptInfopath = Microsoft.PowerShell.Management\Join-Path -Path $script:ProgramFilesInstalledScriptInfosPath `
                                                                        -ChildPath $InstalledScriptInfoFileName
        }
        else
        {
            $scriptInfopath = Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsInstalledScriptInfosPath `
                                                                        -ChildPath $InstalledScriptInfoFileName
        }

        Microsoft.PowerShell.Utility\Out-File -FilePath $scriptInfopath `
                                              -Force `
                                              -InputObject ([System.Management.Automation.PSSerializer]::Serialize($PSGetItemInfo))
    }
}