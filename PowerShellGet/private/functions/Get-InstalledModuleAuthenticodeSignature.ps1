function Get-InstalledModuleAuthenticodeSignature
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [PSModuleInfo]
        $InstalledModuleInfo,

        [Parameter(Mandatory=$true)]
        [string]
        $InstallLocation
    )

    $ModuleName = $InstalledModuleInfo.Name

    # Priority order for getting the published details of the installed module:
    # 1. Latest version under the $InstallLocation
    # 2. Latest available version in $PSModulePath
    # 3. $InstalledModuleInfo
    $AvailableModules = Microsoft.PowerShell.Core\Get-Module -ListAvailable `
                                                             -Name $ModuleName `
                                                             -ErrorAction SilentlyContinue `
                                                             -WarningAction SilentlyContinue `
                                                             -Verbose:$false |
                            Microsoft.PowerShell.Utility\Sort-Object -Property Version -Descending

    # Remove the version folder on 5.0 to get the actual module base folder without version
    if(Test-ModuleSxSVersionSupport)
    {
        $InstallLocation = Microsoft.PowerShell.Management\Split-Path -Path $InstallLocation
    }

    $SourceModule = $AvailableModules | Microsoft.PowerShell.Core\Where-Object {
                                            $_.ModuleBase.StartsWith($InstallLocation, [System.StringComparison]::OrdinalIgnoreCase)
                                        } | Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

    if(-not $SourceModule)
    {
        $SourceModule = $AvailableModules | Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore
    }
    else
    {
        $SourceModule = $InstalledModuleInfo
    }

    $SignedFilePath = $SourceModule.Path

    $CatalogFileName = "$ModuleName.cat"
    $CatalogFilePath = Microsoft.PowerShell.Management\Join-Path -Path $SourceModule.ModuleBase -ChildPath $CatalogFileName

    if(Microsoft.PowerShell.Management\Test-Path -Path $CatalogFilePath -PathType Leaf)
    {
        $message = $LocalizedData.CatalogFileFound -f ($CatalogFileName, $ModuleName)
        Write-Debug -Message $message

        $SignedFilePath = $CatalogFilePath
    }
    else
    {
        Write-Debug -Message ($LocalizedData.CatalogFileNotFoundInAvailableModule -f ($CatalogFileName, $ModuleName))
    }

    $message = "Using the previously-installed module '{0}' with version '{1}' under '{2}' for getting the publisher details." -f ($SourceModule.Name, $SourceModule.Version, $SourceModule.ModuleBase)
    Write-Debug -Message $message

    $message = "Using the '{0}' file for getting the authenticode signature." -f ($SignedFilePath)
    Write-Debug -Message $message

    $AuthenticodeSignature = Microsoft.PowerShell.Security\Get-AuthenticodeSignature -FilePath $SignedFilePath
    $ModuleDetails = $null

    if($AuthenticodeSignature)
    {
        $ModuleDetails = @{}
        $ModuleDetails['AuthenticodeSignature'] = $AuthenticodeSignature
        $ModuleDetails['Version'] = $SourceModule.Version
        $ModuleDetails['ModuleBase']=$SourceModule.ModuleBase
        $ModuleDetails['IsMicrosoftCertificate'] = Test-MicrosoftCertificate -AuthenticodeSignature $AuthenticodeSignature
        $PublisherDetails = Get-AuthenticodePublisher -AuthenticodeSignature $AuthenticodeSignature
        $ModuleDetails['Publisher'] = if($PublisherDetails) {$PublisherDetails.Publisher}
        $ModuleDetails['RootCertificateAuthority'] = if($PublisherDetails) {$PublisherDetails.PublisherRootCA}
        
        $message = $LocalizedData.SourceModuleDetailsForPublisherValidation -f ($ModuleName, $SourceModule.Version, $SourceModule.ModuleBase, $ModuleDetails.Publisher, $ModuleDetails.RootCertificateAuthority, $ModuleDetails.IsMicrosoftCertificate)
        Write-Debug $message
    }

    return $ModuleDetails
}