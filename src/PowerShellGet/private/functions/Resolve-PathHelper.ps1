function Resolve-PathHelper
{
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $path,

        [Parameter()]
        [switch]
        $isLiteralPath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $callerPSCmdlet
    )

    $resolvedPaths =@()

    foreach($currentPath in $path)
    {
        try
        {
            if($isLiteralPath)
            {
                $currentResolvedPaths = Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $currentPath -ErrorAction Stop
            }
            else
            {
                $currentResolvedPaths = Microsoft.PowerShell.Management\Resolve-Path -Path $currentPath -ErrorAction Stop
            }
        }
        catch
        {
            $errorMessage = ($LocalizedData.PathNotFound -f $currentPath)
            ThrowError  -ExceptionName "System.InvalidOperationException" `
                        -ExceptionMessage $errorMessage `
                        -ErrorId "PathNotFound" `
                        -CallerPSCmdlet $callerPSCmdlet `
                        -ErrorCategory InvalidOperation
        }

        foreach($currentResolvedPath in $currentResolvedPaths)
        {
            $resolvedPaths += $currentResolvedPath.ProviderPath
        }
    }

    $resolvedPaths
}
