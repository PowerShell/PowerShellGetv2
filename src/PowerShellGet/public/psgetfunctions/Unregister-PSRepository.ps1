function Unregister-PSRepository {
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=517130')]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true,
            Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name
    )

    Begin {
    }

    Process {
        $PSBoundParameters["Provider"] = $script:PSModuleProviderName
        $PSBoundParameters["MessageResolver"] = $script:PackageManagementMessageResolverScriptBlock

        $null = $PSBoundParameters.Remove("Name")

        foreach ($moduleSourceName in $Name) {
            # Check if $moduleSourceName contains any wildcards
            if (Test-WildcardPattern $moduleSourceName) {
                $message = $LocalizedData.RepositoryNameContainsWildCards -f ($moduleSourceName)
                Write-Error -Message $message -ErrorId "RepositoryNameContainsWildCards" -Category InvalidOperation
                continue
            }

            $PSBoundParameters["Source"] = $moduleSourceName

            $null = PackageManagement\Unregister-PackageSource @PSBoundParameters

            $nugetCmd = Microsoft.PowerShell.Core\Get-Command -Name $script:NuGetExeName `
                -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

            if ($nugetCmd){
                # remove nuget based repo as a nuget source
                $nugetSourceExists = nuget source list | where-object { $_.Contains($Name) }
                if ($nugetSourceExists) {
                    nuget sources remove -name $Name
                }
            }
        }
    }
}
