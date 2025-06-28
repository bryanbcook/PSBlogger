Function Invoke-GApi
{
    [CmdletBinding(DefaultParameterSetName="Uri")]
    param(
        [Parameter(Mandatory, ParameterSetName="Uri")]
        [Parameter(Mandatory, ParameterSetName="Body")]
        [Parameter(Mandatory, ParameterSetName="InFile")]
        [string]$uri,

        [Parameter(ParameterSetName="Body")]
        [string]$body,

        [Parameter(ParameterSetName="InFile")]
        [string]$InFile,

        [Parameter(ParameterSetName="Uri")]
        [Parameter(ParameterSetName="Body")]
        [Parameter(ParameterSetName="InFile")]
        [ValidateSet("GET", "POST", "PUT", "PATCH","DELETE")]
        [string]$method = "GET",

        [Parameter(ParameterSetName="Uri")]
        [Parameter(ParameterSetName="Body")]
        [Parameter(ParameterSetName="InFile")]
        [string]$ContentType = "application/json",

        [Parameter(ParameterSetName="Uri")]
        [Parameter(ParameterSetName="Body")]
        [Parameter(ParameterSetName="InFile")]
        [hashtable]$AdditionalHeaders = @{}
    )

    # obtain the auth-header
    $headers = Get-AuthHeader

    # Add any additional headers
    foreach ($key in $AdditionalHeaders.Keys) {
        $headers[$key] = $AdditionalHeaders[$key]
    }

    $invokeArgs = @{
        Uri = $uri
        Method = $method
        ContentType = $ContentType
        Headers = $headers
    }

    if ($body) {
        if ($method -eq "GET") {
            $invokeArgs.Method = "POST"
        }
        $invokeArgs.Body = $body
    }
    if ($InFile) {
        $invokeArgs.InFile = $InFile
    }


    Invoke-RestMethod @invokeArgs
}