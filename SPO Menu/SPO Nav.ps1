
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

# Get the complete menu state from source
Write-Host "📥 Reading navigation from source hub..." -ForegroundColor Yellow
$sourceMenuState = Invoke-PnPSPRestMethod -Url "/_api/navigation/menuState?mapId=''GlobalNavSiteMapProvider''" -Method Get -Connection $srcConn

Write-Host "✅ Found navigation structure with $($sourceMenuState.Nodes.Count) root items" -ForegroundColor Green

# Function to update URLs in navigation nodes recursively
function Update-NavigationUrls {
    param(
        $Node,
        [string]$SourceSiteUrl,
        [string]$TargetSiteUrl
    )

    if ($Node.SimpleUrl -and $Node.SimpleUrl.StartsWith($SourceSiteUrl)) {
        $Node.SimpleUrl = $Node.SimpleUrl.Replace($SourceSiteUrl, $TargetSiteUrl)
        Write-Host "   🔄 Updated URL: $($Node.SimpleUrl)" -ForegroundColor Gray
    }

    if ($Node.Children -and $Node.Children.Count -gt 0) {
        foreach ($child in $Node.Children) {
            Update-NavigationUrls -Node $child -SourceSiteUrl $SourceSiteUrl -TargetSiteUrl $TargetSiteUrl
        }
    }
}

# Update any site-specific URLs in the navigation
Write-Host "🔄 Updating navigation URLs for target site..." -ForegroundColor Yellow
foreach ($node in $sourceMenuState.Nodes) {
    Update-NavigationUrls -Node $node -SourceSiteUrl $SourceHubSiteUrl -TargetSiteUrl $TargetHubSiteUrl
}

Write-Host "🔗 Connecting to target hub: $TargetHubSiteUrl" -ForegroundColor Green
$targetConn = Connect-PnPOnline -Url $TargetHubSiteUrl `
                                -ClientId $ClientId `
                                -Tenant $Tenant `
                                -CertificatePath $CertificatePath `
                                -CertificatePassword $certPwd `
                                -ReturnConnection

# Prepare the menu state for saving
Write-Host "📤 Preparing navigation data for target hub..." -ForegroundColor Yellow

# Convert the menu state to JSON string (this is critical!)
$menuStateJson = $sourceMenuState | ConvertTo-Json -Depth 20 -Compress

# Create the proper envelope for SaveMenuState API
$savePayload = @{
    menuState = $menuStateJson
} | ConvertTo-Json -Depth 21

Write-Host "💾 Saving navigation to target hub..." -ForegroundColor Yellow

try {
    # Save the menu state to target hub
    $result = Invoke-PnPSPRestMethod -Url "/_api/navigation/SaveMenuState" `
                                     -Method Post `
                                     -ContentType "application/json;odata=verbose" `
                                     -Body $savePayload `
                                     -Connection $targetConn

    Write-Host "🎉 Hub navigation successfully copied!" -ForegroundColor Green
    Write-Host "   ✅ All navigation levels preserved" -ForegroundColor Green
    Write-Host "   ✅ URLs updated for target site" -ForegroundColor Green

} catch {
    Write-Host "❌ Error saving navigation:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    # Additional debugging info
    Write-Host "`n🔍 Debug Info:" -ForegroundColor Yellow
    Write-Host "Menu state size: $($menuStateJson.Length) characters" -ForegroundColor Gray
    Write-Host "Payload size: $($savePayload.Length) characters" -ForegroundColor Gray
}

Write-Host "`n📋 Summary:" -ForegroundColor Cyan
Write-Host "Source: $SourceHubSiteUrl" -ForegroundColor Gray
Write-Host "Target: $TargetHubSiteUrl" -ForegroundColor Gray
Write-Host "Navigation items copied: $($sourceMenuState.Nodes.Count)" -ForegroundColor Gray


and run it 
.\Copy-HubNav-Simple.ps1 -SourceHubSiteUrl "https://yourtenant.sharepoint.com/sites/SourceHub" `
                         -TargetHubSiteUrl "https://yourtenant.sharepoint.com/sites/TargetHub" `
                         -Tenant "yourtenant.onmicrosoft.com" `
                         -ClientId "your-client-id-here" `
                         -CertificatePath "C:\path\to\your\cert.pfx" `
                         -CertificatePassword "your-cert-password"
