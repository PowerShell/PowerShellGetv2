#
# Copyright (c) Microsoft Corporation.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

Import-LocalizedData -BindingVariable LocalizedData -filename MSFT_PSModule.strings.psd1
$script:localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_PSModule' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

Import-Module -Name "$PSScriptRoot\..\PowerShellGetHelper.psm1"

# DSC Resource for the $CurrentProviderName.
$CurrentProviderName = "PowerShellGet"

# Return the current state of the resource.
function Get-TargetResource
{
    <#
    .SYNOPSIS
        This DSC resource provides a mechanism to download PowerShell modules from the PowerShell
        Gallery and install it on your computer. 

        Get-TargetResource returns the current state of the resource.

    .PARAMETER Name
        Specifies the name of the PowerShell module to be installed or uninstalled.

    .PARAMETER Repository
        Specifies the name of the module source repository where the module can be found.

    .PARAMETER RequiredVersion
        Provides the version of the module you want to install or uninstall.

    .PARAMETER MaximumVersion
        Provides the maximum version of the module you want to install or uninstall.

    .PARAMETER MinimumVersion
        Provides the minimum version of the module you want to install or uninstall.

    .PARAMETER Force
        Forces the installation of modules. If a module of the same name and version already exists on the computer,
        this parameter overwrites the existing module with one of the same name that was found by the command.

    .PARAMETER AllowClobber
        Allows the installation of modules regardless of if other existing module on the computer have cmdlets
        of the same name.

    .PARAMETER SkipPublisherCheck
        Allows the installation of modules that have not been catalog signed.
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.String]
        $Repository = "PSGallery",

        [System.String]
        $RequiredVersion,

        [System.String]
        $MaximumVersion,

        [System.String]
        $MinimumVersion,

        [Switch]
        $Force,
        
        [Switch]
        $AllowClobber,

        [Switch]
        $SkipPublisherCheck
    )

    # Initialize the $Ensure variable.
    $ensure = 'Absent'

    $extractedArguments = ExtractArguments -FunctionBoundParameters $PSBoundParameters `
        -ArgumentNames ("Name", "Repository", "MinimumVersion", "MaximumVersion", "RequiredVersion")

    # Get the module with the right version and repository properties.
    $modules = Get-RightModule @extractedArguments -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    # If the module is found, the count > 0
    if ($modules.count -gt 0) 
    {
        $ensure = 'Present'

        Write-Verbose -Message ($localizedData.ModuleFound -f $($Name))
    }
    else
    {
        Write-Verbose -Message ($localizedData.ModuleNotFound -f $($Name))
    }

    Write-Debug -Message "Ensure of $($Name) module is $($ensure)"

    if ($ensure -eq 'Absent')
    {
        $returnValue = @{
            Ensure = $ensure
            Name   = $Name
        }
    }
    else
    {
        # Find a module with the latest version and return its properties.
        $latestModule = $modules[0]

        foreach ($module in $modules)
        {
            if ($module.Version -gt $latestModule.Version)
            {
                $latestModule = $module
            }
        }

        # Check if the repository matches.
        $repositoryName = Get-ModuleRepositoryName -Module $latestModule -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

        $installationPolicy = Get-InstallationPolicy -RepositoryName $repositoryName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

        $returnValue = @{
            Ensure             = $ensure
            Name               = $Name
            Repository         = $repositoryName
            Description        = $latestModule.Description
            Guid               = $latestModule.Guid
            ModuleBase         = $latestModule.ModuleBase
            ModuleType         = $latestModule.ModuleType
            Author             = $latestModule.Author
            InstalledVersion   = $latestModule.Version 
            InstallationPolicy = if ($installationPolicy) {"Trusted"}else {"Untrusted"}
        }
    }
    return $returnValue
}

function Test-TargetResource
{
    <#
    .SYNOPSIS
        This DSC resource provides a mechanism to download PowerShell modules from the PowerShell
        Gallery and install it on your computer. 

        Test-TargetResource validates whether the resource is currently in the desired state.

    .PARAMETER Ensure
        Determines whether the module to be installed or uninstalled.

    .PARAMETER Name
        Specifies the name of the PowerShell module to be installed or uninstalled.

    .PARAMETER Repository
        Specifies the name of the module source repository where the module can be found.

    .PARAMETER InstallationPolicy
        Determines whether you trust the source repository where the module resides.

    .PARAMETER RequiredVersion
        Provides the version of the module you want to install or uninstall.

    .PARAMETER MaximumVersion
        Provides the maximum version of the module you want to install or uninstall.

    .PARAMETER MinimumVersion
        Provides the minimum version of the module you want to install or uninstall.

    .PARAMETER Force
        Forces the installation of modules. If a module of the same name and version already exists on the computer, 
        this parameter overwrites the existing module with one of the same name that was found by the command.

    .PARAMETER AllowClobber
        Allows the installation of modules regardless of if other existing module on the computer have cmdlets
        of the same name.

    .PARAMETER SkipPublisherCheck
        Allows the installation of modules that have not been catalog signed.
    #>

    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.String]
        $Repository = "PSGallery",

        [ValidateSet("Trusted", "Untrusted")]
        [System.String]
        $InstallationPolicy = "Untrusted",

        [System.String]
        $RequiredVersion,

        [System.String]
        $MaximumVersion,

        [System.String]
        $MinimumVersion,

        [Switch]
        $Force,

        [Switch]
        $AllowClobber,

        [Switch]
        $SkipPublisherCheck
    )

    Write-Debug -Message  "Calling Test-TargetResource"

    $extractedArguments = ExtractArguments -FunctionBoundParameters $PSBoundParameters `
        -ArgumentNames ("Name", "Repository", "MinimumVersion", "MaximumVersion", "RequiredVersion")

    $status = Get-TargetResource @extractedArguments

    # The ensure returned from Get-TargetResource is not equal to the desired $Ensure.
    if ($status.Ensure -ieq $Ensure)
    {
        Write-Verbose -Message ($localizedData.InDesiredState -f $Name)
        return $true
    }
    else
    {
        Write-Verbose -Message ($localizedData.NotInDesiredState -f $Name)
        return $false
    }
}

