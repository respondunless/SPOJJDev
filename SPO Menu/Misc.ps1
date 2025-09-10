# Copy-HubNavigation-AppAuth.ps1
# Copies hub navigation from source to target using Entra app authentication

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
    Write-Host "🔐 Starting hub navigation copy with app authentication..." -ForegroundColor Green
    
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
    
    # Step 2: Get raw navigation JSON from source
    Write-Host "📥 Retrieving navigation structure..." -ForegroundColor Yellow
    $srcNavRaw = Invoke-PnPRestMethod -Url "/_api/web/Navigation/TopNavigationBar" -Method Get -Raw
    
    if (-not $srcNavRaw) {
        throw "Failed to retrieve navigation from source hub"
    }
    
    Write-Host "✅ Retrieved navigation data ($(($srcNavRaw | ConvertFrom-Json).Count) root items)" -ForegroundColor Green
    
    # Step 3: Disconnect and connect to target hub
    Write-Host "🔄 Switching to target hub: $TargetHubUrl" -ForegroundColor Yellow
    Disconnect-PnPOnline
    
    Connect-PnPOnline `
        -Url $TargetHubUrl `
        -ClientId $ClientId `
        -Tenant $TenantId `
        -CertificatePath $CertificatePath `
        -CertificatePassword $securePassword
    
    # Step 4: Prepare payload for SaveMenuState
    Write-Host "📤 Preparing navigation payload..." -ForegroundColor Yellow
    $payload = @{ 
        menuState = $srcNavRaw 
    } | ConvertTo-Json -Compress -Depth 10
    
    # Step 5: Save navigation to target hub
    Write-Host "💾 Saving navigation to target hub..." -ForegroundColor Yellow
    $response = Invoke-PnPRestMethod `
        -Url "/_api/Navigation/SaveMenuState" `
        -Method Post `
        -ContentType "application/json;odata=nometadata" `
        -Body $payload
    
    Write-Host "🎉 Navigation successfully copied!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Depth 2)" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $($_.Exception)" -ForegroundColor Red
} finally {
    # Clean up connection
    try { Disconnect-PnPOnline } catch { }
}
