function Get-PSRepository {
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=517127')]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name
    )

    Begin {
    }

    Process {
        $PSBoundParameters["Provider"] = $script:PSModuleProviderName
        $PSBoundParameters["MessageResolver"] = $script:PackageManagementMessageResolverScriptBlock

        $repositories = @()

        if ($Name) {
            foreach ($sourceName in $Name) {
                $PSBoundParameters["Name"] = $sourceName

                $packageSources = PackageManagement\Get-PackageSource @PSBoundParameters

                $repositories += $packageSources | Microsoft.PowerShell.Core\ForEach-Object { New-ModuleSourceFromPackageSource -PackageSource $_ }
            }
        }
        else {
            $packageSources = PackageManagement\Get-PackageSource @PSBoundParameters

            $repositories += $packageSources | Microsoft.PowerShell.Core\ForEach-Object { New-ModuleSourceFromPackageSource -PackageSource $_ }
        }

        $repositories |
            Microsoft.PowerShell.Utility\Sort-Object -Property IsTrusted -Descending |
            Microsoft.PowerShell.Utility\Sort-Object -Property Name
    }
}
