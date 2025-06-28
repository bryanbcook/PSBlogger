Function Invoke-GApi
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$uri,

        [Parameter(ParameterSetName="Body")]
        [string]$body,

        [Parameter(ParameterSetName="InFile")]
        [string]$InFile,

        [Parameter()]
        [ValidateSet("GET", "POST", "PUT", "PATCH","DELETE")]
        [string]$method = "GET",

        [Parameter()]
        [string]$ContentType = "application/json",

        [Parameter(Mandatory=$false)]
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