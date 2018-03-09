function Test-ModuleInUse
{
    [CmdletBinding()]
    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleBasePath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleVersion
    )

    $FileList = Get-ChildItem -Path $ModuleBasePath `
                              -File `
                              -Recurse `
                              -ErrorAction SilentlyContinue `
                              -WarningAction SilentlyContinue
    $IsModuleInUse = $false

    foreach($file in $FileList)
    {
        $IsModuleInUse = Test-FileInUse -FilePath $file.FullName

        if($IsModuleInUse)
        {
            break
        }
    }

    if($IsModuleInUse)
    {
        $message = $LocalizedData.ModuleVersionInUse -f ($ModuleVersion, $ModuleName)
        Write-Error -Message $message -ErrorId 'ModuleIsInUse' -Category InvalidOperation

        return $true
    }

    return $false
}