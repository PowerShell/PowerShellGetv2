function Join-PathUtility
{
    <#
    .DESCRIPTION
        Utility to get the case-sensitive path, if exists.
        Otherwise, returns the output of Join-Path cmdlet.
        This is required for getting the case-sensitive paths on non-Windows platforms.
    #>
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter(Mandatory = $false)]
        [string]
        $ChildPath,

        [Parameter(Mandatory = $true)]
        [string]
        [ValidateSet('File', 'Directory', 'Any')]
        $PathType = 'Any'
    )

    $JoinedPath = Microsoft.PowerShell.Management\Join-Path -Path $Path -ChildPath $ChildPath
    if(Microsoft.PowerShell.Management\Test-Path -Path $Path -PathType Container) {
        $GetChildItem_params = @{
            Path = $Path
            ErrorAction = 'SilentlyContinue'
            WarningAction = 'SilentlyContinue'
        }
        if($PathType -eq 'File') {
            $GetChildItem_params['File'] = $true
        }
        elseif($PathType -eq 'Directory') {
            $GetChildItem_params['Directory'] = $true
        }

        $FoundPath = Microsoft.PowerShell.Management\Get-ChildItem @GetChildItem_params |
            Where-Object {$_.Name -eq $ChildPath} |
                ForEach-Object {$_.FullName} |
                    Select-Object -First 1 -ErrorAction SilentlyContinue

        if($FoundPath) {
            $JoinedPath = $FoundPath
        }
    }

    return $JoinedPath
}