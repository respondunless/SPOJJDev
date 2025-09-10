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

# Get mega menu structure via REST API
$menuState = Invoke-PnPSPRestMethod -Url "/_api/navigation/menuState?mapId='GlobalNavSiteMapProvider'" -Method Get -Connection $srcConn
$sourceNav = $menuState.value.Nodes

Write-Host "✅ Found $($sourceNav.Count) navigation items in source" -ForegroundColor Green

Write-Host "🔗 Connecting to target hub: $TargetHubSiteUrl" -ForegroundColor Green
$targetConn = Connect-PnPOnline -Url $TargetHubSiteUrl `
                                -ClientId $ClientId `
                                -Tenant $Tenant `
                                -CertificatePath $CertificatePath `
                                -CertificatePassword $certPwd `
                                -ReturnConnection

# -------------------------------
# Recursive Copy Function
# -------------------------------
function Copy-NavNodeRecursively {
    param (
        $SourceNode,
        $TargetParentId,
        $targetConn
    )

    Write-Host "➕ Adding: $($SourceNode.Title)" -ForegroundColor Cyan

    $newNode = Add-PnPNavigationNode -Title $SourceNode.Title `
                                     -Url $SourceNode.SimpleUrl `
                                     -Location TopNavigationBar `
                                     -Parent $TargetParentId `
                                     -External:$SourceNode.IsExternal `
                                     -Connection $targetConn

    # Process children if they exist
    if ($null -ne $SourceNode.Children -and $SourceNode.Children.Count -gt 0) {
        foreach ($child in $SourceNode.Children) {
            Write-Host "   ↳ SubItem: $($child.Title)" -ForegroundColor Gray
            Copy-NavNodeRecursively -SourceNode $child -TargetParentId $newNode.Id -targetConn $targetConn
        }
    }
}

# -------------------------------
# Copy all root nodes + recurse
# -------------------------------
foreach ($navItem in $sourceNav) {
    Write-Host "`n📂 Root: $($navItem.Title)" -ForegroundColor Yellow
    Copy-NavNodeRecursively -SourceNode $navItem -TargetParentId 0 -targetConn $targetConn
}

Write-Host "`n🎉 Navigation copy completed (all levels)!" -ForegroundColor Green

and run it 
.\Copy-HubNav-Simple.ps1 -SourceHubSiteUrl "https://yourtenant.sharepoint.com/sites/SourceHub" `
                         -TargetHubSiteUrl "https://yourtenant.sharepoint.com/sites/TargetHub" `
                         -Tenant "yourtenant.onmicrosoft.com" `
                         -ClientId "your-client-id-here" `
                         -CertificatePath "C:\path\to\your\cert.pfx" `
                         -CertificatePassword "your-cert-password"
