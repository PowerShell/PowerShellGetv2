function New-ModuleSourceFromPackageSource
{
    param
    (
        [Parameter(Mandatory=$true)]
        $PackageSource
    )

    $moduleSource = Microsoft.PowerShell.Utility\New-Object PSCustomObject -Property ([ordered]@{
            Name = $PackageSource.Name
            SourceLocation =  $PackageSource.Location
            Trusted=$PackageSource.IsTrusted
            Registered=$PackageSource.IsRegistered
            InstallationPolicy = $PackageSource.Details['InstallationPolicy']
            PackageManagementProvider=$PackageSource.Details['PackageManagementProvider']
            PublishLocation=$PackageSource.Details[$script:PublishLocation]
            ScriptSourceLocation=$PackageSource.Details[$script:ScriptSourceLocation]
            ScriptPublishLocation=$PackageSource.Details[$script:ScriptPublishLocation]
            ProviderOptions = @{}
        })

    $PackageSource.Details.GetEnumerator() | Microsoft.PowerShell.Core\ForEach-Object {
                                                if($_.Key -ne 'PackageManagementProvider' -and
                                                   $_.Key -ne $script:PublishLocation -and
                                                   $_.Key -ne $script:ScriptPublishLocation -and
                                                   $_.Key -ne $script:ScriptSourceLocation -and
                                                   $_.Key -ne 'InstallationPolicy')
                                                {
                                                    $moduleSource.ProviderOptions[$_.Key] = $_.Value
                                                }
                                             }

    $moduleSource.PSTypeNames.Insert(0, "Microsoft.PowerShell.Commands.PSRepository")

    # return the module source object.
    Write-Output -InputObject $moduleSource
}