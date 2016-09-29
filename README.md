[![Build status](https://ci.appveyor.com/api/projects/status/91p7lpjoxit3gw72/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/powershellget/branch/master)

[![Join the chat at https://gitter.im/PowerShell/PowerShellGet](https://badges.gitter.im/PowerShell/PowerShellGet.svg)](https://gitter.im/PowerShell/PowerShellGet?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Introduction
============

PowerShellGet is a PowerShell module with commands for discovering, installing, updating and publishing the PowerShell artifacts like Modules, DSC Resources, Role Capabilities and Scripts.

PowerShellGet module is also integrated with the PackageManagement module as a provider, users can also the PackageManagement cmdlets for discovering, installing and updating the PowerShell artifacts like Modules and Scripts.

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

### Windows 10 or newer

### Windows Server 2016 or newer

### Windows Management Framework (WMF) 5.0 or newer

### Get the latest version from PowerShell Gallery

```powershell
# On PowerShell 5.0 or newer, use the Install-Module with -Force to install the PowerShellGet module from the PowerShellGallery.
Install-Module -Name PowerShellGet -Force

# Use Update-Module cmdlet to get the updated version
Update-Module -Name PowerShellGet

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


