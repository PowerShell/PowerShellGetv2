# Requires -RunAsAdministrator 
Function Save-PowerShellGetForOffline {
    <#
.SYNOPSIS
    Acquire PowerShellGet and related modules for offline use
.DESCRIPTION
    This function acquires all the items needed to do a disconnnected setup of PowerShellGet, PackageManagement, and Nuget.exe.
    The resultant folders are prepped to be deployed directly to target devices using Install-PowerShellGetOffline
    This module currently only supports Windows. 
    
    The script sequence assumes that you are installing everything as though these steps were performed by an administrator.
    One implication is that you must run the script as admin, which will ensure that the modules work for all users. 
    For details on how to do this for non-admin users, review the documentation at:
    https://docs.microsoft.com/en-us/powershell/gallery/psget/repository/bootstrapping_nuget_proivder_and_exe

.EXAMPLE
    
    PS C:\> Save-PowerShellGetForOffline -LocalFolder c:\temp\PowerShellGetStuff 
    
.PARAMETER LocalFolder
    Required, is the path to a folder where PowerShellGet, Package Management, and NuGet.Exe will be placed.  
.PARAMETER NuGetSource
    Optional, is the path to NuGetv2.exe, which is accessible from the system where this is executed

#>    
   

    [CmdletBinding()]
    Param (
        #   Need a local folder to store things in, temporarily
        [Parameter(Mandatory = $true)]
        [string] $LocalFolder,
  

        [Parameter(Mandatory = $false)]
        [string] $NuGetSource = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
    )
    
    <#
        Validate the folder exists. 
        If not, create it.
        If not possible, error. 
    #>


    If (-not (test-path -path $LocalFolder)) {
        write-verbose "Creating folder $LocalFolder"
        new-item $LocalFolder -itemtype Directory
    }
    
    
    <#
        Acquire NuGet.exe and place it on the local system. 

        NOTE that this step is ONLY needed to publish items to the "repository" you will use for your offline systems.
        It is not needed for systems where you are only acquiring things from the local repository. 
    #>
    
    write-verbose "Acquiring Nuget.exe"
    $destination = Join-path (Resolve-Path $LocalFolder) 'nuget.exe'
    $wc = New-Object system.net.webclient
    $wc.downloadFile($NuGetSource, $destination)
     
    <# 
        Save the current PackageManagement and PowerShellGet modules to the current folder
    #>
    write-verbose "Saving Packagemanagement module locally"
    Save-Module PackageManagement -Repository psgallery -path $LocalFolder 
    
    write-verbose "Saving PowerShellGet module locally"
    Save-Module PowerShellGet -Repository PsGallery -path $LocalFolder 
    
    <#
        Unblock the files just acquired from the web
    #>
    Get-ChildItem -Path $LocalFolder -recurse | Unblock-File
    
    <#
        Delete the PSGetModuleInfo.xml file from each module folder.
        This file is created during save-module, but if it is present, test-filecatalog for these modules will fail.
    #>
    
    Get-ChildItem -Path $LocalFolder -Filter psgetmoduleinfo.xml -force -Recurse | Remove-Item -force -Verbose
    
    <#
        The contents of this folder may now be copied to a file share for use with the script OfflinePowerShellGetSetup.ps1
    #>
}


Function Install-PowerShellGetOffline {
    <#
.SYNOPSIS
    Install PowerShellGet and related modules to a disconnected system
.DESCRIPTION
    This performs the steps needed for internet-disconnected systems to use PowerShellGet
    It takes a path (folder name) that has a copy of 
        NuGet.Exe                              and
        The PowerShellGet module, unpacked     and
        The PackageManagement modules, unpacked
    
    This will copy the PowerShellGet components from the LocalFolder into the proper locations for the local machine 

    The script assumes that the installation will be done as an administrator on the target device, so that all users can use PowerShellGet after this.
    To find details on how to change the scope to the current user, see the documentation  
.EXAMPLE
    
    PS C:\> Install-PowerShellGetOffline -LocalFolder \\testshare\temp\PowerShellGetStuff
    
.PARAMETER LocalFolder
    Required, is the path to a folder where PowerShellGet, Package Management, and NuGet.Exe have been placed using Save-PowerShellGetForOffline.  

#>    
   

[CmdletBinding()]

    Param (
        #   Local folder containing NuGet, PackageManagement, and PowerShellGet
        [Parameter(Mandatory = $true)]
        [string] $LocalFolder = "C:\temp\demo"        
    )

    <#
    Confirm the LocalFolder has something resembling Nuget & the 2 modules
#>

    If ((-not(get-item $LocalFolder\nuget.exe)) -or (-not (get-item $LocalFolder\packagemanagement)) -or (-not (get-item $LocalFolder\powershellget))) {
        Throw "Error: The local folder must contain nuget.exe, the PackageManagement module, and the PowerShellGet module"
    }



    <# 

    NuGet.exe is only required on systems used to publish to a PowerShellGet repository.

    Put NuGet.exe in the required location for the local system. 
    Create the folder for Nuget.exe, if necessary
#>

    If (-not (Test-Path -Path "$env:ProgramData\Microsoft\Windows\PowerShell\PowerShellGet")) {

        New-Item "$env:ProgramData\Microsoft\Windows\PowerShell\PowerShellGet" -itemtype directory

    }

    
    If (-not (Test-Path -Path "$env:ProgramData\Microsoft\Windows\PowerShell\packagemanagement")) {

        New-Item "$env:ProgramData\Microsoft\Windows\PowerShell\PackageManagement" -itemtype directory

    }

    Copy-Item -Path @"
$($LocalFolder)\Nuget.exe
"@ -Destination "$env:ProgramData\Microsoft\Windows\PowerShell\PowerShellGet"

    <#

    Copy the module folders for PackageManagement and PowerShellGet to the default installation location 
    This script assumes that the current user is an administrator, to support copying to ProgramFiles.
    
#>

    Copy-Item -Path @"
$($LocalFolder)\PackageManagement\*.*
"@ `
        -Recurse `
        -Destination "$env:ProgramFiles\WindowsPowerShell\modules\PackageManagement\" `
        -Force

    Copy-Item -Path @"
$($LocalFolder)\PowerShellGet\*.*
"@ `
        -Recurse `
        -Destination "$env:ProgramFiles\WindowsPowerShell\modules\PowerShellGet\" `
        -Force

}