function Set-TargetResource
{
    <#
    .SYNOPSIS
        This DSC resource provides a mechanism to download PowerShell modules from the PowerShell
        Gallery and install it on your computer. 

        Set-TargetResource sets the resource to the desired state. "Make it so".

    .PARAMETER Ensure
        Determines whether the module to be installed or uninstalled.

    .PARAMETER Name
        Specifies the name of the PowerShell module to be installed or uninstalled.

    .PARAMETER Repository
        Specifies the name of the module source repository where the module can be found.

    .PARAMETER InstallationPolicy
        Determines whether you trust the source repository where the module resides.

    .PARAMETER RequiredVersion
        Provides the version of the module you want to install or uninstall.

    .PARAMETER MaximumVersion
        Provides the maximum version of the module you want to install or uninstall.

    .PARAMETER MinimumVersion
        Provides the minimum version of the module you want to install or uninstall.

    .PARAMETER Force
        Forces the installation of modules. If a module of the same name and version already exists on the computer,
        this parameter overwrites the existing module with one of the same name that was found by the command.

    .PARAMETER AllowClobber
        Allows the installation of modules regardless of if other existing module on the computer have cmdlets
        of the same name.

    .PARAMETER SkipPublisherCheck
        Allows the installation of modules that have not been catalog signed.
    #>

    [CmdletBinding()]
    param
    (
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.String]
        $Repository = "PSGallery",

        [ValidateSet("Trusted", "Untrusted")]
        [System.String]
        $InstallationPolicy = "Untrusted",

        [System.String]
        $RequiredVersion,

        [System.String]
        $MaximumVersion,

        [System.String]
        $MinimumVersion,

        [Switch]
        $Force,
        
        [Switch]
        $AllowClobber,
        
        [Switch]
        $SkipPublisherCheck
    )

    # Validate the repository argument
    if ($PSBoundParameters.ContainsKey("Repository"))
    {
        ValidateArgument -Argument $Repository -Type "PackageSource" -ProviderName $CurrentProviderName -Verbose
    }

    if ($Ensure -ieq "Present")
    {
        # Version check
        $extractedArguments = ExtractArguments -FunctionBoundParameters $PSBoundParameters `
            -ArgumentNames ("MinimumVersion", "MaximumVersion", "RequiredVersion")

        ValidateVersionArgument @extractedArguments 

        $extractedArguments = ExtractArguments -FunctionBoundParameters $PSBoundParameters `
            -ArgumentNames ("Name", "Repository", "MinimumVersion", "MaximumVersion", "RequiredVersion")

        Write-Verbose -Message ($localizedData.StartFindmodule -f $($Name))

        $modules = Find-Module @extractedArguments -ErrorVariable ev

        if (-not $modules) 
        {
            ThrowError -ExceptionName "System.InvalidOperationException" `
                -ExceptionMessage ($localizedData.ModuleNotFoundInRepository -f $Name, $ev.Exception) `
                -ErrorId "ModuleNotFoundInRepository" `
                -ErrorCategory InvalidOperation
        }

        $trusted = $null
        $moduleFound = $null

        foreach ($m in $modules)
        {
            # Check for the installation policy.
            $trusted = Get-InstallationPolicy -RepositoryName $m.Repository -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

            # Stop the loop if found a trusted repository.
            if ($trusted)
            {
                $moduleFound = $m 
                break;
            }
        }

        # The respository is trusted, so we install it.
        if ($trusted)
        {
            Write-Verbose -Message ($localizedData.StartInstallModule -f $Name, $moduleFound.Version.toString(), $moduleFound.Repository)

            # Extract the installation options.
            $extractedSwitches = ExtractArguments -FunctionBoundParameters $PSBoundParameters -ArgumentNames ("Force", "AllowClobber", "SkipPublisherCheck")

            $moduleFound |  Install-Module -ErrorVariable ev
        }
        # The repository is untrusted but user's installation policy is trusted, so we install it with a warning.
        elseif ($InstallationPolicy -ieq 'Trusted')
        {
            Write-Warning -Message ($localizedData.InstallationPolicyWarning -f $Name, $modules[0].Repository, $InstallationPolicy)

            # Extract installation options (Force implied by InstallationPolicy).
            $extractedSwitches = ExtractArguments -FunctionBoundParameters $PSBoundParameters -ArgumentNames ("AllowClobber", "SkipPublisherCheck")

            # If all the repositories are untrusted, we choose the first one.
            $modules[0] |  Install-Module @extractedSwitches -Force -ErrorVariable ev
        }
        # Both user and repository is untrusted
        else
        {
            ThrowError  -ExceptionName "System.InvalidOperationException" `
                -ExceptionMessage ($localizedData.InstallationPolicyFailed -f $InstallationPolicy, "Untrusted") `
                -ErrorId "InstallationPolicyFailed" `
                -ErrorCategory InvalidOperation
        }

        if ($ev)
        {
            ThrowError  -ExceptionName "System.InvalidOperationException" `
                -ExceptionMessage ($localizedData.FailtoInstall -f $Name, $ev.Exception) `
                -ErrorId "FailtoInstall" `
                -ErrorCategory InvalidOperation
        }
        else
        {
            Write-Verbose -Message ($localizedData.InstalledSuccess -f $($Name))
        }
    }
    # Ensure=Absent
    else
    {

        $extractedArguments = ExtractArguments -FunctionBoundParameters $PSBoundParameters `
            -ArgumentNames ("Name", "Repository", "MinimumVersion", "MaximumVersion", "RequiredVersion")

        # Get the module with the right version and repository properties.
        $modules = Get-RightModule @extractedArguments -ErrorVariable ev

        if ((-not $modules) -or $ev) 
        {
            ThrowError  -ExceptionName "System.InvalidOperationException" `
                -ExceptionMessage ($localizedData.ModuleWithRightPropertyNotFound -f $Name, $ev.Exception) `
                -ErrorId "ModuleWithRightPropertyNotFound" `
                -ErrorCategory InvalidOperation
        }

        foreach ($module in $modules)
        {
            # Get the path where the module is installed.
            $path = $module.ModuleBase

            Write-Verbose -Message ($localizedData.StartUnInstallModule -f $($Name))  

            # There is no Uninstall-Module cmdlet exists, so we will remove the ModuleBase folder as an uninstall operation.
            Microsoft.PowerShell.Management\Remove-Item -Path $path -Force -Recurse -ErrorVariable ev

            if ($ev)
            {
                ThrowError  -ExceptionName "System.InvalidOperationException" `
                    -ExceptionMessage ($localizedData.FailtoUninstall -f $module.Name, $ev.Exception) `
                    -ErrorId "FailtoUninstall" `
                    -ErrorCategory InvalidOperation
            }
            else
            {
                Write-Verbose -Message ($localizedData.UnInstalledSuccess -f $($module.Name))
            }
        } # foreach
    } # Ensure=Absent
}

