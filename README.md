# SPOJJDev
SPO Dev for development for use online


Working with CAD files in SharePoint (SPO) is a bad idea because it lacks proper file locking mechanisms, leading to work loss and data corruption, as well as issues with OneDrive syncing, poor performance with large files and xrefs, and unreliable support for non-Microsoft desktop applications. Instead, use a dedicated CAD product lifecycle management (PLM) system like Autodesk Vault or a properly configured on-premise server.  
Why SPO is problematic for CAD files
Lack of Native File Locking: Unlike Word or Excel, DWG files don't have native support for the kind of robust file locking that SharePoint offers for Microsoft Office documents. This means:
Multiple users can open the same file, leading to conflicts and lost work. 
No reliable way to prevent others from editing a file, resulting in overwritten work. 
OneDrive Sync Issues: The OneDrive sync client, which is essential for working with SPO, struggles with the unique file structure and large file sizes of CAD projects. 
Syncing problems: can lead to files being lost, disappearing, or not syncing correctly. 
Sync client instability: can cause the entire system to hang or lock up when working with large files and complex XREFs (external references). 
Performance and Latency:
Slowdowns and hangs: are common when working with large CAD files or files with many xrefs over a network connection. 
High latency: significantly impacts the user experience and can make file operations unreliable. 
Limited Support for Non-Microsoft Applications: SharePoint is designed for Microsoft Office files and does not natively support in-browser editing for AutoCAD files. 
Opening or saving DWG files via the web browser can be problematic, sometimes defaulting to the AutoCAD Web App and requiring authentication. 
The "open with client applications" feature may not work for non-Microsoft programs like AutoCAD. 
