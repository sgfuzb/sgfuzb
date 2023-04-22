#Get-ChildItem cert:\CurrentUser\TrustedPublisher

$path = "\\installsvr\software\Netcall"

$cert=(Get-ChildItem cert:currentuser\my\ -CodeSigningCert)

Write-Host "=================================="
Write-Host "Cert Subject: " $cert[1].Subject
Write-Host "Cert Expires: " $cert[1].NotAfter
Write-Host "=================================="

$files = Get-ChildItem -path $path -Recurse -Filter "*.ps1"

foreach ($file in $files) {

    Set-AuthenticodeSignature $file.FullName $cert[1] -timestampserver http://timestamp.digicert.com

}
