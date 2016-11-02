
[![Join the chat at https://gitter.im/PowerShell/PowerShellGet](https://badges.gitter.im/PowerShell/PowerShellGet.svg)](https://gitter.im/PowerShell/PowerShellGet?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/PowerShell/PowerShellGet/blob/development/LICENSE)
[![Documentation - PowerShellGet](https://img.shields.io/badge/Documentation-PowerShellGet-blue.svg)](https://msdn.microsoft.com/en-us/powershell/gallery/psget)
[![PowerShell Gallery - PowerShellGet](https://img.shields.io/badge/PowerShell%20Gallery-PowerShellGet-blue.svg)](https://www.powershellgallery.com/packages/PowerShellGet)
[![Minimum Supported PowerShell Version](https://img.shields.io/badge/PowerShell-3.0-blue.svg)](https://github.com/PowerShell/PowerShellGet)

Introduction
============

PowerShellGet is a PowerShell module with commands for discovering, installing, updating and publishing the PowerShell artifacts like Modules, DSC Resources, Role Capabilities and Scripts.

PowerShellGet module is also integrated with the PackageManagement module as a provider, users can also use the PackageManagement cmdlets for discovering, installing and updating the PowerShell artifacts like Modules and Scripts.


Build status
============

## Development branch

|         OS - PS Version             |          Build Status        |
|-------------------------------------|------------------------------|
| AppVeyor (Windows - PS 4.0)         | [![d-av-image][]][d-av-site] |
| AppVeyor (Windows - PS 5.1)         | [![d-av-image][]][d-av-site] |
| AppVeyor (Windows - PS 6.0.0-Alpha) | [![d-av-image][]][d-av-site] |
| Travis CI (Linux - PS 6.0.0-Alpha)  | [![d-tv-image][]][d-tv-site] |
| Travis CI (MacOS - PS 6.0.0-Alpha)  | [![d-tv-image][]][d-tv-site] |

## Master branch
|         OS - PS Version             |          Build Status        |
|-------------------------------------|------------------------------|
| AppVeyor (Windows - PS 4.0)         | [![m-av-image][]][m-av-site] |
| AppVeyor (Windows - PS 5.1)         | [![m-av-image][]][m-av-site] |
| AppVeyor (Windows - PS 6.0.0-Alpha) | [![m-av-image][]][m-av-site] |
| Travis CI (Linux - PS 6.0.0-Alpha)  | [![m-tv-image][]][m-tv-site] |
| Travis CI (MacOS - PS 6.0.0-Alpha)  | [![m-tv-image][]][m-tv-site] |

[d-av-image]: https://ci.appveyor.com/api/projects/status/91p7lpjoxit3gw72/branch/development?svg=true
[d-av-site]: https://ci.appveyor.com/project/PowerShell/powershellget/branch/development
[d-tv-image]: https://travis-ci.org/PowerShell/PowerShellGet.svg?branch=development
[d-tv-site]: https://travis-ci.org/PowerShell/PowerShellGet/branches

[m-av-image]: https://ci.appveyor.com/api/projects/status/91p7lpjoxit3gw72/branch/master?svg=true
[m-av-site]: https://ci.appveyor.com/project/PowerShell/powershellget/branch/master
[m-tv-image]: https://travis-ci.org/PowerShell/PowerShellGet.svg?branch=master
[m-tv-site]: https://travis-ci.org/PowerShell/PowerShellGet/branches

Documentation
=============

[Click here](https://msdn.microsoft.com/en-us/powershell/gallery/psget/overview)


Requirements
============

- Windows PowerShell 3.0 or newer.
- PowerShell Core.

Module Dependencies
===================

- PackageManagement module

Get PowerShellGet Module
========================

### PowerShellGet is an in-box module in following releases
- [Windows 10](https://www.microsoft.com/en-us/windows/get-windows-10) or newer
- [Windows Server 2016](https://technet.microsoft.com/en-us/windows-server-docs/get-started/windows-server-2016) or newer
- [Windows Management Framework (WMF) 5.0](https://www.microsoft.com/en-us/download/details.aspx?id=50395) or newer
- [PowerShell 6.0.0-Alpha](https://github.com/PowerShell/PowerShell/releases)

### Get PowerShellGet module for PowerShell versions 3.0 and 4.0
- [PackageManagement MSI](http://go.microsoft.com/fwlink/?LinkID=746217&clcid=0x409) 

### Get the latest version from PowerShell Gallery

Before updating PowerShellGet, you should always install the latest Nuget provider. To do that, run the following in an elevated PowerShell session.
```powershell
Install-PackageProvider Nuget –force –verbose
# exit the session
```

For systems with PowerShell 5.0 (or greater) you can install both PowerShellGet. 
To do this on Windows 10, Windows Server 2016, or any system with WMF 5.0 or 5.1 installed, run the following commands from an elevated PowerShell session.
```powershell
Install-Module –Name PowerShellGet –Force
# exit the session
```

Use Update-Module to get the next updated versions.
```powershell
Update-Module -Name PowerShellGet
# exit the session
```

### Source

#### Steps
* Obtain the source
    - Download the latest source code from the release page (https://github.com/PowerShell/PowerShellGet/releases) OR
    - Clone the repository (needs git)
    ```powershell
    git clone https://github.com/PowerShell/PowerShellGet
    ```
* Navigate to the source directory
```powershell
cd path/to/PowerShellGet
```

* Import the module
```powershell
Import-Module /path/to/PowerShellGet/PowerShellGet
```


Running Tests
=============

Pester-based PowerShellGet Tests are located in `<branch>/PowerShellGet/Tests` folder.

1. Ensure Pester is installed on the machine
2. Go the Tests folder in your local repository
3. Run the tests by calling Invoke-Pester.

Contributing to PowerShellGet
==============================
You are welcome to contribute to this project. There are many ways to contribute:

1. Submit a bug report via [Issues]( https://github.com/PowerShell/PowerShellGet/issues). For a guide to submitting good bug reports, please read [Painless Bug Tracking](http://www.joelonsoftware.com/articles/fog0000000029.html).
2. Verify fixes for bugs.
3. Submit your fixes for a bug. Before submitting, please make sure you have:
  * Performed code reviews of your own
  * Updated the test cases if needed
  * Run the test cases to ensure no feature breaks or test breaks
  * Added the test cases for new code
4. Submit a feature request.
5. Help answer questions in the discussions list.
6. Submit test cases.
7. Tell others about the project.
8. Tell the developers how much you appreciate the product!

You might also read these two blog posts about contributing code: [Open Source Contribution Etiquette](http://tirania.org/blog/archive/2010/Dec-31.html) by Miguel de Icaza, and [Don’t “Push” Your Pull Requests](http://www.igvita.com/2011/12/19/dont-push-your-pull-requests/) by Ilya Grigorik.

Before submitting a feature or substantial code contribution, please discuss it with the Windows PowerShell team via [Issues](https://github.com/PowerShell/PowerShellGet/issues), and ensure it follows the product roadmap. Note that all code submissions will be rigorously reviewed by the Windows PowerShell Team. Only those that meet a high bar for both quality and roadmap fit will be merged into the source.


