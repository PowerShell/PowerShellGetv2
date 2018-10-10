function Test-ValidManifestModule
{
    [CmdletBinding()]
    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleBasePath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InstallLocation,

        [Parameter()]
        [Switch]
        $SkipPublisherCheck,

        [Parameter()]
        [Switch]
        $AllowClobber,

        [Parameter()]
        [Switch]
        $IsUpdateOperation
    )

    Write-Verbose -Message ($LocalizedData.ValidatingTheModule -f $ModuleName,$ModuleBasePath)
    $manifestPath = Join-PathUtility -Path $ModuleBasePath -ChildPath "$ModuleName.psd1" -PathType File
    $PSModuleInfo = $null

    if(-not (Microsoft.PowerShell.Management\Test-Path $manifestPath -PathType Leaf))
    {
        $message = $LocalizedData.PathNotFound -f ($manifestPath)
        ThrowError -ExceptionName 'System.InvalidOperationException' `
                    -ExceptionMessage $message `
                    -ErrorId 'PathNotFound' `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidOperation
    }

    $PSModuleInfo = Microsoft.PowerShell.Core\Test-ModuleManifest -Path $manifestPath -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    if(-not $PSModuleInfo)
    {
        $message = $LocalizedData.InvalidPSModule -f ($moduleName)
        ThrowError -ExceptionName 'System.InvalidOperationException' `
                    -ExceptionMessage $message `
                    -ErrorId 'InvalidManifestModule' `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidOperation
    }
    else
    {
        Write-Verbose -Message ($LocalizedData.ValidatedModuleManifestFile -f $ModuleBasePath)
    }

    if($script:IsWindows)
    {
        Write-Verbose -Message ($LocalizedData.ValidateModuleAuthenticodeSignature -f $ModuleName)
        $ValidationResult = Validate-ModuleAuthenticodeSignature -CurrentModuleInfo $PSModuleInfo `
                                                                    -InstallLocation $InstallLocation `
                                                                    -IsUpdateOperation:$IsUpdateOperation `
                                                                    -SkipPublisherCheck:$SkipPublisherCheck
        
        if($ValidationResult)
        {
            # Checking for the possible command clobbering.
            Write-Verbose -Message ($LocalizedData.ValidateModuleCommandAlreadyAvailable -f $ModuleName)
            $ValidationResult = Validate-ModuleCommandAlreadyAvailable -CurrentModuleInfo $PSModuleInfo `
                                                                        -InstallLocation $InstallLocation `
                                                                        -AllowClobber:$AllowClobber `
                                                                        -IsUpdateOperation:$IsUpdateOperation
        }

        if(-not $ValidationResult)
        {
            $PSModuleInfo = $null
        }
    }

    return $PSModuleInfo
}