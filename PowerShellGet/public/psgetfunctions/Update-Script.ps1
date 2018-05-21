function Update-Script
{
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(SupportsShouldProcess=$true,
                   HelpUri='https://go.microsoft.com/fwlink/?LinkId=619787')]
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
        [ValidateNotNullOrEmpty()]
        [Uri]
        $Proxy,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [PSCredential]
        $ProxyCredential,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [PSCredential]
        $Credential,

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

        # Script names already tried in the current pipeline
        $scriptNamesInPipeline = @()
    }

    Process
    {
        $scriptFilePathsToUpdate = @()

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

        if($Name)
        {
            foreach($scriptName in $Name)
            {
                $availableScriptPaths = Get-AvailableScriptFilePath -Name $scriptName -Verbose:$false

                if(-not $availableScriptPaths -and -not (Test-WildcardPattern -Name $scriptName))
                {
                    $message = $LocalizedData.ScriptNotInstalledOnThisMachine -f ($scriptName, $script:MyDocumentsScriptsPath, $script:ProgramFilesScriptsPath)
                    Write-Error -Message $message -ErrorId "ScriptNotInstalledOnThisMachine" -Category InvalidOperation -TargetObject $scriptName
                    continue
                }

                foreach($scriptFilePath in $availableScriptPaths)
                {
                    $installedScriptFilePath = Get-InstalledScriptFilePath -Name ([System.IO.Path]::GetFileNameWithoutExtension($scriptFilePath)) |
                                                   Microsoft.PowerShell.Core\Where-Object {$_ -eq $scriptFilePath }

                    # Check if this script got installed with PowerShellGet and user has required permissions
                    if ($installedScriptFilePath)
                    {
                        if(-not (Test-RunningAsElevated) -and $installedScriptFilePath.StartsWith($script:ProgramFilesScriptsPath, [System.StringComparison]::OrdinalIgnoreCase))
                        {
                            if(-not (Test-WildcardPattern -Name $scriptName))
                            {
                                $message = $LocalizedData.AdminPrivilegesRequiredForScriptUpdate -f ($scriptName, $installedScriptFilePath)
                                Write-Error -Message $message -ErrorId "AdminPrivilegesAreRequiredForUpdate" -Category InvalidOperation -TargetObject $scriptName
                            }
                            continue
                        }

                        $scriptFilePathsToUpdate += $installedScriptFilePath
                    }
                    else
                    {
                        if(-not (Test-WildcardPattern -Name $scriptName))
                        {
                            $message = $LocalizedData.ScriptNotInstalledUsingPowerShellGet -f ($scriptName)
                            Write-Error -Message $message -ErrorId "ScriptNotInstalledUsingPowerShellGet" -Category InvalidOperation -TargetObject $scriptName
                        }
                        continue
                    }
                }
            }
        }
        else
        {
            $isRunningAsElevated = Test-RunningAsElevated
            $installedScriptFilePaths = Get-InstalledScriptFilePath

            if($isRunningAsElevated)
            {
                $scriptFilePathsToUpdate = $installedScriptFilePaths
            }
            else
            {
                # Update the scripts installed under
                $scriptFilePathsToUpdate = $installedScriptFilePaths | Microsoft.PowerShell.Core\Where-Object {
                                                $_.StartsWith($script:MyDocumentsScriptsPath, [System.StringComparison]::OrdinalIgnoreCase)}
            }
        }

        $PSBoundParameters["Provider"] = $script:PSModuleProviderName
        $PSBoundParameters[$script:PSArtifactType] = $script:PSArtifactTypeScript
        $PSBoundParameters["InstallUpdate"] = $true

        foreach($scriptFilePath in $scriptFilePathsToUpdate)
        {
            $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($scriptFilePath)

            $installedScriptInfoFilePath = $null
            $installedScriptInfoFileName = "$($scriptName)_$script:InstalledScriptInfoFileName"

            if($scriptFilePath.ToString().StartsWith($script:MyDocumentsScriptsPath, [System.StringComparison]::OrdinalIgnoreCase))
            {
                $PSBoundParameters["Scope"] = "CurrentUser"
                $installedScriptInfoFilePath = Microsoft.PowerShell.Management\Join-Path -Path $script:MyDocumentsInstalledScriptInfosPath `
                                                                                         -ChildPath $installedScriptInfoFileName
            }
            elseif($scriptFilePath.ToString().StartsWith($script:ProgramFilesScriptsPath, [System.StringComparison]::OrdinalIgnoreCase))
            {
                $PSBoundParameters["Scope"] = "AllUsers"
                $installedScriptInfoFilePath = Microsoft.PowerShell.Management\Join-Path -Path $script:ProgramFilesInstalledScriptInfosPath `
                                                                                         -ChildPath $installedScriptInfoFileName

            }

            $psgetItemInfo = $null
            if($installedScriptInfoFilePath -and (Microsoft.PowerShell.Management\Test-Path -Path $installedScriptInfoFilePath -PathType Leaf))
            {
                $psgetItemInfo = DeSerialize-PSObject -Path $installedScriptInfoFilePath
            }

            # Skip the script name if it is already tried in the current pipeline
            if(-not $psgetItemInfo -or ($scriptNamesInPipeline -contains $psgetItemInfo.Name))
            {
                continue
            }


            $scriptFilePath = Microsoft.PowerShell.Management\Join-Path -Path $psgetItemInfo.InstalledLocation `
                                                                        -ChildPath "$($psgetItemInfo.Name).ps1"

            # Remove the InstalledScriptInfo.xml file if the actual script file was manually uninstalled by the user
            if(-not (Microsoft.PowerShell.Management\Test-Path -Path $scriptFilePath -PathType Leaf))
            {
                Microsoft.PowerShell.Management\Remove-Item -Path $installedScriptInfoFilePath -Force -ErrorAction SilentlyContinue

                continue
            }

            $scriptNamesInPipeline += $psgetItemInfo.Name

            $message = $LocalizedData.CheckingForScriptUpdate -f ($psgetItemInfo.Name)
            Write-Verbose -Message $message

            $providerName = Get-ProviderName -PSCustomObject $psgetItemInfo
            if(-not $providerName)
            {
                $providerName = $script:NuGetProviderName
            }

            $PSBoundParameters["MessageResolver"] = $script:PackageManagementUpdateScriptMessageResolverScriptBlock
            $PSBoundParameters["PackageManagementProvider"] = $providerName
            $PSBoundParameters["Name"] = $psgetItemInfo.Name
            $PSBoundParameters['Source'] = $psgetItemInfo.Repository
            $PSBoundParameters[$script:AllowPrerelease] = $AllowPrerelease
            $null = $PSBoundParameters.Remove("AllowPrerelease")

            Get-PSGalleryApiAvailability -Repository (Get-SourceName -Location $psgetItemInfo.RepositorySourceLocation)

            $sid = PackageManagement\Install-Package @PSBoundParameters
        }
    }
}