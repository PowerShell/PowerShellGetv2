function Copy-Module
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
        $PSGetItemInfo
    )

    $ev = $null
    $message = $LocalizedData.AdministratorRightsNeededOrSpecifyCurrentUserScope

    if(Microsoft.PowerShell.Management\Test-Path $DestinationPath)
    {
        Microsoft.PowerShell.Management\Remove-Item -Path $DestinationPath `
                                                    -Recurse `
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


    # Copy the module to destination
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

    Microsoft.PowerShell.Management\Copy-Item -Path "$SourcePath\*" `
                                              -Destination $DestinationPath `
                                              -Force `
                                              -Recurse `
                                              -ErrorVariable ev `
                                              -ErrorAction SilentlyContinue `
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

    # Remove the *.nupkg file
    $NupkgFilePath = Join-PathUtility -Path $DestinationPath -ChildPath "$($PSGetItemInfo.Name).nupkg" -PathType File
    if(Microsoft.PowerShell.Management\Test-Path -Path $NupkgFilePath -PathType Leaf)
    {
        Microsoft.PowerShell.Management\Remove-Item -Path $NupkgFilePath -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Confirm:$false -WhatIf:$false
    }

    # Create PSGetModuleInfo.xml
    $psgetItemInfopath = Microsoft.PowerShell.Management\Join-Path $DestinationPath $script:PSGetItemInfoFileName

    Microsoft.PowerShell.Utility\Out-File -FilePath $psgetItemInfopath -Force -InputObject ([System.Management.Automation.PSSerializer]::Serialize($PSGetItemInfo))

    [System.IO.File]::SetAttributes($psgetItemInfopath, [System.IO.FileAttributes]::Hidden)
}