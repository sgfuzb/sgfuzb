$cert=(Get-ChildItem cert:currentuser\my\ -CodeSigningCert)

Write-Host "=================================="
Write-Host "Cert Subject: " $cert[1].Subject
Write-Host "Cert Expires: " $cert[1].NotAfter
Write-Host "=================================="

Set-AuthenticodeSignature '\\installsvr\software\Java\Uninstall-Java8.ps1' -Certificate $cert[1]
#Set-AuthenticodeSignature M:\powershell\Install-RSAT-online.ps1 $cert
