function Update-Module
{
    <#
    .ExternalHelp ..\PSModule-help.xml
    #>
    [CmdletBinding(SupportsShouldProcess=$true,
                   HelpUri='https://go.microsoft.com/fwlink/?LinkID=398576')]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [string]
        $RequiredVersion,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [string]
        $MaximumVersion,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [PSCredential]
        $Credential,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [PSCredential]
        $ProxyCredential,

        [Parameter()]
        [Switch]
        $Force,

        [Parameter()]
        [Switch]
        $AllowPrerelease,

        [Parameter()]
        [switch]
        $AcceptLicense
    )

    Begin
    {
        Install-NuGetClientBinaries -CallerPSCmdlet $PSCmdlet -Proxy $Proxy -ProxyCredential $ProxyCredential

        # Module names already tried in the current pipeline
        $moduleNamesInPipeline = @()
    }

    Process
    {
        $ValidationResult = Validate-VersionParameters -CallerPSCmdlet $PSCmdlet `
                                                       -Name $Name `
                                                       -MaximumVersion $MaximumVersion `
                                                       -RequiredVersion $RequiredVersion `
                                                       -AllowPrerelease:$AllowPrerelease

        if(-not $ValidationResult)
        {
            # Validate-VersionParameters throws the error.
            # returning to avoid further execution when different values are specified for -ErrorAction parameter
            return
        }

        $GetPackageParameters = @{}
        $GetPackageParameters[$script:PSArtifactType] = $script:PSArtifactTypeModule
        $GetPackageParameters["Provider"] = $script:PSModuleProviderName
        $GetPackageParameters["MessageResolver"] = $script:PackageManagementMessageResolverScriptBlock
        $GetPackageParameters['ErrorAction'] = 'SilentlyContinue'
        $GetPackageParameters['WarningAction'] = 'SilentlyContinue'
        $PSBoundParameters[$script:AllowPrereleaseVersions] = $AllowPrerelease
        $null = $PSBoundParameters.Remove("AllowPrerelease")

        $PSGetItemInfos = @()

        if($Name)
        {
            foreach($moduleName in $Name)
            {
                $GetPackageParameters['Name'] = $moduleName
                $installedPackages = PackageManagement\Get-Package @GetPackageParameters

                if(-not $installedPackages -and -not (Test-WildcardPattern -Name $moduleName))
                {
                    $availableModules = Get-Module -ListAvailable $moduleName -Verbose:$false | Microsoft.PowerShell.Utility\Select-Object -Unique -ErrorAction Ignore

                    if(-not $availableModules)
                    {
                        $message = $LocalizedData.ModuleNotInstalledOnThisMachine -f ($moduleName)
                        Write-Error -Message $message -ErrorId 'ModuleNotInstalledOnThisMachine' -Category InvalidOperation -TargetObject $moduleName
                    }
                    else
                    {
                        $message = $LocalizedData.ModuleNotInstalledUsingPowerShellGet -f ($moduleName)
                        Write-Error -Message $message -ErrorId 'ModuleNotInstalledUsingInstallModuleCmdlet' -Category InvalidOperation -TargetObject $moduleName
                    }

                    continue
                }

                $installedPackages |
                    Microsoft.PowerShell.Core\ForEach-Object {New-PSGetItemInfo -SoftwareIdentity $_ -Type $script:PSArtifactTypeModule} |
                        Microsoft.PowerShell.Core\ForEach-Object {
                            if(-not (Test-RunningAsElevated) -and $_.InstalledLocation.StartsWith($script:programFilesModulesPath, [System.StringComparison]::OrdinalIgnoreCase))
                            {
                                if(-not (Test-WildcardPattern -Name $moduleName))
                                {
                                    $message = $LocalizedData.AdminPrivilegesRequiredForUpdate -f ($_.Name, $_.InstalledLocation)
                                    Write-Error -Message $message -ErrorId "AdminPrivilegesAreRequiredForUpdate" -Category InvalidOperation -TargetObject $moduleName
                                }
                                continue
                            }

                            $PSGetItemInfos += $_
                        }
            }
        }
        else
        {

            $PSGetItemInfos = PackageManagement\Get-Package @GetPackageParameters |
                                Microsoft.PowerShell.Core\ForEach-Object {New-PSGetItemInfo -SoftwareIdentity $_ -Type $script:PSArtifactTypeModule} |
                                    Microsoft.PowerShell.Core\Where-Object {
                                        (Test-RunningAsElevated) -or
                                        $_.InstalledLocation.StartsWith($script:MyDocumentsModulesPath, [System.StringComparison]::OrdinalIgnoreCase)
                                    }
        }


        $PSBoundParameters["Provider"] = $script:PSModuleProviderName
        $PSBoundParameters[$script:PSArtifactType] = $script:PSArtifactTypeModule

        foreach($psgetItemInfo in $PSGetItemInfos)
        {
            # Skip the module name if it is already tried in the current pipeline
            if($moduleNamesInPipeline -contains $psgetItemInfo.Name)
            {
                continue
            }

            $moduleNamesInPipeline += $psgetItemInfo.Name

            $message = $LocalizedData.CheckingForModuleUpdate -f ($psgetItemInfo.Name)
            Write-Verbose -Message $message

            $providerName = Get-ProviderName -PSCustomObject $psgetItemInfo
            if(-not $providerName)
            {
                $providerName = $script:NuGetProviderName
            }

            $PSBoundParameters["MessageResolver"] = $script:PackageManagementUpdateModuleMessageResolverScriptBlock
            $PSBoundParameters["Name"] = $psgetItemInfo.Name
            $PSBoundParameters['Source'] = $psgetItemInfo.Repository

            Get-PSGalleryApiAvailability -Repository (Get-SourceName -Location $psgetItemInfo.RepositorySourceLocation)

            $PSBoundParameters["PackageManagementProvider"] = $providerName
            $PSBoundParameters["InstallUpdate"] = $true

            if($psgetItemInfo.InstalledLocation.ToString().StartsWith($script:MyDocumentsModulesPath, [System.StringComparison]::OrdinalIgnoreCase))
            {
                $PSBoundParameters["Scope"] = "CurrentUser"
            }
            else
            {
                $PSBoundParameters['Scope'] = 'AllUsers'
            }

            $sid = PackageManagement\Install-Package @PSBoundParameters
        }
    }
}