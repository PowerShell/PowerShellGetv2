function Get-ParametersHashtable
{
    param(
        $Proxy,
        $ProxyCredential
    )

    $ParametersHashtable = @{}
    if($Proxy)
    {
        $ParametersHashtable[$script:Proxy] = $Proxy
    }

    if($ProxyCredential)
    {
        $ParametersHashtable[$script:ProxyCredential] = $ProxyCredential
    }

    return $ParametersHashtable
}