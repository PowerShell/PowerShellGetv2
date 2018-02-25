function Get-Hash
# Returns a SHA1 hash of the specified string
{
    [CmdletBinding()]
    Param
    (
        [string]
        $locationString
    )

    if(-not $locationString)
    {
        return ""
    }

    $sha1Object = New-Object System.Security.Cryptography.SHA1Managed
    $stringHash = $sha1Object.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($locationString));
    $stringHashInHex = [System.BitConverter]::ToString($stringHash)

    if ($stringHashInHex)
    {
        # Remove all dashes in the hex string
        return $stringHashInHex.Replace('-', '')
    }

    return ""
}