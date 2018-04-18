function Send-EnvironmentChangeMessage
# Broadcast the Environment variable changes, so that other processes pick changes to Environment variables without having to reboot or logoff/logon.
{
    if($Script:IsWindows)
    {
        if (-not ('Microsoft.PowerShell.Commands.PowerShellGet.Win32.NativeMethods' -as [type]))
        {
            Add-Type -Namespace Microsoft.PowerShell.Commands.PowerShellGet.Win32 `
                     -Name NativeMethods `
                     -MemberDefinition @'
                        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
                        public static extern IntPtr SendMessageTimeout(
                            IntPtr hWnd,
                            uint Msg,
                            UIntPtr wParam,
                            string lParam,
                            uint fuFlags,
                            uint uTimeout,
                            out UIntPtr lpdwResult);
'@
        }

        $HWND_BROADCAST = [System.IntPtr]0xffff
        $WM_SETTINGCHANGE = 0x1a
        $result = [System.UIntPtr]::zero

        $returnValue = [Microsoft.PowerShell.Commands.PowerShellGet.Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST,
                                                                                                            $WM_SETTINGCHANGE,
                                                                                                            [System.UIntPtr]::Zero,
                                                                                                            'Environment',
                                                                                                            2,
                                                                                                            5000,
                                                                                                            [ref]$result)
        if($returnValue)
        {
            Write-Verbose -Message $LocalizedData.SentEnvironmentVariableChangeMessage
        }
        else
        {
            Write-Warning -Message $LocalizedData.UnableToSendEnvironmentVariableChangeMessage
        }
    }
}
