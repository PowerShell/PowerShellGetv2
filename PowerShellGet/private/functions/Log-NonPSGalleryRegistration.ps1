function Log-NonPSGalleryRegistration
# Function to record non-PSGallery registration for telemetry
# Function consumes the type of registration (i.e hosted (http(s)), non-hosted (file/unc)), locations, installation policy, provider and event name
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [string]
        $sourceLocation,

        [Parameter()]
        [string]
        $installationPolicy,

        [Parameter()]
        [string]
        $packageManagementProvider,

        [Parameter()]
        [string]
        $publishLocation,

        [Parameter()]
        [string]
        $scriptSourceLocation,

        [Parameter()]
        [string]
        $scriptPublishLocation,

        [Parameter(Mandatory=$true)]
        [string]
        $operationName
    )

    if (-not $script:TelemetryEnabled)
    {
        return
    }

    # Initialize source location type - this can be hosted (http(s)) or not hosted (unc/file)
    $sourceLocationType = "NON_WEB_HOSTED"
    if (Test-WebUri -uri $sourceLocation)
    {
        $sourceLocationType = "WEB_HOSTED"
    }

    # Create a hash of the source location
    # We cannot log the actual source location, since this might contain PII (Personally identifiable information) data
    $sourceLocationHash = Get-Hash -locationString $sourceLocation
    $publishLocationHash = Get-Hash -locationString $publishLocation
    $scriptSourceLocationHash = Get-Hash -locationString $scriptSourceLocation
    $scriptPublishLocationHash = Get-Hash -locationString $scriptPublishLocation

    # Log the telemetry event
    [Microsoft.PowerShell.Commands.PowerShellGet.Telemetry]::TraceMessageNonPSGalleryRegistration($sourceLocationType, $sourceLocationHash, $installationPolicy, $packageManagementProvider, $publishLocationHash, $scriptSourceLocationHash, $scriptPublishLocationHash, $operationName)
}