Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/SourceHub" -ClientId <...> -Tenant <...> -CertificatePath <...> -CertificatePassword <...>
Get-PnPNavigationNode -Location TopNavigationBar | Format-Table Id, Title, Url, ParentId
