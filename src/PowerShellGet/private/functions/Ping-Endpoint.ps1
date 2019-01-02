function Ping-Endpoint
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Endpoint,

        [Parameter()]
        $Credential,

        [Parameter()]
        $Proxy,

        [Parameter()]
        $ProxyCredential,

        [Parameter()]
        [switch]
        $AllowAutoRedirect = $true
    )

    $results = @{}

    $WebProxy = $null
    if($Proxy -and ('Microsoft.PowerShell.Commands.PowerShellGet.InternalWebProxy' -as [Type]))
    {
        $ProxyNetworkCredential = $null
        if($ProxyCredential)
        {
            $ProxyNetworkCredential = $ProxyCredential.GetNetworkCredential()
        }

        $WebProxy = New-Object Microsoft.PowerShell.Commands.PowerShellGet.InternalWebProxy -ArgumentList $Proxy,$ProxyNetworkCredential
    }

    if(HttpClientApisAvailable)
    {
        $response = $null
        try
        {
            $handler = New-Object System.Net.Http.HttpClientHandler

            if($Credential)
            {
                $handler.Credentials = $Credential.GetNetworkCredential()
            }
            else
            {
                $handler.UseDefaultCredentials = $true
            }

            if($WebProxy)
            {
                $handler.Proxy = $WebProxy
            }

            $httpClient = New-Object System.Net.Http.HttpClient -ArgumentList $handler
            $response = $httpclient.GetAsync($endpoint)
        }
        catch
        {
        }

        if ($response -ne $null -and $response.result -ne $null)
        {
            $results.Add($Script:ResponseUri,$response.Result.RequestMessage.RequestUri.AbsoluteUri.ToString())
            $results.Add($Script:StatusCode,$response.result.StatusCode.value__)
        }
    }
    else
    {
        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::Create()
        $iss.types.clear()
        $iss.formats.clear()
        $iss.LanguageMode = "FullLanguage"

        $WebRequestcmd =  @'
            param($Credential, $WebProxy)

            try
            {{
                $request = [System.Net.WebRequest]::Create("{0}")
                $request.Method = 'GET'
                $request.Timeout = 30000
                if($Credential)
                {{
                    $request.Credentials = $Credential.GetNetworkCredential()
                }}
                else
                {{
                    $request.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
                }}

                $request.AllowAutoRedirect = ${1}

                if($WebProxy)
                {{
                    $request.Proxy = $WebProxy
                }}

                $response = [System.Net.HttpWebResponse]$request.GetResponse()
                if($response.StatusCode.value__ -eq 302)
                {{
                    $response.Headers["Location"].ToString()
                }}
                else
                {{
                    $response
                }}
                $response.Close()
            }}
            catch [System.Net.WebException]
            {{
                "Error:System.Net.WebException"
            }}
'@ -f $EndPoint, $AllowAutoRedirect

        $ps = [powershell]::Create($iss).AddScript($WebRequestcmd)

        if($WebProxy)
        {
            $null = $ps.AddParameter('WebProxy', $WebProxy)
        }

        if($Credential)
        {
            $null = $ps.AddParameter('Credential', $Credential)
        }

        $response = $ps.Invoke()
        $ps.dispose()
        if ($response -ne "Error:System.Net.WebException")
        {
            if($AllowAutoRedirect)
            {
                $results.Add($Script:ResponseUri,$response.ResponseUri.ToString())
                $results.Add($Script:StatusCode,$response.StatusCode.value__)
            }
            else
            {
                $results.Add($Script:ResponseUri,[String]$response)
            }
        }
    }
    return $results
}
