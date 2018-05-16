function Log-ArtifactNotFoundInPSGallery
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [string[]]
        $SearchedName,

        [Parameter()]
        [string[]]
        $FoundName,

        [Parameter(Mandatory=$true)]
        [string]
        $operationName
    )

    if (-not $script:TelemetryEnabled)
    {
        return
    }

    if(-not $SearchedName)
    {
        return
    }

    $SearchedNameNoWildCards = @()

    # Ignore wild cards
    foreach ($artifactName in $SearchedName)
    {
        if (-not (Test-WildcardPattern $artifactName))
        {
            $SearchedNameNoWildCards += $artifactName
        }
    }

    # Find artifacts searched, but not found in the specified gallery
    $notFoundArtifacts = @()
    foreach ($element in $SearchedNameNoWildCards)
    {
        if (-not ($FoundName -contains $element))
        {
            $notFoundArtifacts += $element
        }
    }

    # Perform Telemetry only if searched artifacts are not available in specified Gallery
    if ($notFoundArtifacts)
    {
        [Microsoft.PowerShell.Commands.PowerShellGet.Telemetry]::TraceMessageArtifactsNotFound($notFoundArtifacts, $operationName)
    }
}