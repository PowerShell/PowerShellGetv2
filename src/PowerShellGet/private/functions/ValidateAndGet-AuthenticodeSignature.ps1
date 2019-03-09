function ValidateAndGet-AuthenticodeSignature
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [PSModuleInfo]
        $ModuleInfo
    )

    $ModuleDetails = $null
    $AuthenticodeSignature = $null

    $ModuleName = $ModuleInfo.Name
    $ModuleBasePath = $ModuleInfo.ModuleBase
    $ModuleManifestName = "$ModuleName.psd1"
    $CatalogFileName = "$ModuleName.cat"
    $CatalogFilePath = Microsoft.PowerShell.Management\Join-Path -Path $ModuleBasePath -ChildPath $CatalogFileName

    if(Microsoft.PowerShell.Management\Test-Path -Path $CatalogFilePath -PathType Leaf)
    {
        $message = $LocalizedData.CatalogFileFound -f ($CatalogFileName, $ModuleName)
        Write-Verbose -Message $message

        $AuthenticodeSignature = Microsoft.PowerShell.Security\Get-AuthenticodeSignature -FilePath $CatalogFilePath

        if(-not $AuthenticodeSignature -or ($AuthenticodeSignature.Status -ne "Valid"))
        {
            $message = $LocalizedData.InvalidModuleAuthenticodeSignature -f ($ModuleName, $CatalogFileName)
            ThrowError -ExceptionName 'System.InvalidOperationException' `
                        -ExceptionMessage $message `
                        -ErrorId 'InvalidAuthenticodeSignature' `
                        -CallerPSCmdlet $PSCmdlet `
                        -ErrorCategory InvalidOperation

            return
        }

        Write-Verbose -Message ($LocalizedData.ValidAuthenticodeSignature -f @($CatalogFileName, $ModuleName))

        if(Get-Command -Name Test-FileCatalog -Module Microsoft.PowerShell.Security -ErrorAction Ignore)
        {
            Write-Verbose -Message ($LocalizedData.ValidatingCatalogSignature -f @($ModuleName, $CatalogFileName))

            # Skip the PSGetModuleInfo.xml and ModuleName.cat files in the catalog validation
            $TestFileCatalogResult = Microsoft.PowerShell.Security\Test-FileCatalog -Path $ModuleBasePath `
                                                                                    -CatalogFilePath $CatalogFilePath `
                                                                                    -FilesToSkip $script:PSGetItemInfoFileName,'*.cat','*.nupkg','*.nuspec' `
                                                                                    -Detailed `
                                                                                    -ErrorAction SilentlyContinue
            if(-not $TestFileCatalogResult -or
                ($TestFileCatalogResult.Status -ne "Valid") -or
                ($TestFileCatalogResult.Signature.Status -ne "Valid"))
            {
                $message = $LocalizedData.InvalidCatalogSignature -f ($ModuleName, $CatalogFileName)
                ThrowError -ExceptionName 'System.InvalidOperationException' `
                            -ExceptionMessage $message `
                            -ErrorId 'InvalidCatalogSignature' `
                            -CallerPSCmdlet $PSCmdlet `
                            -ErrorCategory InvalidOperation
                return
            }
            else
            {
                Write-Verbose -Message ($LocalizedData.ValidCatalogSignature -f @($CatalogFileName, $ModuleName))
            }
        }
    }
    else
    {
        Write-Verbose -Message ($LocalizedData.CatalogFileNotFoundInNewModule -f ($CatalogFileName, $ModuleName))

        $message = "Using the '{0}' file for getting the authenticode signature." -f ($ModuleManifestName)
        Write-Debug -Message $message

        $AuthenticodeSignature = Microsoft.PowerShell.Security\Get-AuthenticodeSignature -FilePath $ModuleInfo.Path

        if($AuthenticodeSignature)
        {
            if($AuthenticodeSignature.Status -eq "Valid")
            {
                Write-Verbose -Message ($LocalizedData.ValidAuthenticodeSignatureInFile -f @($ModuleManifestName, $ModuleName))
            }
            elseif($AuthenticodeSignature.Status -ne "NotSigned")
            {
                $message = $LocalizedData.InvalidModuleAuthenticodeSignature -f ($ModuleName, $ModuleManifestName)
                ThrowError -ExceptionName 'System.InvalidOperationException' `
                           -ExceptionMessage $message `
                           -ErrorId 'InvalidAuthenticodeSignature' `
                           -CallerPSCmdlet $PSCmdlet `
                           -ErrorCategory InvalidOperation
                return
            }
        }
    }

    if($AuthenticodeSignature)
    {
        $ModuleDetails = @{}
        $ModuleDetails['AuthenticodeSignature'] = $AuthenticodeSignature
        $ModuleDetails['Version'] = $ModuleInfo.Version
        $ModuleDetails['ModuleBase']=$ModuleInfo.ModuleBase
        $ModuleDetails['IsMicrosoftCertificate'] = Test-MicrosoftCertificate -AuthenticodeSignature $AuthenticodeSignature
        $PublisherDetails = Get-AuthenticodePublisher -AuthenticodeSignature $AuthenticodeSignature
        $ModuleDetails['Publisher'] = if($PublisherDetails) {$PublisherDetails.Publisher}
        $ModuleDetails['RootCertificateAuthority'] = if($PublisherDetails) {$PublisherDetails.PublisherRootCA}

        $message = $LocalizedData.NewModuleVersionDetailsForPublisherValidation -f ($ModuleInfo.Name, $ModuleInfo.Version, $ModuleDetails.Publisher, $ModuleDetails.RootCertificateAuthority, $ModuleDetails.IsMicrosoftCertificate)
        Write-Debug $message
    }

    return $ModuleDetails
}