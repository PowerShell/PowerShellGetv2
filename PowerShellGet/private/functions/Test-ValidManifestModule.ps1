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

    $moduleName = Microsoft.PowerShell.Management\Split-Path $ModuleBasePath -Leaf
    $manifestPath = Join-PathUtility -Path $ModuleBasePath -ChildPath "$moduleName.psd1" -PathType File
    $PSModuleInfo = $null

    if(Microsoft.PowerShell.Management\Test-Path $manifestPath)
    {
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
        elseif($script:IsWindows)
        {
            $ValidationResult = Validate-ModuleAuthenticodeSignature -CurrentModuleInfo $PSModuleInfo `
                                                                     -InstallLocation $InstallLocation `
                                                                     -IsUpdateOperation:$IsUpdateOperation `
                                                                     -SkipPublisherCheck:$SkipPublisherCheck

            if($ValidationResult)
            {
                # Checking for the possible command clobbering.
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
    }

    return $PSModuleInfo
}