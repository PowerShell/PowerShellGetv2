function Test-ModuleSxSVersionSupport
{
    # Side-by-Side module version is available on PowerShell 5.0 or later versions only
    # By default, PowerShell module versions will be installed/updated Side-by-Side.
    $PSVersionTable.PSVersion -ge '5.0.0'
}