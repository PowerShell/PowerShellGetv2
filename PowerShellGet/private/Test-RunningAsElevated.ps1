function Test-RunningAsElevated
# Check if current user is running with elevated privileges
{
    [CmdletBinding()]
    [OutputType([bool])]
    Param()

    if(-not $script:IsRunningAsElevatedTested -and $script:IsRunningAsElevated)
    {
        if($script:IsWindows)
        {
            $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
            $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
            $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
            $script:IsRunningAsElevated = $prp.IsInRole($adm)
        }
        elseif($script:IsCoreCLR)
        {
            # Permission models on *nix can be very complex, to the point that you could never possibly guess without simply trying what you need to try;
            # This is totally different from Windows where you can know what you can or cannot do with/without admin rights.
            $script:IsRunningAsElevated = $true
        }

        $script:IsRunningAsElevatedTested = $true
    }

    return $script:IsRunningAsElevated
}