Function Get-RightModule
{
    <#
    .SYNOPSIS
        This is a helper function. It returns the modules that meet the specified versions and the repository requirements.

    .PARAMETER Name
        Specifies the name of the PowerShell module.

    .PARAMETER RequiredVersion
        Provides the version of the module you want to install or uninstall.

    .PARAMETER MaximumVersion
        Provides the maximum version of the module you want to install or uninstall.

    .PARAMETER MinimumVersion
        Provides the minimum version of the module you want to install or uninstall.

    .PARAMETER Repository
        Specifies the name of the module source repository where the module can be found.
    #>

    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [System.String]
        $RequiredVersion,

        [System.String]
        $MinimumVersion,

        [System.String]
        $MaximumVersion,

        [System.String]
        $Repository
    )

    Write-Verbose -Message ($localizedData.StartGetModule -f $($Name))

    $modules = Microsoft.PowerShell.Core\Get-Module -Name $Name -ListAvailable -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    if (-not $modules)
    {
        return $null
    }

    # As Get-Module does not take RequiredVersion, MinimumVersion, MaximumVersion, or Repository, below we need to check
    # whether the modules are containing the right version and repository location.

    $extractedArguments = ExtractArguments -FunctionBoundParameters $PSBoundParameters `
        -ArgumentNames ("MaximumVersion", "MinimumVersion", "RequiredVersion")
    $returnVal = @()

    foreach ($m in $modules)
    {
        $versionMatch = $false
        $installedVersion = $m.Version

        # Case 1 - a user provides none of RequiredVersion, MinimumVersion, MaximumVersion
        if ($extractedArguments.Count -eq 0)
        {
            $versionMatch = $true
        }

        # Case 2 - a user provides RequiredVersion 
        elseif ($extractedArguments.ContainsKey("RequiredVersion"))
        {
            # Check if it matches with the installedversion
            $versionMatch = ($installedVersion -eq [System.Version]$RequiredVersion)
        }
        else
        {
            
            # Case 3 - a user provides MinimumVersion 
            if ($extractedArguments.ContainsKey("MinimumVersion"))
            {
                $versionMatch = ($installedVersion -ge [System.Version]$extractedArguments['MinimumVersion'])
            }
            
            # Case 4 - a user provides MaximumVersion
            if ($extractedArguments.ContainsKey("MaximumVersion"))
            {
                $isLessThanMax = ($installedVersion -le [System.Version]$extractedArguments['MaximumVersion'])

                if ($extractedArguments.ContainsKey("MinimumVersion"))
                {
                    $versionMatch = $versionMatch -and $isLessThanMax
                }
                else
                {
                    $versionMatch = $isLessThanMax
                }
            }
            
            # Case 5 - Both MinimumVersion and MaximumVersion are provided. It's covered by the above.
            # Do not return $false yet to allow the foreach to continue
            if (-not $versionMatch)
            {
                Write-Verbose -Message ($localizedData.VersionMismatch -f $($Name), $($installedVersion))
                $versionMatch = $false
            }
        }

        # Case 6 - Version matches but need to check if the module is from the right repository.
        if ($versionMatch) 
        {
            # a user does not provide Repository, we are good
            if (-not $PSBoundParameters.ContainsKey("Repository"))
            {
                Write-Verbose -Message ($localizedData.ModuleFound -f "$($Name) $($installedVersion)")
                $returnVal += $m
            }
            else
            {
                # Check if the Repository matches
                $sourceName = Get-ModuleRepositoryName -Module $m

                if ($Repository -ieq $sourceName)
                {
                    Write-Verbose -Message ($localizedData.ModuleFound -f "$($Name) $($installedVersion)")
                    $returnVal += $m
                }
                else
                {
                    Write-Verbose -Message ($localizedData.RepositoryMismatch -f $($Name), $($sourceName))
                }
            }
        }
    } # foreach
    return $returnVal
}

Function Get-ModuleRepositoryName
{
    <#
    .SYNOPSIS
        This is a helper function that returns the module's repository name.

    .PARAMETER Module
        Specifies the name of the PowerShell module.
    #>

    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        $Module
    )

    # RepositorySourceLocation property is supported in PS V5 only. To work with the earlier PS version, we need to do a different way.
    # PSGetModuleInfo.xml exists for any PS modules downloaded through PSModule provider.
    $psGetModuleInfoFileName = "PSGetModuleInfo.xml"
    $psGetModuleInfoPath = Microsoft.PowerShell.Management\Join-Path -Path $Module.ModuleBase -ChildPath $psGetModuleInfoFileName

    Write-Verbose -Message ($localizedData.FoundModulePath -f $($psGetModuleInfoPath))

    if (Microsoft.PowerShell.Management\Test-path -Path $psGetModuleInfoPath)
    {
        $psGetModuleInfo = Microsoft.PowerShell.Utility\Import-Clixml -Path $psGetModuleInfoPath

        return $psGetModuleInfo.Repository
    }
}

Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
