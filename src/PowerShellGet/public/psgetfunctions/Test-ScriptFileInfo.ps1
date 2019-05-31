function Test-ScriptFileInfo {
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(PositionalBinding = $false,
        DefaultParameterSetName = 'PathParameterSet',
        HelpUri = 'https://go.microsoft.com/fwlink/?LinkId=619791')]
    Param
    (
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'PathParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'LiteralPathParameterSet')]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string]
        $LiteralPath
    )

    Process {
        $scriptFilePath = $null
        if ($Path) {
            $scriptFilePath = Resolve-PathHelper -Path $Path -CallerPSCmdlet $PSCmdlet | Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

            if (-not $scriptFilePath -or -not (Microsoft.PowerShell.Management\Test-Path -Path $scriptFilePath -PathType Leaf)) {
                $errorMessage = ($LocalizedData.PathNotFound -f $Path)
                ThrowError  -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $errorMessage `
                    -ErrorId "PathNotFound" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ExceptionObject $Path `
                    -ErrorCategory InvalidArgument
                return
            }
        }
        else {
            $scriptFilePath = Resolve-PathHelper -Path $LiteralPath -IsLiteralPath -CallerPSCmdlet $PSCmdlet | Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

            if (-not $scriptFilePath -or -not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $scriptFilePath -PathType Leaf)) {
                $errorMessage = ($LocalizedData.PathNotFound -f $LiteralPath)
                ThrowError  -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $errorMessage `
                    -ErrorId "PathNotFound" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ExceptionObject $LiteralPath `
                    -ErrorCategory InvalidArgument
                return
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

        $PSScriptInfo = New-PSScriptInfoObject -Path $scriptFilePath

        [System.Management.Automation.Language.Token[]]$tokens = $null;
        [System.Management.Automation.Language.ParseError[]]$errors = $null;
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptFilePath, ([ref]$tokens), ([ref]$errors))


        $notSupportedOnNanoErrorIds = @('WorkflowNotSupportedInPowerShellCore',
            'ConfigurationNotSupportedInPowerShellCore')
        $errorsAfterSkippingOneCoreErrors = $errors | Microsoft.PowerShell.Core\Where-Object { $notSupportedOnNanoErrorIds -notcontains $_.ErrorId }

        if ($errorsAfterSkippingOneCoreErrors) {
            $errorMessage = ($LocalizedData.ScriptParseError -f $scriptFilePath)
            ThrowError  -ExceptionName "System.ArgumentException" `
                -ExceptionMessage $errorMessage `
                -ErrorId "ScriptParseError" `
                -CallerPSCmdlet $PSCmdlet `
                -ExceptionObject $errorsAfterSkippingOneCoreErrors `
                -ErrorCategory InvalidArgument
            return
        }

        if ($ast) {
            # Get the block/group comment beginning with <#PSScriptInfo
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

            # $psscriptInfoComments.Text will have the multiline PSScriptInfo comment,
            # split them into multiple lines to parse for the PSScriptInfo metadata properties.
            $commentLines = [System.Text.RegularExpressions.Regex]::Split($psscriptInfoComments.Text, "[\r\n]")

            $KeyName = $null
            $Value = ""

            # PSScriptInfo comment will be in following format:
            <#PSScriptInfo

                .VERSION 1.0

                .GUID 544238e3-1751-4065-9227-be105ff11636

                .AUTHOR manikb

                .COMPANYNAME Microsoft Corporation

                .COPYRIGHT (c) 2015 Microsoft Corporation. All rights reserved.

                .TAGS Tag1 Tag2 Tag3

                .LICENSEURI https://contoso.com/License

                .PROJECTURI https://contoso.com/

                .ICONURI https://contoso.com/Icon

                .EXTERNALMODULEDEPENDENCIES ExternalModule1

                .REQUIREDSCRIPTS Start-WFContosoServer,Stop-ContosoServerScript

                .EXTERNALSCRIPTDEPENDENCIES Stop-ContosoServerScript

                .RELEASENOTES
                contoso script now supports following features
                Feature 1
                Feature 2
                Feature 3
                Feature 4
                Feature 5

                #>
            # If comment line count is not more than two, it doesn't have the any metadata property
            # First line is <#PSScriptInfo
            # Last line #>
            #
            if ($commentLines.Count -gt 2) {
                for ($i = 1; $i -lt ($commentLines.count - 1); $i++) {
                    $line = $commentLines[$i]

                    if (-not $line) {
                        continue
                    }

                    # A line is starting with . conveys a new metadata property
                    # __NEWLINE__ is used for replacing the value lines while adding the value to $PSScriptInfo object
                    #
                    if ($line.trim().StartsWith('.')) {
                        $parts = $line.trim() -split '[.\s+]', 3 | Microsoft.PowerShell.Core\Where-Object { $_ }

                        if ($KeyName -and $Value) {
                            if ($keyName -eq $script:ReleaseNotes) {
                                $Value = $Value.Trim() -split '__NEWLINE__'
                            }
                            elseif ($keyName -eq $script:DESCRIPTION) {
                                $Value = $Value -split '__NEWLINE__'
                                $Value = ($Value -join "`r`n").Trim()
                            }
                            else {
                                $Value = $Value -split '__NEWLINE__' | Microsoft.PowerShell.Core\Where-Object { $_ }

                                if ($Value -and $Value.GetType().ToString() -eq "System.String") {
                                    $Value = $Value.Trim()
                                }
                            }

                            ValidateAndAdd-PSScriptInfoEntry -PSScriptInfo $PSScriptInfo `
                                -PropertyName $KeyName `
                                -PropertyValue $Value `
                                -CallerPSCmdlet $PSCmdlet
                        }

                        $KeyName = $null
                        $Value = ""

                        if ($parts.GetType().ToString() -eq "System.String") {
                            $KeyName = $parts
                        }
                        else {
                            $KeyName = $parts[0];
                            $Value = $parts[1]
                        }
                    }
                    else {
                        if ($Value) {
                            # __NEWLINE__ is used for replacing the value lines while adding the value to $PSScriptInfo object
                            $Value += '__NEWLINE__'
                        }

                        $Value += $line
                    }
                }

                if ($KeyName -and $Value) {
                    if ($keyName -eq $script:ReleaseNotes) {
                        $Value = $Value.Trim() -split '__NEWLINE__'
                    }
                    elseif ($keyName -eq $script:DESCRIPTION) {
                        $Value = $Value -split '__NEWLINE__'
                        $Value = ($Value -join "`r`n").Trim()
                    }
                    else {
                        $Value = $Value -split '__NEWLINE__' | Microsoft.PowerShell.Core\Where-Object { $_ }

                        if ($Value -and $Value.GetType().ToString() -eq "System.String") {
                            $Value = $Value.Trim()
                        }
                    }

                    ValidateAndAdd-PSScriptInfoEntry -PSScriptInfo $PSScriptInfo `
                        -PropertyName $KeyName `
                        -PropertyValue $Value `
                        -CallerPSCmdlet $PSCmdlet

                    $KeyName = $null
                    $Value = ""
                }
            }

            $helpContent = $ast.GetHelpContent()
            if ($helpContent -and $helpContent.Description) {
                ValidateAndAdd-PSScriptInfoEntry -PSScriptInfo $PSScriptInfo `
                    -PropertyName $script:DESCRIPTION `
                    -PropertyValue $helpContent.Description.Trim() `
                    -CallerPSCmdlet $PSCmdlet

            }

            # Handle RequiredModules
            if ((Microsoft.PowerShell.Utility\Get-Member -InputObject $ast -Name 'ScriptRequirements') -and
                $ast.ScriptRequirements -and
                (Microsoft.PowerShell.Utility\Get-Member -InputObject $ast.ScriptRequirements -Name 'RequiredModules') -and
                $ast.ScriptRequirements.RequiredModules) {
                ValidateAndAdd-PSScriptInfoEntry -PSScriptInfo $PSScriptInfo `
                    -PropertyName $script:RequiredModules `
                    -PropertyValue $ast.ScriptRequirements.RequiredModules `
                    -CallerPSCmdlet $PSCmdlet
            }

            # Get all defined functions and populate DefinedCommands, DefinedFunctions and DefinedWorkflows
            $allCommands = $ast.FindAll( { param($i) return ($i.GetType().Name -eq 'FunctionDefinitionAst') }, $true)

            if ($allCommands) {
                $allCommandNames = $allCommands | ForEach-Object { $_.Name } | Select-Object -Unique -ErrorAction Ignore
                ValidateAndAdd-PSScriptInfoEntry -PSScriptInfo $PSScriptInfo `
                    -PropertyName $script:DefinedCommands `
                    -PropertyValue $allCommandNames `
                    -CallerPSCmdlet $PSCmdlet

                $allFunctionNames = $allCommands | Where-Object { -not $_.IsWorkflow } | ForEach-Object { $_.Name } | Select-Object -Unique -ErrorAction Ignore
                ValidateAndAdd-PSScriptInfoEntry -PSScriptInfo $PSScriptInfo `
                    -PropertyName $script:DefinedFunctions `
                    -PropertyValue $allFunctionNames `
                    -CallerPSCmdlet $PSCmdlet


                $allWorkflowNames = $allCommands | Where-Object { $_.IsWorkflow } | ForEach-Object { $_.Name } | Select-Object -Unique -ErrorAction Ignore
                ValidateAndAdd-PSScriptInfoEntry -PSScriptInfo $PSScriptInfo `
                    -PropertyName $script:DefinedWorkflows `
                    -PropertyValue $allWorkflowNames `
                    -CallerPSCmdlet $PSCmdlet
            }
        }

        # Ensure that the script file has the required metadata properties.
        if (-not $PSScriptInfo.Version -or -not $PSScriptInfo.Guid -or -not $PSScriptInfo.Author -or -not $PSScriptInfo.Description) {
            $errorMessage = ($LocalizedData.MissingRequiredPSScriptInfoProperties -f $scriptFilePath)
            ThrowError  -ExceptionName "System.ArgumentException" `
                -ExceptionMessage $errorMessage `
                -ErrorId "MissingRequiredPSScriptInfoProperties" `
                -CallerPSCmdlet $PSCmdlet `
                -ExceptionObject $Path `
                -ErrorCategory InvalidArgument
            return
        }

        if ($PSScriptInfo.Version -match '-') {
            $result = ValidateAndGet-VersionPrereleaseStrings -Version $PSScriptInfo.Version  -CallerPSCmdlet $PSCmdlet
            if (-not $result) {
                # ValidateAndGet-VersionPrereleaseStrings throws the error.
                # returning to avoid further execution when different values are specified for -ErrorAction parameter
                return
            }
        }

        $PSScriptInfo = Get-OrderedPSScriptInfoObject -PSScriptInfo $PSScriptInfo

        return $PSScriptInfo
    }
}
