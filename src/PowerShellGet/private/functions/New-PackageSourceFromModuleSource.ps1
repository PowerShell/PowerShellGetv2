function New-PackageSourceFromModuleSource
{
    param
    (
        [Parameter(Mandatory=$true)]
        $ModuleSource
    )

    $ScriptSourceLocation = $null
    if(Get-Member -InputObject $ModuleSource -Name $script:ScriptSourceLocation)
    {
        $ScriptSourceLocation = $ModuleSource.ScriptSourceLocation
    }

    $ScriptPublishLocation = $ModuleSource.PublishLocation
    if(Get-Member -InputObject $ModuleSource -Name $script:ScriptPublishLocation)
    {
        $ScriptPublishLocation = $ModuleSource.ScriptPublishLocation
    }

    $packageSourceDetails = @{}
    $packageSourceDetails["InstallationPolicy"] = $ModuleSource.InstallationPolicy
    $packageSourceDetails["PackageManagementProvider"] = (Get-ProviderName -PSCustomObject $ModuleSource)
    $packageSourceDetails[$script:PublishLocation] = $ModuleSource.PublishLocation
    $packageSourceDetails[$script:ScriptSourceLocation] = $ScriptSourceLocation
    $packageSourceDetails[$script:ScriptPublishLocation] = $ScriptPublishLocation

    $ModuleSource.ProviderOptions.GetEnumerator() | Microsoft.PowerShell.Core\ForEach-Object {
                                                        $packageSourceDetails[$_.Key] = $_.Value
                                                    }

    # create a new package source
    $src =  New-PackageSource -Name $ModuleSource.Name `
                              -Location $ModuleSource.SourceLocation `
                              -Trusted $ModuleSource.Trusted `
                              -Registered $ModuleSource.Registered `
                              -Details $packageSourceDetails

    Write-Verbose ( $LocalizedData.RepositoryDetails -f ($src.Name, $src.Location, $src.IsTrusted, $src.IsRegistered) )

    # return the package source object.
    Write-Output -InputObject $src
}