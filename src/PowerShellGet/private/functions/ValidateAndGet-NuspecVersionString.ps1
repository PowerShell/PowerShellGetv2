function ValidateAndGet-NuspecVersionString
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Version
    )

    $versionPattern = '^((?<MinRule>[\[\(])?((?<MinVersion>[^:\(\[\)\]\,]+))?((?<Comma>[\,])?(?<MaxVersion>[^:\(\[\)\]\,]+)?)?(?<MaxRule>[\]\)])?)$'
    $VersionInfo = @{}

    if ( -not ($Version -match $versionPattern))
    {
        $message = $LocalizedData.FailedToParseRequiredScriptsVersion -f ('Invalid Version format', $Version, $LocalizedData.RequiredScriptVersoinFormat)
        Write-Verbose $message
        ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId "UnableToResolveScriptDependency" `
                    -CallerPSCmdlet $CallerPSCmdlet `
                    -ErrorCategory InvalidOperation
    }

    if ($Matches.Keys -Contains 'MinRule' -xor $Matches.Keys -Contains 'MaxRule')
    {
        $message = $LocalizedData.FailedToParseRequiredScriptsVersion -f ('Minimum and Maximum inclusive/exclusive condition mismatch', $Version, $LocalizedData.RequiredScriptVersoinFormat)
        Write-Verbose $message
        ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId "UnableToResolveScriptDependency" `
                    -CallerPSCmdlet $CallerPSCmdlet `
                    -ErrorCategory InvalidOperation
    }

    if (-not ($Matches.Keys -Contains 'MinVersion' -or $Matches.Keys -Contains 'MaxVersion'))
    {
        $message = $LocalizedData.FailedToParseRequiredScriptsVersion -f ('No version.', $Version, $LocalizedData.RequiredScriptVersoinFormat)
        Write-Verbose $message
        ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId "UnableToResolveScriptDependency" `
                    -CallerPSCmdlet $CallerPSCmdlet `
                    -ErrorCategory InvalidOperation
    }

    if ((-not ($Matches.Keys -Contains 'MinRule' -and $Matches.Keys -Contains 'MaxRule')) -and $Matches.Keys -Contains 'Comma')
    {
        $message = $LocalizedData.FailedToParseRequiredScriptsVersion -f ('Invalid version format', $Version, $LocalizedData.RequiredScriptVersoinFormat)
        Write-Verbose $message
        ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId "UnableToResolveScriptDependency" `
                    -CallerPSCmdlet $CallerPSCmdlet `
                    -ErrorCategory InvalidOperation
    }

    if ($Matches.Keys -Contains 'MaxRule' -and -not ($Matches['MaxRule'] -eq ']') )
    {
        $message = $LocalizedData.FailedToParseRequiredScriptsVersion -f ('Maximum version condition should be inclusive', $Version, $LocalizedData.RequiredScriptVersoinFormat)
        Write-Verbose $message
        ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId "UnableToResolveScriptDependency" `
                    -CallerPSCmdlet $CallerPSCmdlet `
                    -ErrorCategory InvalidOperation
    }

    if ($Matches.Keys -Contains 'MinVersion' -and $Matches.Keys -Contains 'MaxVersion')
    {
        if ($Matches.Keys -Contains 'MinRule' -and $Matches.Keys -Contains 'MaxRule')
        {
            if ($Matches['MinRule'] -eq '[')
            {
                $VersionInfo['MinimumVersion'] = $Matches['MinVersion']
                $VersionInfo['MaximumVersion'] = $Matches['MaxVersion']
            }
            else
            {
                $message = $LocalizedData.FailedToParseRequiredScriptsVersion -f ('Minimum version condition should be inclusive', $Version, $LocalizedData.RequiredScriptVersoinFormat)
                Write-Verbose $message
                ThrowError -ExceptionName "System.ArgumentException" `
                            -ExceptionMessage $message `
                            -ErrorId "UnableToResolveScriptDependency" `
                            -CallerPSCmdlet $CallerPSCmdlet `
                            -ErrorCategory InvalidOperation
            }
        }
        else
        {
            $message = $LocalizedData.FailedToParseRequiredScriptsVersion -f ('Minimum and Maximum inclusive/exclusive condition mismatch', $Version, $LocalizedData.RequiredScriptVersoinFormat)
            Write-Verbose $message
            ThrowError -ExceptionName "System.ArgumentException" `
                        -ExceptionMessage $message `
                        -ErrorId "UnableToResolveScriptDependency" `
                        -CallerPSCmdlet $CallerPSCmdlet `
                        -ErrorCategory InvalidOperation
        }

        return $VersionInfo
    }

    if ($Matches.Keys -Contains 'MinVersion')
    {
        if ($Matches.Keys -Contains 'MinRule' -and $Matches.Keys -Contains 'MaxRule')
        {
            if (($Matches['MinRule'] -eq '[') -and ($Matches['MaxRule'] -eq ']'))
            {
                $VersionInfo['RequiredVersion'] = $Matches['MinVersion']
                return $VersionInfo
            }
        }
        else
        {
            $VersionInfo['MinimumVersion'] = $Matches['MinVersion']
            return $VersionInfo
        }

        $message = $LocalizedData.FailedToParseRequiredScriptsVersion -f ("Minimum and Maximum version rules should be inclusive for 'RequiredVersion'", $Version, $LocalizedData.RequiredScriptVersoinFormat)
        Write-Verbose $message
        ThrowError -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $message `
                    -ErrorId "UnableToResolveScriptDependency" `
                    -CallerPSCmdlet $CallerPSCmdlet `
                    -ErrorCategory InvalidOperation
    }

    if ($Matches.Keys -Contains 'MaxVersion')
    {
        $VersionInfo['MaximumVersion'] = $Matches['MaxVersion']
        return $VersionInfo
    }

    $message = $LocalizedData.FailedToParseRequiredScriptsVersion -f ("Failed to parse version string", $Version, $LocalizedData.RequiredScriptVersoinFormat)
    Write-Verbose $message
    ThrowError -ExceptionName "System.ArgumentException" `
                -ExceptionMessage $message `
                -ErrorId "UnableToResolveScriptDependency" `
                -CallerPSCmdlet $CallerPSCmdlet `
                -ErrorCategory InvalidOperation
}