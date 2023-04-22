
# From https://social.technet.microsoft.com/Forums/ie/en-US/c1d825aa-f946-427c-bd81-cf3a18908651/server-2016-unable-to-add-rsat-role-the-referenced-assembly-could-not-be-found-error?forum=winservermanager

$WhatIfPreference = $true

#Read CBS log file contents into memory
try {$Contents = [System.IO.File]::ReadLines('C:\Windows\Logs\CBS\CBS.log')} catch {"File is currently in use.  Re-run script in 2 minutes.";return}
#Parse log file for missing assemblies
$InterestingLines = $Contents | Select-String -SimpleMatch '(ERROR_SXS_ASSEMBLY_MISSING)'

#Retrieve unique Package names from error messages
$Packages = @()
foreach ($Line in $InterestingLines) {
    $Package  = $(($Line -split("'") )[1])
    $Package = $Package.Substring(0,$Package.Length - ($Package.split(".")[4]).Length - 1)
    if ($Packages -notcontains $Package) { $Packages += $Package }
}

$AllKeys = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackageDetect', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages')

foreach ($RegRoot in $AllKeys) {
    $Keys = Get-ChildItem $RegRoot | Where-Object {$_.PSIsContainer}
    foreach ($Key in $Keys) {
    #write-host "Checking $($Key.name)" -ForegroundColor Blue
        foreach ($Package in $Packages) {
            foreach ($Property in $Key.Property) {
                #write-Host "$Property ? $Package" -ForegroundColor blue
                if ($Property -match $Package) {
                    $ShortTarget = $($Key.Name).Substring(87) 
                    write-host "Found $Package in $ShortTarget...  " -ForegroundColor Yellow -NoNewline
                    $Target = $($Key.Name).TrimStart("HKEY_LOCAL_MACHINE\\")
                    try {
                        
                        if ($WhatIfPreference -eq $false){
                            # Attempt to give Admins full control of key and delete key.
                            $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($Target,[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::ChangePermissions)
                            $acl = $key.GetAccessControl()
                            $rule = New-Object System.Security.AccessControl.RegistryAccessRule ("BUILTIN\Administrators","FullControl","Allow")
                            $acl.SetAccessRule($rule)
                            $key.SetAccessControl($acl)
                        }
                        Remove-ItemProperty -Path "HKLM:\$Target" -Name $Package -Force
                        Write-Host "delete successful." -ForegroundColor Green
                    } catch {
                        Write-Host "delete failed.  Delete manually." -ForegroundColor Red
                    }
                }
            }
        }
    }
}