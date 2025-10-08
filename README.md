# SPOJJDev
SPO Dev for development for use online


Working with CAD files in SharePoint (SPO) is a bad idea because it lacks proper file locking mechanisms, leading to work loss and data corruption, as well as issues with OneDrive syncing, poor performance with large files and xrefs, and unreliable support for non-Microsoft desktop applications. Instead, use a dedicated CAD product lifecycle management (PLM) system like Autodesk Vault or a properly configured on-premise server.  
Why SPO is problematic for CAD files
Lack of Native File Locking: Unlike Word or Excel, DWG files don't have native support for the kind of robust file locking that SharePoint offers for Microsoft Office documents. This means:
Multiple users can open the same file, leading to conflicts and lost work. 
