param(
    [Parameter(Mandatory = $true)]
    [string]$SourceHubSiteUrl,

    [Parameter(Mandatory = $true)]
    [string]$TargetHubSiteUrl,

    [Parameter(Mandatory = $true)]
    [string]$Tenant,

    [Parameter(Mandatory = $true)]
    [string]$ClientId,

    [Parameter(Mandatory = $true)]
    [string]$CertificatePath,

    [Parameter(Mandatory = $true)]
    [string]$CertificatePassword
)

# Convert password to SecureString
$certPwd = ConvertTo-SecureString $CertificatePassword -AsPlainText -Force

Write-Host "🔗 Connecting to source hub: $SourceHubSiteUrl" -ForegroundColor Green
$srcConn = Connect-PnPOnline -Url $SourceHubSiteUrl `
                             -ClientId $ClientId `
                             -Tenant $Tenant `
                             -CertificatePath $CertificatePath `
                             -CertificatePassword $certPwd `
                             -ReturnConnection

Write-Host "📥 Reading navigation from source hub..." -ForegroundColor Yellow

try {
    # Get the raw JSON string directly to avoid object cycles
    # This is the key fix - using -Raw parameter to get pure JSON string
    $rawMenuStateJson = Invoke-PnPSPRestMethod -Url "/_api/navigation/menuState?mapId='GlobalNavSiteMapProvider'" `
                                               -Method Get `
                                               -Connection $srcConn `
                                               -Raw

    Write-Host "✅ Successfully retrieved navigation JSON ($($rawMenuStateJson.Length) characters)" -ForegroundColor Green

    # Parse the JSON to count nodes for display
    $menuStateObj = $rawMenuStateJson | ConvertFrom-Json
    Write-Host "✅ Found $($menuStateObj.Nodes.Count) root navigation items" -ForegroundColor Green

} catch {
    Write-Host "❌ Error reading navigation from source:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "🔗 Connecting to target hub: $TargetHubSiteUrl" -ForegroundColor Green
$targetConn = Connect-PnPOnline -Url $TargetHubSiteUrl `
                                -ClientId $ClientId `
                                -Tenant $Tenant `
                                -CertificatePath $CertificatePath `
                                -CertificatePassword $certPwd `
                                -ReturnConnection

Write-Host "📤 Preparing navigation data for target hub..." -ForegroundColor Yellow

# Create the proper JSON envelope that SaveMenuState expects
# Based on research: SaveMenuState expects { "menuState": "<json-string>" }
$savePayload = @{
    menuState = $rawMenuStateJson
} | ConvertTo-Json -Depth 2 -Compress

Write-Host "💾 Saving navigation to target hub..." -ForegroundColor Yellow

try {
    # Use -Content parameter (not -Body) and proper Content-Type
    $result = Invoke-PnPSPRestMethod -Url "/_api/navigation/SaveMenuState" `
                                     -Method Post `
                                     -ContentType "application/json;odata=verbose" `
                                     -Content $savePayload `
                                     -Connection $targetConn

    Write-Host "🎉 Hub navigation successfully copied!" -ForegroundColor Green
    Write-Host "   ✅ All navigation levels preserved" -ForegroundColor Green
    Write-Host "   ✅ Navigation structure maintained" -ForegroundColor Green

    # Display result details if available
    if ($result) {
        Write-Host "   ✅ Server response received" -ForegroundColor Green
    }

} catch {
    Write-Host "❌ Error saving navigation to target:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    # Additional debugging info
    Write-Host "`n🔍 Debug Info:" -ForegroundColor Yellow
    Write-Host "Source JSON size: $($rawMenuStateJson.Length) characters" -ForegroundColor Gray
    Write-Host "Payload size: $($savePayload.Length) characters" -ForegroundColor Gray
    Write-Host "Target URL: $TargetHubSiteUrl" -ForegroundColor Gray

    exit 1
}

Write-Host "`n📋 Summary:" -ForegroundColor Cyan
Write-Host "Source: $SourceHubSiteUrl" -ForegroundColor Gray
Write-Host "Target: $TargetHubSiteUrl" -ForegroundColor Gray
Write-Host "Navigation items copied: $($menuStateObj.Nodes.Count)" -ForegroundColor Gray
Write-Host "`n🔄 Please refresh your target hub site to see the changes" -ForegroundColor Yellow


and run it 
.\Copy-HubNav-Simple.ps1 -SourceHubSiteUrl "https://yourtenant.sharepoint.com/sites/SourceHub" `
                         -TargetHubSiteUrl "https://yourtenant.sharepoint.com/sites/TargetHub" `
                         -Tenant "yourtenant.onmicrosoft.com" `
                         -ClientId "your-client-id-here" `
                         -CertificatePath "C:\path\to\your\cert.pfx" `
                         -CertificatePassword "your-cert-password"
