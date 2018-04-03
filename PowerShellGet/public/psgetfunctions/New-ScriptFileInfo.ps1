function New-ScriptFileInfo
{
    <#
    .ExternalHelp PSModule-help.xml
    #>
    [CmdletBinding(PositionalBinding=$false,
                   SupportsShouldProcess=$true,
                   HelpUri='https://go.microsoft.com/fwlink/?LinkId=619792')]
    Param
    (
        [Parameter(Mandatory=$false,
                   Position=0,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Version,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Author,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Guid]
        $Guid,

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

    Process
    {
        if($Path)
        {
            if(-not $Path.EndsWith('.ps1', [System.StringComparison]::OrdinalIgnoreCase))
            {
                $errorMessage = ($LocalizedData.InvalidScriptFilePath -f $Path)
                ThrowError  -ExceptionName 'System.ArgumentException' `
                            -ExceptionMessage $errorMessage `
                            -ErrorId 'InvalidScriptFilePath' `
                            -CallerPSCmdlet $PSCmdlet `
                            -ExceptionObject $Path `
                            -ErrorCategory InvalidArgument
                return
            }

            if(-not $Force -and (Microsoft.PowerShell.Management\Test-Path -Path $Path))
            {
                $errorMessage = ($LocalizedData.ScriptFileExist -f $Path)
                ThrowError  -ExceptionName 'System.ArgumentException' `
                            -ExceptionMessage $errorMessage `
                            -ErrorId 'ScriptFileExist' `
                            -CallerPSCmdlet $PSCmdlet `
                            -ExceptionObject $Path `
                            -ErrorCategory InvalidArgument
                return
            }
        }
        elseif(-not $PassThru)
        {
            ThrowError  -ExceptionName 'System.ArgumentException' `
                        -ExceptionMessage $LocalizedData.MissingTheRequiredPathOrPassThruParameter `
                        -ErrorId 'MissingTheRequiredPathOrPassThruParameter' `
                        -CallerPSCmdlet $PSCmdlet `
                        -ErrorCategory InvalidArgument
            return
        }

        if(-not $Version)
        {
            $Version = '1.0'
        }
        else
        {
            $result = ValidateAndGet-VersionPrereleaseStrings -Version $Version -CallerPSCmdlet $PSCmdlet
            if (-not $result)
            {
                # ValidateAndGet-VersionPrereleaseStrings throws the error.
                # returning to avoid further execution when different values are specified for -ErrorAction parameter
                return
            }
        }

        if(-not $Author)
        {
            if($script:IsWindows)
            {
                $Author = (Get-EnvironmentVariable -Name 'USERNAME' -Target $script:EnvironmentVariableTarget.Process -ErrorAction SilentlyContinue)
            }
            else
            {
                $Author = $env:USER
            }
        }

        if(-not $Guid)
        {
            $Guid = [System.Guid]::NewGuid()
        }

        $params = @{
            Version = $Version
            Author = $Author
            Guid = $Guid
            CompanyName = $CompanyName
            Copyright = $Copyright
            ExternalModuleDependencies = $ExternalModuleDependencies
            RequiredScripts = $RequiredScripts
            ExternalScriptDependencies = $ExternalScriptDependencies
            Tags = $Tags
            ProjectUri = $ProjectUri
            LicenseUri = $LicenseUri
            IconUri = $IconUri
            ReleaseNotes = $ReleaseNotes
			PrivateData = $PrivateData
        }

        if(-not (Validate-ScriptFileInfoParameters -parameters $params))
        {
            return
        }

        if("$Description" -match '<#' -or "$Description" -match '#>')
        {
            $message = $LocalizedData.InvalidParameterValue -f ($Description, 'Description')
            Write-Error -Message $message -ErrorId 'InvalidParameterValue' -Category InvalidArgument

            return
        }

        $PSScriptInfoString = Get-PSScriptInfoString @params

        $requiresStrings = Get-RequiresString -RequiredModules $RequiredModules

        $ScriptCommentHelpInfoString = Get-ScriptCommentHelpInfoString -Description $Description

        $ScriptMetadataString = $PSScriptInfoString
        $ScriptMetadataString += "`r`n"

        if("$requiresStrings".Trim())
        {
            $ScriptMetadataString += "`r`n"
            $ScriptMetadataString += $requiresStrings -join "`r`n"
            $ScriptMetadataString += "`r`n"
        }

        $ScriptMetadataString += "`r`n"
        $ScriptMetadataString += $ScriptCommentHelpInfoString
        $ScriptMetadataString += "Param()`r`n`r`n"

        $tempScriptFilePath = Microsoft.PowerShell.Management\Join-Path -Path $script:TempPath -ChildPath "$(Get-Random).ps1"

        try
        {
            Microsoft.PowerShell.Management\Set-Content -Value $ScriptMetadataString -Path $tempScriptFilePath -Force -WhatIf:$false -Confirm:$false

            $scriptInfo = Test-ScriptFileInfo -Path $tempScriptFilePath

            if(-not $scriptInfo)
            {
                # Above Test-ScriptFileInfo cmdlet writes the errors
                return
            }

    	    if($Path -and ($Force -or $PSCmdlet.ShouldProcess($Path, ($LocalizedData.NewScriptFileInfowhatIfMessage -f $Path) )))
    	    {
                Microsoft.PowerShell.Management\Copy-Item -Path $tempScriptFilePath -Destination $Path -Force -WhatIf:$false -Confirm:$false
            }

            if($PassThru)
            {
                Write-Output -InputObject $ScriptMetadataString
            }
        }
        finally
        {
            Microsoft.PowerShell.Management\Remove-Item -Path $tempScriptFilePath -Force -WhatIf:$false -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }
}