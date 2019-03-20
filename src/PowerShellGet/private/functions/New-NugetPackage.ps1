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

    if (-Not(Test-Path -Path $NuspecPath -PathType Leaf)) {
        throw "A nuspec file does not exist at $NuspecPath, provide valid path to a .nuspec"
    }

    if (-Not(Test-Path -Path $NugetPackageRoot)) {
        throw "NugetPackageRoot $NugetPackageRoot does not exist"
    }


    if ($PSCmdlet.ParameterSetName -eq "UseNuget") {
        if (-Not(Test-Path -Path $NuGetExePath)) {
            throw "Nuget.exe does not exist at $NugetExePath, provide a valid path to nuget.exe"
        }

        $ArgumentList = @("pack")
        $ArgumentList += "`"$NuspecPath`""
        $ArgumentList += "-outputdirectory `"$OutputPath`""

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
            throw "nuget.exe failed to pack $stdErr"
        }
    }

    if ($PSCmdlet.ParameterSetName -eq "UseDotnetCli") {
        #perform dotnet pack using a temporary project file.
        $dotnetCliPath = (Get-Command -Name "dotnet").Source
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

        #execution

        $ArgumentList = @("pack")
        $ArgumentList += "`"$projectFile`""
        $ArgumentList += "/p:NuspecFile=`"$NuspecPath`""
        $ArgumentList += "--output `"$OutputPath`""

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

        if (Test-Path -Path $tempPath) {
            Remove-Item -Path $tempPath -Force -Recurse
        }

        if (-Not ($process.ExitCode -eq 0 )) {
            $stdOut = $process.StandardOutput.ReadToEnd()
            throw "dotnet cli failed to pack $stdOut"
        }

    }

    [xml]$nuspecXml = Get-Content -Path $NuspecPath
    $version = $nuspecXml.package.metadata.version
    $id = $nuspecXml.package.metadata.id
    $nupkgFullFile = Join-Path $OutputPath -ChildPath "$id.$version.nupkg"

    $stdOut = $process.StandardOutput.ReadToEnd()

    Write-Verbose -Message $stdOut
    Write-Output $nupkgFullFile
}
