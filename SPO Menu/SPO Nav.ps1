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

# Convert password to secure string
$certPwd = ConvertTo-SecureString $CertificatePassword -AsPlainText -Force

Write-Host "Connecting to source hub..." -ForegroundColor Green

# Connect to source hub
$srcConn = Connect-PnPOnline -Url $SourceHubSiteUrl `
                             -ClientId $ClientId `
                             -Tenant $Tenant `
                             -CertificatePath $CertificatePath `
                             -CertificatePassword $certPwd `
                             -ReturnConnection

# Get navigation from source
$sourceNav = Get-PnPNavigationNode -Location TopNavigationBar -Connection $srcConn

Write-Host "Found $($sourceNav.Count) navigation items" -ForegroundColor Green
Write-Host "Connecting to target hub..." -ForegroundColor Green

# Connect to target hub
$targetConn = Connect-PnPOnline -Url $TargetHubSiteUrl `
                                -ClientId $ClientId `
                                -Tenant $Tenant `
                                -CertificatePath $CertificatePath `
                                -CertificatePassword $certPwd `
                                -ReturnConnection

# Copy each navigation item
foreach ($navItem in $sourceNav) {
    Write-Host "Copying: $($navItem.Title)" -ForegroundColor Cyan
    
    # Add main nav item
    $newNavItem = Add-PnPNavigationNode -Title $navItem.Title `
                                       -Url $navItem.Url `
                                       -Location TopNavigationBar `
                                       -External:$navItem.IsExternal `
                                       -Connection $targetConn
    
    # Get and copy sub-items
    $childItems = Get-PnPNavigationNode -Location TopNavigationBar -Connection $srcConn | Where-Object { $_.ParentId -eq $navItem.Id }
    
    foreach ($childItem in $childItems) {
        Write-Host "  Adding sub-item: $($childItem.Title)" -ForegroundColor Gray
        Add-PnPNavigationNode -Title $childItem.Title `
                             -Url $childItem.Url `
                             -Location TopNavigationBar `
                             -Parent $newNavItem.Id `
                             -External:$childItem.IsExternal `
                             -Connection $targetConn
    }
}

Write-Host "Navigation copy completed!" -ForegroundColor Green

and run it 
.\Copy-HubNav-Simple.ps1 -SourceHubSiteUrl "https://yourtenant.sharepoint.com/sites/SourceHub" `
                         -TargetHubSiteUrl "https://yourtenant.sharepoint.com/sites/TargetHub" `
                         -Tenant "yourtenant.onmicrosoft.com" `
                         -ClientId "your-client-id-here" `
                         -CertificatePath "C:\path\to\your\cert.pfx" `
                         -CertificatePassword "your-cert-password"
