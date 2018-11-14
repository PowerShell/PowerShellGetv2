function HttpClientApisAvailable
{
    $HttpClientApisAvailable = $false
    try
    {
        [System.Net.Http.HttpClient]
        $HttpClientApisAvailable = $true
    }
    catch
    {
    }
    return $HttpClientApisAvailable
}
