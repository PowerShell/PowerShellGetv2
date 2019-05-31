function Update-ScriptFileInfo {
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(PositionalBinding = $false,
        DefaultParameterSetName = 'PathParameterSet',
        SupportsShouldProcess = $true,
        HelpUri = 'https://go.microsoft.com/fwlink/?LinkId=619793')]
    Param
    (
        [Parameter(Mandatory = $true,
            Position = 0,
            ParameterSetName = 'PathParameterSet',
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(Mandatory = $true,
            Position = 0,
            ParameterSetName = 'LiteralPathParameterSet',
            ValueFromPipelineByPropertyName = $true)]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string]
        $LiteralPath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Version,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Author,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Guid]
        $Guid,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $CompanyName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Copyright,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $RequiredModules,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $ExternalModuleDependencies,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $RequiredScripts,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $ExternalScriptDependencies,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Tags,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $ProjectUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $LicenseUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $IconUri,

        [Parameter()]
        [string[]]
        $ReleaseNotes,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $PrivateData,

        [Parameter()]
        [switch]
        $PassThru,

        [Parameter()]
        [switch]
        $Force
    )

    Process {
        # Resolve the script path
        $scriptFilePath = $null
        if ($Path) {
            $scriptFilePath = Resolve-PathHelper -Path $Path -CallerPSCmdlet $PSCmdlet |
            Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

            if (-not $scriptFilePath -or
                -not (Microsoft.PowerShell.Management\Test-Path -Path $scriptFilePath -PathType Leaf)) {
                $errorMessage = ($LocalizedData.PathNotFound -f $Path)
                ThrowError  -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $errorMessage `
                    -ErrorId "PathNotFound" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ExceptionObject $Path `
                    -ErrorCategory InvalidArgument
            }
        }
        else {
            $scriptFilePath = Resolve-PathHelper -Path $LiteralPath -IsLiteralPath -CallerPSCmdlet $PSCmdlet |
            Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

            if (-not $scriptFilePath -or
                -not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $scriptFilePath -PathType Leaf)) {
                $errorMessage = ($LocalizedData.PathNotFound -f $LiteralPath)
                ThrowError  -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $errorMessage `
                    -ErrorId "PathNotFound" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ExceptionObject $LiteralPath `
                    -ErrorCategory InvalidArgument
            }
        }

        if (-not $scriptFilePath.EndsWith('.ps1', [System.StringComparison]::OrdinalIgnoreCase)) {
            $errorMessage = ($LocalizedData.InvalidScriptFilePath -f $scriptFilePath)
            ThrowError  -ExceptionName "System.ArgumentException" `
                -ExceptionMessage $errorMessage `
                -ErrorId "InvalidScriptFilePath" `
                -CallerPSCmdlet $PSCmdlet `
                -ExceptionObject $scriptFilePath `
                -ErrorCategory InvalidArgument
            return
        }

        # Obtain script info
        $psscriptInfo = $null
        try {
            $psscriptInfo = Test-ScriptFileInfo -LiteralPath $scriptFilePath
        }
        catch {
            if (-not $Force) {
                throw $_
                return
            }
        }

        if (-not $psscriptInfo) {
            if (-not $Description) {
                ThrowError  -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $LocalizedData.DescriptionParameterIsMissingForAddingTheScriptFileInfo `
                    -ErrorId 'DescriptionParameterIsMissingForAddingTheScriptFileInfo' `
                    -CallerPSCmdlet $PSCmdlet `
                    -ErrorCategory InvalidArgument
                return
            }

            if (-not $Version) {
                $Version = '1.0'
            }
            else {
                $result = ValidateAndGet-VersionPrereleaseStrings -Version $Version -CallerPSCmdlet $PSCmdlet
                if (-not $result) {
                    # ValidateAndGet-VersionPrereleaseStrings throws the error.
                    # returning to avoid further execution when different values are specified for -ErrorAction parameter
                    return
                }
            }

            if (-not $Author) {
                if ($script:IsWindows) {
                    $Author = (Get-EnvironmentVariable -Name 'USERNAME' -Target $script:EnvironmentVariableTarget.Process -ErrorAction SilentlyContinue)
                }
                else {
                    $Author = $env:USER
                }
            }

            if (-not $Guid) {
                $Guid = [System.Guid]::NewGuid()
            }
        }
        else {
            # Use existing values if any of the parameters are not specified during Update-ScriptFileInfo
            if (-not $Version -and $psscriptInfo.Version) {
                $Version = $psscriptInfo.Version
            }

            if (-not $Guid -and $psscriptInfo.Guid) {
                $Guid = $psscriptInfo.Guid
            }

            if (-not $Author -and $psscriptInfo.Author) {
                $Author = $psscriptInfo.Author
            }

            if (-not $CompanyName -and $psscriptInfo.CompanyName) {
                $CompanyName = $psscriptInfo.CompanyName
            }

            if (-not $Copyright -and $psscriptInfo.Copyright) {
                $Copyright = $psscriptInfo.Copyright
            }

            if (-not $RequiredModules -and $psscriptInfo.RequiredModules) {
                $RequiredModules = $psscriptInfo.RequiredModules
            }

            if (-not $ExternalModuleDependencies -and $psscriptInfo.ExternalModuleDependencies) {
                $ExternalModuleDependencies = $psscriptInfo.ExternalModuleDependencies
            }

            if (-not $RequiredScripts -and $psscriptInfo.RequiredScripts) {
                $RequiredScripts = $psscriptInfo.RequiredScripts
            }

            if (-not $ExternalScriptDependencies -and $psscriptInfo.ExternalScriptDependencies) {
                $ExternalScriptDependencies = $psscriptInfo.ExternalScriptDependencies
            }

            if (-not $Tags -and $psscriptInfo.Tags) {
                $Tags = $psscriptInfo.Tags
            }

            if (-not $ProjectUri -and $psscriptInfo.ProjectUri) {
                $ProjectUri = $psscriptInfo.ProjectUri
            }

            if (-not $LicenseUri -and $psscriptInfo.LicenseUri) {
                $LicenseUri = $psscriptInfo.LicenseUri
            }

            if (-not $IconUri -and $psscriptInfo.IconUri) {
                $IconUri = $psscriptInfo.IconUri
            }

            if (-not $ReleaseNotes -and $psscriptInfo.ReleaseNotes) {
                $ReleaseNotes = $psscriptInfo.ReleaseNotes
            }

            if (-not $PrivateData -and $psscriptInfo.PrivateData) {
                $PrivateData = $psscriptInfo.PrivateData
            }
        }

        $params = @{
            Version                    = $Version
            Author                     = $Author
            Guid                       = $Guid
            CompanyName                = $CompanyName
            Copyright                  = $Copyright
            ExternalModuleDependencies = $ExternalModuleDependencies
            RequiredScripts            = $RequiredScripts
            ExternalScriptDependencies = $ExternalScriptDependencies
            Tags                       = $Tags
            ProjectUri                 = $ProjectUri
            LicenseUri                 = $LicenseUri
            IconUri                    = $IconUri
            ReleaseNotes               = $ReleaseNotes
            PrivateData                = $PrivateData
        }

        # Ensure no fields contain '<#' or '#>' (would break comment section)
        if (-not (Validate-ScriptFileInfoParameters -parameters $params)) {
            return
        }

        if ("$Description" -match '<#' -or "$Description" -match '#>') {
            $message = $LocalizedData.InvalidParameterValue -f ($Description, 'Description')
            Write-Error -Message $message -ErrorId 'InvalidParameterValue' -Category InvalidArgument

            return
        }

        $PSScriptInfoString = Get-PSScriptInfoString @params

        $requiresStrings = Get-RequiresString -RequiredModules $RequiredModules

        $DescriptionValue = if ($Description) { $Description } else { $psscriptInfo.Description }
        $ScriptCommentHelpInfoString = Get-ScriptCommentHelpInfoString -Description $DescriptionValue

        $ScriptMetadataString = $PSScriptInfoString
        $ScriptMetadataString += "`r`n"

        if ("$requiresStrings".Trim()) {
            $ScriptMetadataString += "`r`n"
            $ScriptMetadataString += $requiresStrings -join "`r`n"
            $ScriptMetadataString += "`r`n"
        }

        $ScriptMetadataString += "`r`n"
        $ScriptMetadataString += $ScriptCommentHelpInfoString
        $ScriptMetadataString += "`r`nParam()`r`n`r`n"

        $tempScriptFilePath = Microsoft.PowerShell.Management\Join-Path -Path $script:TempPath -ChildPath "$(Get-Random).ps1"

        try {
            # First create a new script file with new script metadata to ensure that updated values are valid.
            Microsoft.PowerShell.Management\Set-Content -Value $ScriptMetadataString -Path $tempScriptFilePath -Force -WhatIf:$false -Confirm:$false

            $scriptInfo = Test-ScriptFileInfo -Path $tempScriptFilePath

            if (-not $scriptInfo) {
                # Above Test-ScriptFileInfo cmdlet writes the error
                return
            }

            $scriptFileContents = Microsoft.PowerShell.Management\Get-Content -LiteralPath $scriptFilePath

            # If -Force is specified and script file doesnt have a valid PSScriptInfo
            # Prepend the PSScriptInfo and Check if the Test-ScriptFileInfo returns a valid script info without any errors
            if ($Force -and -not $psscriptInfo) {
                # Add the script file contents to the temp file with script metadata
                Microsoft.PowerShell.Management\Set-Content -LiteralPath $tempScriptFilePath `
                    -Value $ScriptMetadataString, $scriptFileContents `
                    -Force `
                    -WhatIf:$false `
                    -Confirm:$false

                $tempScriptInfo = $null
                try {
                    $tempScriptInfo = Test-ScriptFileInfo -LiteralPath $tempScriptFilePath
                }
                catch {
                    $errorMessage = ($LocalizedData.UnableToAddPSScriptInfo -f $scriptFilePath)
                    ThrowError  -ExceptionName 'System.InvalidOperationException' `
                        -ExceptionMessage $errorMessage `
                        -ErrorId 'UnableToAddPSScriptInfo' `
                        -CallerPSCmdlet $PSCmdlet `
                        -ExceptionObject $scriptFilePath `
                        -ErrorCategory InvalidOperation
                    return
                }
            }
            else {
                [System.Management.Automation.Language.Token[]]$tokens = $null;
                [System.Management.Automation.Language.ParseError[]]$errors = $null;
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptFilePath, ([ref]$tokens), ([ref]$errors))

                # Update PSScriptInfo and #Requires
                $CommentTokens = $tokens | Microsoft.PowerShell.Core\Where-Object { $_.Kind -eq 'Comment' }

                $psscriptInfoComments = $CommentTokens |
                Microsoft.PowerShell.Core\Where-Object { $_.Extent.Text -match "<#PSScriptInfo" } |
                Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

                if (-not $psscriptInfoComments) {
                    $errorMessage = ($LocalizedData.MissingPSScriptInfo -f $scriptFilePath)
                    ThrowError  -ExceptionName "System.ArgumentException" `
                        -ExceptionMessage $errorMessage `
                        -ErrorId "MissingPSScriptInfo" `
                        -CallerPSCmdlet $PSCmdlet `
                        -ExceptionObject $scriptFilePath `
                        -ErrorCategory InvalidArgument
                    return
                }

                # Ensure that metadata is replaced at the correct location and should not corrupt the existing script file.

                # Remove the lines between below lines and add the new PSScriptInfo and new #Requires statements
                # ($psscriptInfoComments.Extent.StartLineNumber - 1)
                # ($psscriptInfoComments.Extent.EndLineNumber - 1)
                $tempContents = @()
                $IsNewPScriptInfoAdded = $false

                for ($i = 0; $i -lt $scriptFileContents.Count; $i++) {
                    $line = $scriptFileContents[$i]
                    if (($i -ge ($psscriptInfoComments.Extent.StartLineNumber - 1)) -and
                        ($i -le ($psscriptInfoComments.Extent.EndLineNumber - 1))) {
                        if (-not $IsNewPScriptInfoAdded) {
                            $PSScriptInfoString = $PSScriptInfoString.TrimStart()
                            $requiresStrings = $requiresStrings.TrimEnd()

                            $tempContents += "$PSScriptInfoString `r`n`r`n$($requiresStrings -join "`r`n")"
                            $IsNewPScriptInfoAdded = $true
                        }
                    }
                    elseif ($line -notmatch "\s*#Requires\s+-Module") {
                        # Add the existing lines if they are not part of PSScriptInfo comment or not containing #Requires -Module statements.
                        $tempContents += $line
                    }
                }

                Microsoft.PowerShell.Management\Set-Content -Value $tempContents -Path $tempScriptFilePath -Force -WhatIf:$false -Confirm:$false

                $scriptInfo = Test-ScriptFileInfo -Path $tempScriptFilePath

                if (-not $scriptInfo) {
                    # Above Test-ScriptFileInfo cmdlet writes the error
                    return
                }

                # Now update the Description value if a new is specified.
                if ($Description) {
                    $tempContents = @()
                    $IsDescriptionAdded = $false

                    $IsDescriptionBeginFound = $false
                    $scriptFileContents = Microsoft.PowerShell.Management\Get-Content -Path $tempScriptFilePath

                    for ($i = 0; $i -lt $scriptFileContents.Count; $i++) {
                        $line = $scriptFileContents[$i]

                        if (-not $IsDescriptionAdded) {
                            if (-not $IsDescriptionBeginFound) {
                                if ($line.Trim().StartsWith(".DESCRIPTION", [System.StringComparison]::OrdinalIgnoreCase)) {
                                    $IsDescriptionBeginFound = $true
                                }
                                else {
                                    $tempContents += $line
                                }
                            }
                            else {
                                # Description begin has found
                                # Skip the old description lines until description end is found

                                if ($line.Trim().StartsWith("#>", [System.StringComparison]::OrdinalIgnoreCase) -or
                                    $line.Trim().StartsWith(".", [System.StringComparison]::OrdinalIgnoreCase)) {
                                    $tempContents += ".DESCRIPTION `r`n$($Description -join "`r`n")`r`n"
                                    $IsDescriptionAdded = $true
                                    $tempContents += $line
                                }
                            }
                        }
                        else {
                            $tempContents += $line
                        }
                    }

                    Microsoft.PowerShell.Management\Set-Content -Value $tempContents -Path $tempScriptFilePath -Force -WhatIf:$false -Confirm:$false

                    $scriptInfo = Test-ScriptFileInfo -Path $tempScriptFilePath

                    if (-not $scriptInfo) {
                        # Above Test-ScriptFileInfo cmdlet writes the error
                        return
                    }
                }
            }

            if ($Force -or $PSCmdlet.ShouldProcess($scriptFilePath, ($LocalizedData.UpdateScriptFileInfowhatIfMessage -f $Path) )) {
                Microsoft.PowerShell.Management\Copy-Item -Path $tempScriptFilePath -Destination $scriptFilePath -Force -WhatIf:$false -Confirm:$false

                if ($PassThru) {
                    $ScriptMetadataString
                }
            }
        }
        finally {
            Microsoft.PowerShell.Management\Remove-Item -Path $tempScriptFilePath -Force -WhatIf:$false -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }
}
