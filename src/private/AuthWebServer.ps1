Function Wait-GoogleAuthApiToken
{
  param(
    [int]$Port = 80
  )

  $ErrorActionPreference = 'Stop'

  try {
    $HttpListener = New-Object System.Net.HttpListener
    $HttpListener.Prefixes.Add("http://+:$Port/")
    Write-Information "Waiting for auth flow in browser to complete..."
    $HttpListener.Start()
  
    $authCodeReceived = $False
  
    while ($HttpListener.IsListening -and -not $authCodeReceived) {
      $HttpContext = $HttpListener.GetContext()
      $HttpRequest = $HttpContext.Request      
      $Query = $HttpRequest.QueryString

      if ($null -ne $Query["code"]) {
        $authCode = $Query["code"]
        Write-Output $authCode
        Write-Verbose "Received auth-code: $authCode"
        $authCodeReceived = $true

        # Send "Thanks!"
        $buffer = [System.Text.Encoding]::UTF8.GetBytes("<html><body>Good Job! Successfully authorized PSBlogger. You can close this browser window now.</body></html>")
        $response = $HttpContext.Response
        $response.ContentLength64 = $buffer.Length
        $output = $response.OutputStream;
        $output.Write($buffer,0,$buffer.Length)
        $output.Close() | Write-Verbose 
      }      
    }
  
    Write-Verbose "Stopping HttpListener."
    $HttpListener.Stop()
    Write-Verbose "Stopped HttpListener."
  }
  catch {
    Write-Error $_.ToString()
  }
  finally {
    if ($null -ne $HttpListener) {
      Write-Verbose "Disposing HttpListener"
      $HttpListener.Dispose()
      $HttpListener = $null
    }
  }

}