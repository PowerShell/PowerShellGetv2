
function Get-CredsFromCredentialProvider {
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $SourceLocation,

        [Parameter()]
        [bool]
        $isRetry = $false
    )


    Write-Verbose "PowerShellGet Calling 'CallCredProvider' on $SourceLocation"
    # Example query: https://pkgs.dev.azure.com/onegettest/_packaging/onegettest/nuget/v2
    $regex = [regex] '^(\S*pkgs.dev.azure.com\S*/v2)$|^(\S*pkgs.visualstudio.com\S*/v2)$'

    if (!($SourceLocation -match $regex)) {
        return $null;
    }

    # Find credential provider
    # Option 1. Use env var 'NUGET_PLUGIN_PATHS' to find credential provider
    # See: https://docs.microsoft.com/en-us/nuget/reference/extensibility/nuget-cross-platform-plugins#plugin-installation-and-discovery
    # Note: OSX and Linux can only use option 1
    # Nuget prioritizes credential providers stored in the NUGET_PLUGIN_PATHS env var
    $credProviderPath = $null
    $defaultEnvPath = "NUGET_PLUGIN_PATHS"
    $nugetPluginPath = Get-Childitem env:$defaultEnvPath -ErrorAction SilentlyContinue
    $callDotnet = $true;

    if ($nugetPluginPath -and $nugetPluginPath.value) {
        # Obtion 1a) The environment variable NUGET_PLUGIN_PATHS should contain a full path to the executable,
        # .exe in the .NET Framework case and .dll in the .NET Core case
        $credProviderPath = $nugetPluginPath.value
        $extension = $credProviderPath.Substring($credProviderPath.get_Length() - 4)
        if ($extension -eq ".exe") {
            $callDotnet = $false
        }
    }
    else {
        # Option 1b) Find User-location - The NuGet Home location - %UserProfile%/.nuget/plugins/
        $path = "$($env:UserProfile)/.nuget/plugins/netcore/CredentialProvider.Microsoft/CredentialProvider.Microsoft.dll";

        if ($script:IsLinux -or $script:IsMacOS) {
            $path = "$($HOME)/.nuget/plugins/netcore/CredentialProvider.Microsoft/CredentialProvider.Microsoft.dll";
        }
        if (Test-Path $path -PathType Leaf) {
            $credProviderPath = $path
        }
    }

    # Option 2. Use Visual Studio path to find credential provider
    # Visual Studio comes pre-installed with the Azure Artifacts credential provider, so we'll search for that file using vswhere.exe
    # If Windows (ie not unix), we'll use vswhere.exe to find installation path of VsWhere
    # If credProviderPath is already set we can skip option 2
    if (!$credProviderPath -and $script:IsWindows) {
        if (${Env:ProgramFiles(x86)}) {
            $programFiles = ${Env:ProgramFiles(x86)}
        }
        elseif ($Env:Programfiles) {
            $programFiles = $Env:Programfiles
        }
        else {
            return $null
        }

        $vswhereExePath = "$($programFiles)\\Microsoft Visual Studio\\Installer\\vswhere.exe"
        if (!(Test-Path $vswhereExePath -PathType Leaf)) {
            return $null
        }

        $RedirectedOutput = Join-Path ([System.IO.Path]::GetTempPath()) 'RedirectedOutput.txt'
        Start-Process $vswhereExePath `
            -Wait `
            -WorkingDirectory $PSHOME `
            -RedirectStandardOutput $RedirectedOutput `
            -NoNewWindow

        $content = Get-Content $RedirectedOutput
        Remove-Item $RedirectedOutput -Force -Recurse -ErrorAction SilentlyContinue

        $vsInstallationPath = ""
        if ([System.Text.RegularExpressions.Regex]::IsMatch($content, "installationPath")) {
            $vsInstallationPath = [System.Text.RegularExpressions.Regex]::Match($content, "(?<=installationPath: ).*(?= installationVersion:)");
            $vsInstallationPath = $vsInstallationPath.ToString()
        }

        # Then use the installation path discovered by vswhere.exe to create the path to search for credential provider
        # ex: "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise" + "\Common7\IDE\CommonExtensions\Microsoft\NuGet\Plugins\CredentialProvider.Microsoft\CredentialProvider.Microsoft.exe"
        if ($vsInstallationPath) {
            $credProviderPath = ($vsInstallationPath + '\Common7\IDE\CommonExtensions\Microsoft\NuGet\Plugins\CredentialProvider.Microsoft\CredentialProvider.Microsoft.exe')
            if (!(Test-Path $credProviderPath -PathType Leaf)) {
                return $null
            }
            $callDotnet = $false;
        }
    }

    if (!(Test-Path $credProviderPath -PathType Leaf)) {
        return $null
    }

    $filename = $credProviderPath
    $arguments = "-U $SourceLocation"
    if ($callDotnet) {
        $filename = "dotnet"
        $arguments = "$credProviderPath $arguments"
    }
    $argumentsNoRetry = $arguments
    if ($isRetry) {
        $arguments = "$arguments -I";
        Write-Debug "Credential provider is re-running with -IsRetry"
    }

    Write-Debug "Credential provider path is: $credProviderPath"
    # Using a process to run CredentialProvider.Microsoft.exe with arguments -V verbose -U query (and -IsRetry when appropriate)
    # See: https://github.com/Microsoft/artifacts-credprovider
    Start-Process $filename -ArgumentList "$arguments -V minimal" `
        -Wait `
        -WorkingDirectory $PSHOME `
        -NoNewWindow

    # This should never run IsRetry
    $RedirectedOutput = Join-Path ([System.IO.Path]::GetTempPath()) 'RedirectedOutput.txt'
    Start-Process $filename -ArgumentList "$argumentsNoRetry -V verbose" `
        -Wait `
        -WorkingDirectory $PSHOME `
        -RedirectStandardOutput $RedirectedOutput `
        -NoNewWindow

    $content = Get-Content $RedirectedOutput
    Remove-Item $RedirectedOutput -Force -Recurse -ErrorAction SilentlyContinue

    $username = [System.Text.RegularExpressions.Regex]::Match($content, '(?<=Username: )\S*')
    $password = [System.Text.RegularExpressions.Regex]::Match($content, '(?<=Password: ).*')

    if ($username -and $password) {
        $secstr = ConvertTo-SecureString $password -AsPlainText -Force
        $credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr

        return $credential
    }

    return $null
}
