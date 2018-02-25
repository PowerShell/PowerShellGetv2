function Test-FileInUse
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [string]
        $FilePath
    )

    if(Microsoft.PowerShell.Management\Test-Path -LiteralPath $FilePath -PathType Leaf)
    {
        # Attempts to open a file and handles the exception if the file is already open/locked
        try
        {
            $fileInfo = New-Object System.IO.FileInfo $FilePath
            $fileStream = $fileInfo.Open( [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None )

            if ($fileStream)
            {
                $fileStream.Close()
            }
        }
        catch
        {
            Write-Debug "In Test-FileInUse function, unable to open the $FilePath file in ReadWrite access. $_"
            return $true
        }
    }

    return $false
}