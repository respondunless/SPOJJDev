# Copy-HubNavigation-RestMethod.ps1
# Copies hub navigation using native REST calls (works with older PnP versions)

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
    Write-Host "🔐 Starting hub navigation copy with REST method..." -ForegroundColor Green
    
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
    
    # Step 2: Get access token and retrieve navigation
    Write-Host "📥 Retrieving navigation structure..." -ForegroundColor Yellow
    $sourceToken = Get-PnPAccessToken
    
    $srcNavigation = Invoke-RestMethod `
        -Headers @{ Authorization = "Bearer $sourceToken" } `
        -Uri "$SourceHubUrl/_api/web/Navigation/TopNavigationBar" `
        -Method Get
    
    if (-not $srcNavigation -or -not $srcNavigation.value) {
        throw "Failed to retrieve navigation from source hub"
    }
    
    Write-Host "✅ Retrieved navigation data ($($srcNavigation.value.Count) root items)" -ForegroundColor Green
    
    # Step 3: Disconnect and connect to target hub
    Write-Host "🔄 Switching to target hub: $TargetHubUrl" -ForegroundColor Yellow
    Disconnect-PnPOnline
    
    Connect-PnPOnline `
        -Url $TargetHubUrl `
        -ClientId $ClientId `
        -Tenant $TenantId `
        -CertificatePath $CertificatePath `
        -CertificatePassword $securePassword
    
    # Step 4: Get target token and prepare payload
    Write-Host "📤 Preparing navigation payload..." -ForegroundColor Yellow
    $targetToken = Get-PnPAccessToken
    
    # Convert navigation array to JSON string (this is what SaveMenuState expects)
    $navigationJson = $srcNavigation.value | ConvertTo-Json -Compress -Depth 10
    
    # Create the envelope that SaveMenuState expects
    $payload = @{ 
        menuState = $navigationJson 
    } | ConvertTo-Json -Compress -Depth 10
    
    # Step 5: Save navigation to target hub
    Write-Host "💾 Saving navigation to target hub..." -ForegroundColor Yellow
    $response = Invoke-RestMethod `
        -Headers @{ 
            Authorization = "Bearer $targetToken"
            "Content-Type" = "application/json;odata=nometadata"
        } `
        -Uri "$TargetHubUrl/_api/Navigation/SaveMenuState" `
        -Method Post `
        -Body $payload
    
    Write-Host "🎉 Navigation successfully copied!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Depth 2)" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
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
    try { Disconnect-PnPOnline } catch { }
}
