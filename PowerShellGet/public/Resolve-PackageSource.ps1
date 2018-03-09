function Resolve-PackageSource
{
    Write-Debug ($LocalizedData.ProviderApiDebugMessage -f ('Resolve-PackageSource'))

    Set-ModuleSourcesVariable

    $SourceName = $request.PackageSources

    if(-not $SourceName)
    {
        $SourceName = "*"
    }

    foreach($moduleSourceName in $SourceName)
    {
        if($request.IsCanceled)
        {
            return
        }

        $wildcardPattern = New-Object System.Management.Automation.WildcardPattern $moduleSourceName,$script:wildcardOptions
        $moduleSourceFound = $false

        $script:PSGetModuleSources.GetEnumerator() |
            Microsoft.PowerShell.Core\Where-Object {$wildcardPattern.IsMatch($_.Key)} |
                Microsoft.PowerShell.Core\ForEach-Object {

                    $moduleSource = $script:PSGetModuleSources[$_.Key]

                    $packageSource = New-PackageSourceFromModuleSource -ModuleSource $moduleSource

                    Write-Output -InputObject $packageSource

                    $moduleSourceFound = $true
                }

        if(-not $moduleSourceFound)
        {
            $sourceName  = Get-SourceName -Location $moduleSourceName

            if($sourceName)
            {
                $moduleSource = $script:PSGetModuleSources[$sourceName]

                $packageSource = New-PackageSourceFromModuleSource -ModuleSource $moduleSource

                Write-Output -InputObject $packageSource
            }
            elseif( -not (Test-WildcardPattern $moduleSourceName))
            {
                $message = $LocalizedData.RepositoryNotFound -f ($moduleSourceName)

                Write-Error -Message $message -ErrorId "RepositoryNotFound" -Category InvalidOperation -TargetObject $moduleSourceName
            }
        }
    }
}