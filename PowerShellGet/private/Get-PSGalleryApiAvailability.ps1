function Get-PSGalleryApiAvailability
{
    param
    (
        [Parameter()]
        [string[]]
        $Repository
    )

    # skip if repository is null or not PSGallery
    if ( -not $Repository)
    {
        return
    }

    if ($Repository -notcontains $Script:PSGalleryModuleSource )
    {
        return
    }

    # run check only once
    if( -not $Script:PSGalleryApiChecked)
    {
        $null = Check-PSGalleryApiAvailability -PSGalleryV2ApiUri $Script:PSGallerySourceUri -PSGalleryV3ApiUri $Script:PSGalleryV3SourceUri
    }

    if ( -not $Script:PSGalleryV2ApiAvailable )
    {
        if ($Script:PSGalleryV3ApiAvailable)
        {
            ThrowError -ExceptionName "System.InvalidOperationException" `
                       -ExceptionMessage $LocalizedData.PSGalleryApiV2Discontinued `
                       -ErrorId "PSGalleryApiV2Discontinued" `
                       -CallerPSCmdlet $PSCmdlet `
                       -ErrorCategory InvalidOperation
        }
        else
        {
            # both APIs are down, throw error
            ThrowError -ExceptionName "System.InvalidOperationException" `
                       -ExceptionMessage $LocalizedData.PowerShellGalleryUnavailable `
                       -ErrorId "PowerShellGalleryUnavailable" `
                       -CallerPSCmdlet $PSCmdlet `
                       -ErrorCategory InvalidOperation
        }

    }
    else
    {
        if ($Script:PSGalleryV3ApiAvailable)
        {
            Write-Warning -Message $LocalizedData.PSGalleryApiV2Deprecated
            return
        }
    }

    # if V2 is available and V3 is not available, do nothing
}
