function Set-EnvironmentVariable
{
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [parameter()]
        [String]
        $Value,

        [parameter(Mandatory = $true)]
        [int]
        $Target
    )

    if ($Target -eq $script:EnvironmentVariableTarget.Process)
    {
        [System.Environment]::SetEnvironmentVariable($Name, $Value)

        return
    }
    elseif ($Target -eq $script:EnvironmentVariableTarget.Machine)
    {
        if ($Name.Length -ge $script:SystemEnvironmentVariableMaximumLength)
        {
            $message = $LocalizedData.InvalidEnvironmentVariableName -f ($Name, $script:SystemEnvironmentVariableMaximumLength)
            ThrowError -ExceptionName "System.ArgumentException" `
                        -ExceptionMessage $message `
                        -ErrorId 'InvalidEnvironmentVariableName' `
                        -ErrorCategory InvalidArgument `
                        -ExceptionObject $Name
            return
        }

        $Path = $script:SystemEnvironmentKey
    }
    elseif ($Target -eq $script:EnvironmentVariableTarget.User)
    {
        if ($Name.Length -ge $script:UserEnvironmentVariableMaximumLength)
        {
            $message = $LocalizedData.InvalidEnvironmentVariableName -f ($Name, $script:UserEnvironmentVariableMaximumLength)
            ThrowError -ExceptionName "System.ArgumentException" `
                        -ExceptionMessage $message `
                        -ErrorId 'InvalidEnvironmentVariableName' `
                        -ErrorCategory InvalidArgument `
                        -ExceptionObject $Name
            return
        }

        $Path = $script:UserEnvironmentKey
    }

    if (!$Value)
    {
        Microsoft.PowerShell.Management\Remove-ItemProperty $Path -Name $Name -ErrorAction SilentlyContinue
    }
    else
    {
        Microsoft.PowerShell.Management\Set-ItemProperty $Path -Name $Name -Value $Value
    }

    # Broadcast the Environment variable changes, so that other processes pick changes to Environment variables without having to reboot or logoff/logon.
    Send-EnvironmentChangeMessage
}
