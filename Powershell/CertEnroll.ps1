[string]$TemplateName = "MEH Smartcard User"
[string]$CAName = "mehca2.moorfields.nhs.uk\Moorfields Eye Hospital Issuing CA 2"
[string]$UID = read-host "Please enter the UID"
[string]$Email = read-host "Please enter the user's Email Address"

###################################
# Generate Request File
###################################
write-host
write-host "Generating Request File" -ForegroundColor Yellow

remove-item .\supusercert.inf -ErrorAction silentlycontinue
remove-item .\supusercert.req -ErrorAction silentlycontinue

add-content .\supusercert.inf "[NewRequest]`r
Subject = `"CN=$UID`"`r
Exportable = TRUE`r 
RequestType = CMC`r
[RequestAttributes]`r
CertificateTemplate = `"$TemplateName`"`r
SAN = `"Email=$Email`""

.\certreq -new .\usercert.inf .\usercert.req

###################################
# Send Request
###################################
write-host "Sending Certificate Request" -ForegroundColor Yellow

.\certreq -submit -config "$CAName" .\supusercert.req .\$UID.cer

###################################
# Install Certificate
###################################
write-host "Installing Certificate" -ForegroundColor Yellow

.\certreq -accept .\$UID.cer<br/>



<#

# https://www.sysadmins.lv/blog-en/introducing-to-certificate-enrollment-apis-part-5-enroll-on-behalf-of.aspx

$PKCS10 = New-Object -ComObject X509Enrollment.CX509CertificateRequestPkcs10
$PKCS10.InitializeFromTemplateName(0x1,"MEH Smartcard User")
$PKCS10.Encode()
$pkcs7 = New-Object -ComObject X509enrollment.CX509CertificateRequestPkcs7
$pkcs7.InitializeFromInnerRequest($pkcs10)
$pkcs7.RequesterName = "city_road\adminsg"
$signer = New-Object -ComObject X509Enrollment.CSignerCertificate
$cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object {$_.Extensions | Where-Object {$_.Oid.Value -eq "2.5.29.37" -and $_.EnhancedKeyUsages["1.3.6.1.4.1.311.20.2.1"]}}
$Base64 = [Convert]::ToBase64String($Cert.RawData)
$signer = New-Object -ComObject X509Enrollment.CSignerCertificate
$signer.Initialize(0,0,1,$Base64)
#$signer.Initialize(0,0,0xc,"3A47D2C3CF064E13FE90442DA77412CBC5FA8824")
$pkcs7.SignerCertificate = $signer
$Request = New-Object -ComObject X509Enrollment.CX509Enrollment
$Request.InitializeFromRequest($pkcs7)
$Request.Enroll()
#>