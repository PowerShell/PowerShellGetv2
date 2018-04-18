function Get-EnvironmentVariable
{
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [parameter(Mandatory = $true)]
        [int]
        $Target
    )

    if ($Target -eq $script:EnvironmentVariableTarget.Process)
    {
        return [System.Environment]::GetEnvironmentVariable($Name)
    }
    elseif ($Target -eq $script:EnvironmentVariableTarget.Machine)
    {
        if ($Name -eq "path")
        {
            # if we need the path environment variable, we need it un-expanded, otherwise
            # when writing it back, we would loose all the variables like %systemroot% in it.
            # We use the Win32 API directly using DoNotExpandEnvironmentNames
            # It is unclear whether any code calling this function for %path% needs the expanded version of %path%
            # There are currently no tests for this code
            # Microsoft.PowerShell.Management\Get-ItemProperty is passed through to the PowerShell Registry provider
            # which currently doesn't seem to support anything like: DoNotExpandEnvironmentNames
            $hklmHive = [Microsoft.Win32.Registry]::LocalMachine
            $EnvRegKey = $hklmHive.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment", $FALSE)
            $itemPropertyValue = $EnvRegKey.GetValue($Name, "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            return $itemPropertyValue
        }
        else
        {
            $itemPropertyValue = Microsoft.PowerShell.Management\Get-ItemProperty -Path $script:SystemEnvironmentKey -Name $Name -ErrorAction SilentlyContinue

            if($itemPropertyValue)
            {
                return $itemPropertyValue.$Name
            }
        }
    }
    elseif ($Target -eq $script:EnvironmentVariableTarget.User)
    {
        $itemPropertyValue = Microsoft.PowerShell.Management\Get-ItemProperty -Path $script:UserEnvironmentKey -Name $Name -ErrorAction SilentlyContinue

        if($itemPropertyValue)
        {
            return $itemPropertyValue.$Name
        }
    }
}