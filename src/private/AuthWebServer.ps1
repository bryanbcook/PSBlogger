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
      # Use async method with timeout to allow for cancellation
      $contextTask = $HttpListener.GetContextAsync()
      
      # Wait for either a request or cancellation (check every 500ms)
      while (-not $contextTask.IsCompleted) {
        Start-Sleep -Milliseconds 500
        
        # Check if user pressed Ctrl+C by testing if we can write to console
        try {
          [Console]::TreatControlCAsInput = $false
          if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq 'C' -and $key.Modifiers -eq 'Control') {
              Write-Information "`nCancellation requested. Stopping auth server..."
              return $null
            }
          }
        }
        catch {
          # Ignore console access errors
        }
      }
      
      if ($contextTask.IsCompleted) {
        $HttpContext = $contextTask.Result
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
    }
    Write-Verbose "Stopping HttpListener."
    $HttpListener.Stop()
    Write-Verbose "Stopped HttpListener."
  }
  catch {
    # TODO: Catch Permission denied error and warn about running from an elevated prompt
    # or add Requires -Administrator
    Write-Error $_.ToString() -ErrorAction Stop
  }
  finally {
    if ($null -ne $HttpListener) {
      Write-Verbose "Disposing HttpListener"
      $HttpListener.Dispose()
      $HttpListener = $null
    }
  }

}