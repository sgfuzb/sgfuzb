#######################################################
# Install MEH SSL cert and update IIS sites
# Steven Gill
# 20/09/22
#######################################################

$FileName = "MEH_SSL.pfx"
$CertPath = "\\installsvr\software\MEH_SSL_Wildcard_Certificate\cert-2209\" + $FileName
$SecurePassword = (ConvertTo-SecureString -String "c9%7hV=BKe" -Force -AsPlainText)

#$Servernames = Import-Csv ".\Install-MEHCert.csv"

$Servernames = "MEHLIBSIP3", "MEHLIBSIP4"

ForEach ($Server in $Servernames){

    # Copy temp pfx
    Copy-Item -Path $CertPath -Destination "\\$Server\c$\"

    # Install remote pfx
    $ScriptBlock = { 
        param ([SecureString] $password) 
        Get-Command -Module PKIClient;
        Import-PfxCertificate -FilePath 'c:\MEH_SSL.pfx' cert:\localMachine\my -Password $password
    }

    Invoke-command -ComputerName $Server -ScriptBlock $scriptblock -ArgumentList $SecurePassword

    # Remove old expired certs

    # Get-ChildItem cert:\localMachine\my | Where-Object {($_.NotAfter -lt (get-date)) -and ($_.Subject -like '*moorfields.nhs.uk*')} | Remove-Item

    # Remove temp pfx
    $file = "\\$Server\c$\" + $FileName
    Remove-Item -Path $file

}

break

# set binding - needs work to enumerate sites

$siteName = 'mywebsite'
$dnsName = 'www.mywebsite.ru'

# create the ssl certificate
$newCert = New-SelfSignedCertificate -DnsName $dnsName -CertStoreLocation cert:\LocalMachine\My

# get the web binding of the site
$binding = Get-WebBinding -Name $siteName -Protocol "https"

# set the ssl certificate
$binding.AddSslCertificate($newCert.GetCertHashString(), "my")

