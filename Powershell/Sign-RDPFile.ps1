#
# Sign RDP file using installed Cert
#

$FileToSign = "m:\temp\RDSTEST-01-NLASSO.rdp"

#$CertThumb = (Get-ChildItem cert:\localMachine\my | Where-Object {($_.Subject -like '*moorfields.nhs.uk*')} | Sort-Object -Property NotAfter | Select-Object -First 1).Thumbprint
$CertThumb = (Get-ChildItem cert:currentuser\my\ -CodeSigningCert | Sort-Object -Property NotAfter | Select-Object -First 1).Thumbprint

$command = "cmd.exe /C C:\windows\system32\rdpsign.exe /sha256 " + $CertThumb + " " + $FileToSign
Invoke-Expression -Command:$command
