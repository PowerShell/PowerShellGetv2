# Load localized data
Import-LocalizedData LocalizedData -filename PSGet.Resource.psd1

# Dot source the first part of this file from .\private\modulefile\PartOne.ps1
. "$PSScriptRoot\private\modulefile\PartOne.ps1"

# region Load of module functions after split from main .psm1 file issue Fix#37
$PublicFunctions = @( Get-ChildItem -Path $PSScriptRoot\public\*.ps1 -Recurse -ErrorAction SilentlyContinue )
$PrivateFunctions = @( Get-ChildItem -Path $PSScriptRoot\private\functions\*.ps1 -ErrorAction SilentlyContinue )

# Load the separate function files from the private and public folders.
$AllFunctions = $PublicFunctions + $PrivateFunctions
foreach($function in $AllFunctions) {
    try {
        . $function.Fullname
    }
    catch {
        Write-Error -Message "Failed to import function $($function.fullname): $_"
    }
}

# Export the public functions
Export-ModuleMember -Function $PublicFunctions.BaseName

#endregion

# now dot source the rest of this file from .\private\modulefile\PartTwo.ps1 (after the private and public
# functions have been dot sourced above.)
. "$PSScriptRoot\private\modulefile\PartTwo.ps1"
