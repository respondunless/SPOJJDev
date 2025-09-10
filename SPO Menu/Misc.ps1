# Copy-HubNavigation-CycleSafe.ps1
# Copies hub navigation using raw JSON to avoid object cycle issues

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceHubUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetHubUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientId,
    
    [Parameter(Mandatory=$true)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$CertificatePath,
    
    [Parameter(Mandatory=$true)]
    [string]$CertificatePassword
)

try {
    Write-Host "🔐 Starting cycle-safe hub navigation copy..." -ForegroundColor Green
    
    # Convert certificate password to secure string
    $securePassword = ConvertTo-SecureString $CertificatePassword -AsPlainText -Force
    
    # Step 1: Connect to source hub
    Write-Host "📡 Connecting to source hub: $SourceHubUrl" -ForegroundColor Yellow
    Connect-PnPOnline `
        -Url $SourceHubUrl `
        -ClientId $ClientId `
        -Tenant $TenantId `
        -CertificatePath $CertificatePath `
        -CertificatePassword $securePassword
    
    # Step 2: Get access token and retrieve RAW navigation (no deserialization)
    Write-Host "📥 Retrieving navigation structure as raw JSON..." -ForegroundColor Yellow
    $sourceToken = Get-PnPAccessToken
    
    # Use Invoke-WebRequest to get raw JSON string (avoids object cycles)
    $srcNavigationRaw = Invoke-WebRequest `
        -Headers @{ Authorization = "Bearer $sourceToken" } `
        -Uri "$SourceHubUrl/_api/web/Navigation/TopNavigationBar" `
        -Method Get
    
    if (-not $srcNavigationRaw.Content) {
        throw "Failed to retrieve navigation from source hub"
    }
    
    # Parse just enough to count items for feedback
    $tempNav = $srcNavigationRaw.Content | ConvertFrom-Json
    Write-Host "✅ Retrieved raw navigation JSON ($($tempNav.value.Count) root items, $($srcNavigationRaw.Content.Length) chars)" -ForegroundColor Green
    
    # Step 3: Disconnect and connect to target hub
    Write-Host "🔄 Switching to target hub: $TargetHubUrl" -ForegroundColor Yellow
    Disconnect-PnPOnline
    
    Connect-PnPOnline `
        -Url $TargetHubUrl `
        -ClientId $ClientId `
        -Tenant $TenantId `
        -CertificatePath $CertificatePath `
        -CertificatePassword $securePassword
    
    # Step 4: Get target token and prepare payload with raw JSON
    Write-Host "📤 Preparing navigation payload with raw JSON..." -ForegroundColor Yellow
    $targetToken = Get-PnPAccessToken
    
    # Extract just the 'value' array from the raw JSON response
    $navObject = $srcNavigationRaw.Content | ConvertFrom-Json
    $navigationArrayJson = $navObject.value | ConvertTo-Json -Compress -Depth 10
    
    # Create the envelope that SaveMenuState expects (menuState as string)
    $payload = @{ 
        menuState = $navigationArrayJson 
    } | ConvertTo-Json -Compress -Depth 10
    
    Write-Host "Payload preview (first 200 chars): $($payload.Substring(0, [Math]::Min(200, $payload.Length)))" -ForegroundColor Gray
    
    # Step 5: Save navigation to target hub
    Write-Host "💾 Saving navigation to target hub..." -ForegroundColor Yellow
    
    # Use Invoke-WebRequest for better error handling
    $response = Invoke-WebRequest `
        -Headers @{ 
            Authorization = "Bearer $targetToken"
            "Content-Type" = "application/json;odata=nometadata"
            "Accept" = "application/json;odata=nometadata"
        } `
        -Uri "$TargetHubUrl/_api/Navigation/SaveMenuState" `
        -Method Post `
        -Body $payload
    
    Write-Host "🎉 Navigation successfully copied!" -ForegroundColor Green
    Write-Host "HTTP Status: $($response.StatusCode)" -ForegroundColor Cyan
    Write-Host "Response: $($response.Content)" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    
    # Enhanced error reporting for web requests
    if ($_.Exception -is [Microsoft.PowerShell.Commands.HttpResponseException]) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "HTTP Status: $statusCode" -ForegroundColor Red
        
        # Common error translations
        switch ([int]$statusCode) {
            401 { Write-Host "💡 Suggestion: Authentication failed - check app registration and certificate" -ForegroundColor Yellow }
            403 { Write-Host "💡 Suggestion: Check app permissions (Sites.FullControl.All) and admin consent" -ForegroundColor Yellow }
            400 { Write-Host "💡 Suggestion: Payload format issue - navigation structure might be incompatible" -ForegroundColor Yellow }
            404 { Write-Host "💡 Suggestion: Endpoint not found - site might not be a hub or using different navigation type" -ForegroundColor Yellow }
        }
        
        # Try to get response body
        try {
            $errorContent = $_.ErrorDetails.Message
            if ($errorContent) {
                Write-Host "Error details: $errorContent" -ForegroundColor Red
            }
        } catch {
            Write-Host "Could not read error details" -ForegroundColor Red
        }
    }
    
    # Legacy error handling for older PowerShell versions
    elseif ($_.Exception.Response) {
        Write-Host "HTTP Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            Write-Host "Error details: $errorBody" -ForegroundColor Red
        } catch {
            Write-Host "Could not read error details" -ForegroundColor Red
        }
    }
    
} finally {
    # Clean up connection
    try { 
        Disconnect-PnPOnline 
        Write-Host "🔌 Disconnected from SharePoint" -ForegroundColor Gray
    } catch { }
}
