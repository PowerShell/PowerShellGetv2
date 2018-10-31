function Set-PSGalleryRepository
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]
        $Trusted,

        [Parameter()]
        $Proxy,

        [Parameter()]
        $ProxyCredential,

        [Parameter()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet
    )

    $psgalleryLocation = Resolve-Location -Location $Script:PSGallerySourceUri `
                                          -Proxy $Proxy `
                                          -ProxyCredential $ProxyCredential `
                                          -CallerPSCmdlet $CallerPSCmdlet `
                                          -ErrorAction SilentlyContinue
                                          

    $scriptSourceLocation = Resolve-Location -Location $Script:PSGalleryScriptSourceUri `
                                             -Proxy $Proxy `
                                             -ProxyCredential $ProxyCredential `
                                             -CallerPSCmdlet $CallerPSCmdlet `
                                             -ErrorAction SilentlyContinue 
                                              
    if($psgalleryLocation)
    {
        $result = Ping-Endpoint -Endpoint $Script:PSGalleryPublishUri -AllowAutoRedirect:$false -Proxy $Proxy -ProxyCredential $ProxyCredential
        if ($result.ContainsKey($Script:ResponseUri) -and $result[$Script:ResponseUri])
        {
                $script:PSGalleryPublishUri = $result[$Script:ResponseUri]
        }

        $repository = Microsoft.PowerShell.Utility\New-Object PSCustomObject -Property ([ordered]@{
                Name = $Script:PSGalleryModuleSource
                SourceLocation =  $psgalleryLocation
                PublishLocation = $Script:PSGalleryPublishUri
                ScriptSourceLocation = $scriptSourceLocation
                ScriptPublishLocation = $Script:PSGalleryPublishUri
                Trusted=$Trusted
                Registered=$true
                InstallationPolicy = if($Trusted) {'Trusted'} else {'Untrusted'}
                PackageManagementProvider=$script:NuGetProviderName
                ProviderOptions = @{}
            })

        $repository.PSTypeNames.Insert(0, "Microsoft.PowerShell.Commands.PSRepository")
        $script:PSGetModuleSources[$Script:PSGalleryModuleSource] = $repository

        Save-ModuleSources

        return $repository
    }
}