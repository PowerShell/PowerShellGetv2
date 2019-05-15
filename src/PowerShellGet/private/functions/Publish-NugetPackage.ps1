function Publish-NugetPackage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NupkgPath,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $true)]
        [string]$NugetApiKey,

        [Parameter(ParameterSetName = "UseNuget")]
        [string]$NugetExePath,

        [Parameter(ParameterSetName = "UseDotnetCli")]
        [switch]$UseDotnetCli
    )
    Set-StrictMode -Off

    Write-Verbose "Calling Publish-NugetPackage -NupkgPath $NupkgPath -Destination $Destination -NugetExePath $NugetExePath -UseDotnetCli:$UseDotnetCli"
    $Destination = $Destination.TrimEnd("\")

    if ($PSCmdlet.ParameterSetName -eq "UseNuget") {
        $ArgumentList = @('push')
        $ArgumentList += "`"$NupkgPath`""
        $ArgumentList += @('-source', "`"$Destination`"")
        $ArgumentList += @('-apikey', "`"$NugetApiKey`"")
        $ArgumentList += '-NonInteractive'

        #use processstartinfo and process objects here as it allows stderr redirection in memory rather than file.
        $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processStartInfo.FileName = $NugetExePath
        $processStartInfo.RedirectStandardError = $true
        $processStartInfo.RedirectStandardOutput = $true
        $processStartInfo.UseShellExecute = $false
        $processStartInfo.Arguments = $ArgumentList

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processStartInfo
        $process.Start() | Out-Null
        $process.WaitForExit()

        if (-Not ($process.ExitCode -eq 0 )) {
            $stdErr = $process.StandardError.ReadToEnd()
            throw "nuget.exe failed to push $stdErr"
        }
    }

    if ($PSCmdlet.ParameterSetName -eq "UseDotnetCli") {
        #perform dotnet pack using a temporary project file.
        $dotnetCliPath = (Get-Command -Name "dotnet").Source

        $ArgumentList = @('nuget')
        $ArgumentList += 'push'
        $ArgumentList += "`"$NupkgPath`""
        $ArgumentList += @('--source', "`"$Destination`"")
        $ArgumentList += @('--api-key', "`"$NugetApiKey`"")

        #use processstartinfo and process objects here as it allows stdout redirection in memory rather than file.
        $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processStartInfo.FileName = $dotnetCliPath
        $processStartInfo.RedirectStandardError = $true
        $processStartInfo.RedirectStandardOutput = $true
        $processStartInfo.UseShellExecute = $false
        $processStartInfo.Arguments = $ArgumentList

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processStartInfo
        $process.Start() | Out-Null
        $process.WaitForExit()

        if (-Not ($process.ExitCode -eq 0)) {
            $stdOut = $process.StandardOutput.ReadToEnd()
            throw "dotnet cli failed to nuget push $stdOut"
        }
    }

    $stdOut = $process.StandardOutput.ReadToEnd()
    Write-Verbose -Message $stdOut
}
