function Get-InstalledPackage
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $Name,

        [Parameter()]
        [string]
        $RequiredVersion,

        [Parameter()]
        [string]
        $MinimumVersion,

        [Parameter()]
        [string]
        $MaximumVersion
    )

    Write-Debug -Message ($LocalizedData.ProviderApiDebugMessage -f ('Get-InstalledPackage'))

    $options = $request.Options

    foreach( $o in $options.Keys )
    {
        Write-Debug ( "OPTION: {0} => {1}" -f ($o, $options[$o]) )
    }

    $artifactTypes = $script:PSArtifactTypeModule
    if($options.ContainsKey($script:PSArtifactType))
    {
        $artifactTypes = $options[$script:PSArtifactType]
    }

    if($artifactTypes -eq $script:All)
    {
        $artifactTypes = @($script:PSArtifactTypeModule,$script:PSArtifactTypeScript)
    }

    if($artifactTypes -contains $script:PSArtifactTypeModule)
    {
        Get-InstalledModuleDetails -Name $Name `
                                   -RequiredVersion $RequiredVersion `
                                   -MinimumVersion $MinimumVersion `
                                   -MaximumVersion $MaximumVersion | Microsoft.PowerShell.Core\ForEach-Object {$_.SoftwareIdentity}
    }

    if($artifactTypes -contains $script:PSArtifactTypeScript)
    {
        Get-InstalledScriptDetails -Name $Name `
                                   -RequiredVersion $RequiredVersion `
                                   -MinimumVersion $MinimumVersion `
                                   -MaximumVersion $MaximumVersion | Microsoft.PowerShell.Core\ForEach-Object {$_.SoftwareIdentity}
    }
}