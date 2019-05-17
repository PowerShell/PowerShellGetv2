function New-NugetPackage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$NuspecPath,

        [Parameter(Mandatory = $true)]
        [string]$NugetPackageRoot,

        [Parameter()]
        [string]$OutputPath = $NugetPackageRoot,

        [Parameter(Mandatory = $true, ParameterSetName = "UseNuget")]
        [string]$NugetExePath,

        [Parameter(ParameterSetName = "UseDotnetCli")]
        [switch]$UseDotnetCli

    )
    Set-StrictMode -Off

    Write-Verbose "Calling New-NugetPackage"

    if (-Not(Test-Path -Path $NuspecPath -PathType Leaf)) {
        throw "A nuspec file does not exist at $NuspecPath, provide valid path to a .nuspec"
    }

    if (-Not(Test-Path -Path $NugetPackageRoot)) {
        throw "NugetPackageRoot $NugetPackageRoot does not exist"
    }

    $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo

    if ($PSCmdlet.ParameterSetName -eq "UseNuget") {
        if (-Not(Test-Path -Path $NuGetExePath)) {
            throw "Nuget.exe does not exist at $NugetExePath, provide a valid path to nuget.exe"
        }
        $ProcessName = $NugetExePath

        $ArgumentList = @("pack")
        $ArgumentList += "`"$NuspecPath`""
        $ArgumentList += "-outputdirectory `"$OutputPath`" -noninteractive"

        $tempPath = $null
    }
    else {
        # use Dotnet CLI

        #perform dotnet pack using a temporary project file.
        $ProcessName = (Get-Command -Name "dotnet").Source
        $tempPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid()).Guid
        New-Item -ItemType Directory -Path $tempPath -Force | Out-Null

        $CsprojContent = @"
<Project Sdk="Microsoft.NET.Sdk">
<PropertyGroup>
    <AssemblyName>NotUsed</AssemblyName>
    <Description>Temp project used for creating nupkg file.</Description>
    <TargetFramework>netcoreapp2.0</TargetFramework>
    <IsPackable>true</IsPackable>
</PropertyGroup>
</Project>
"@
        $projectFile = New-Item -ItemType File -Path $tempPath -Name "Temp.csproj"
        Set-Content -Value $CsprojContent -Path $projectFile

        $ArgumentList = @("pack")
        $ArgumentList += "`"$projectFile`""
        $ArgumentList += "/p:NuspecFile=`"$NuspecPath`""
        $ArgumentList += "--output `"$OutputPath`""
    }

    # run the packing program
    $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processStartInfo.FileName = $ProcessName
    $processStartInfo.Arguments = $ArgumentList
    $processStartInfo.RedirectStandardError = $true
    $processStartInfo.RedirectStandardOutput = $true
    $processStartInfo.UseShellExecute = $false

    Write-Verbose "Calling $ProcessName $($ArgumentList -join ' ')"
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processStartInfo

    $process.Start() | Out-Null

    # read output incrementally, it'll block if it writes too much
    $outputLines = @()
    Write-Verbose "$ProcessName output:"
    while (! $process.HasExited) {
        $output = $process.StandardOutput.ReadLine()
        Write-Verbose "`t$output"
        $outputLines += $output
    }

    # get any remaining output
    $process.WaitForExit()
    $outputLines += $process.StandardOutput.ReadToEnd()

    $stdOut = $outputLines -join "`n"

    Write-Verbose "finished running $($processStartInfo.FileName) with exit code $($process.ExitCode)"

    if (($tempPath -ne $null) -and (Test-Path -Path $tempPath)) {
        Remove-Item -Path $tempPath -Force -Recurse
    }

    if (-Not ($process.ExitCode -eq 0 )) {
        # nuget writes errors to stdErr, dotnet writes them to stdOut
        if ($UseDotnetCli) {
            $errors = $stdOut
        }
        else {
            $errors = $process.StandardError.ReadToEnd()
        }
        throw "$ProcessName failed to pack: error $errors"
    }

    $stdOut -match "Successfully created package '(.*.nupkg)'" | Out-Null
    $nupkgFullFile = $matches[1]

    Write-Verbose "Created Nuget Package $nupkgFullFile"
    Write-Output $nupkgFullFile
}
