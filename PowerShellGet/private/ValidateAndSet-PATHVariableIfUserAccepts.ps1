function ValidateAndSet-PATHVariableIfUserAccepts
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $Scope,

        [Parameter(Mandatory=$true)]
        [string]
        $ScopePath,

        [Parameter()]
        [Switch]
        $NoPathUpdate,

        [Parameter()]
        [Switch]
        $Force,

        [Parameter()]
        $Request
    )

    if(-not $script:IsWindows)
    {
        return
    }

    Set-PSGetSettingsVariable

    # Check and add the scope path to PATH environment variable if USER accepts the prompt.
    if($Scope -eq 'AllUsers')
    {
        $envVariableTarget = $script:EnvironmentVariableTarget.Machine
        $scriptPATHPromptQuery=$LocalizedData.ScriptPATHPromptQuery -f $ScopePath
        $scopeSpecificKey = 'AllUsersScope_AllowPATHChangeForScripts'
    }
    else
    {
        $envVariableTarget = $script:EnvironmentVariableTarget.User
        $scriptPATHPromptQuery=$LocalizedData.ScriptPATHPromptQuery -f $ScopePath
        $scopeSpecificKey = 'CurrentUserScope_AllowPATHChangeForScripts'
    }

    $AlreadyPromptedForScope = $script:PSGetSettings.Contains($scopeSpecificKey)
    Write-Debug "Already prompted for the current scope:$AlreadyPromptedForScope"

    if(-not $AlreadyPromptedForScope)
    {
        # Read the file contents once again to ensure that it was not set in another PowerShell Session
        Set-PSGetSettingsVariable -Force

        $AlreadyPromptedForScope = $script:PSGetSettings.Contains($scopeSpecificKey)
        Write-Debug "After reading contents of PowerShellGetSettings.xml file, the Already prompted for the current scope:$AlreadyPromptedForScope"

        if($AlreadyPromptedForScope)
        {
            return
        }

        $userResponse = $false

        if(-not $NoPathUpdate)
        {
            $scopePathEndingWithBackSlash = "$scopePath\"

            # Check and add the $scopePath to $env:Path value
            if( (($env:PATH -split ';') -notcontains $scopePath) -and
                (($env:PATH -split ';') -notcontains $scopePathEndingWithBackSlash))
            {
                if($Force)
                {
                    $userResponse = $true
                }
                else
                {
                    $scriptPATHPromptCaption = $LocalizedData.ScriptPATHPromptCaption

                    if($Request)
                    {
                        $userResponse = $Request.ShouldContinue($scriptPATHPromptQuery, $scriptPATHPromptCaption)
                    }
                    else
                    {
                        $userResponse = $PSCmdlet.ShouldContinue($scriptPATHPromptQuery, $scriptPATHPromptCaption)
                    }
                }

                if($userResponse)
                {
                    $currentPATHValue = Get-EnvironmentVariable -Name 'PATH' -Target $envVariableTarget

                    if((($currentPATHValue -split ';') -notcontains $scopePath) -and
                       (($currentPATHValue -split ';') -notcontains $scopePathEndingWithBackSlash))
                    {
                        # To ensure that the installed script is immediately usable,
                        # we need to add the scope path to the PATH enviroment variable.
                        Set-EnvironmentVariable -Name 'PATH' `
                                                -Value "$currentPATHValue;$scopePath" `
                                                -Target $envVariableTarget

                        Write-Verbose ($LocalizedData.AddedScopePathToPATHVariable -f ($scopePath,$Scope))
                    }

                    # Process specific PATH
                    # Check and add the $scopePath to $env:Path value of current process
                    # so that installed scripts can be used in the current process.
                    $target = $script:EnvironmentVariableTarget.Process
                    $currentPATHValue = Get-EnvironmentVariable -Name 'PATH' -Target $target

                    if((($currentPATHValue -split ';') -notcontains $scopePath) -and
                       (($currentPATHValue -split ';') -notcontains $scopePathEndingWithBackSlash))
                    {
                        # To ensure that the installed script is immediately usable,
                        # we need to add the scope path to the PATH enviroment variable.
                        Set-EnvironmentVariable -Name 'PATH' `
                                                -Value "$currentPATHValue;$scopePath" `
                                                -Target $target

                        Write-Verbose ($LocalizedData.AddedScopePathToProcessSpecificPATHVariable -f ($scopePath,$Scope))
                    }
                }
            }
        }

        # Add user's response to the PowerShellGet.settings file
        $script:PSGetSettings[$scopeSpecificKey] = $userResponse

        Save-PSGetSettings
    }
}