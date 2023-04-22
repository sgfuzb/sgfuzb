# Get smartcard logon certs from AD

$cultureENGB = New-Object System.Globalization.CultureInfo("en-GB")
$UserCertList =@()
$Message = ""

# get all enabled users

$users = Get-ADuser -Filter "Enabled -eq 'true'" -Properties DisplayName,mail,department,Company,Certificates,Enabled -SearchBase "DC=moorfields,DC=nhs,DC=uk"|
Select-Object enabled, name, displayName, mail, description, department, company, certificates

#$users = $users | Select-Object -First 10

#$users = "GILLS"

# check their newest certs and log expiry date
Foreach ($user in $users){

    $cert = $user.Certificates | 
        ForEach-Object {New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $_} | 
        Where-Object {$_.Extensions | Where-Object {$_.oid.friendlyname -match "Template" -and $_.Format(0) -match "MEH Smartcard User" }} | 
        Sort-Object $_.Notafter -Descending | 
        Select-Object -First 1

    If ($cert.notafter) { 
        $UserCertList += [PSCustomObject]@{
            User = $user.name
            Email = $user.mail
            CertExpiry = $cert.Notafter
            CertIssue = $cert.Notbefore
        }
    }
}

# Report those expiring +/- 30 days
$ExpStart = (Get-Date).AddDays(-30)
$ExpEnd = (Get-Date).AddDays(30)

# Report those issued in last 7 days
$IssStart = (Get-Date).AddDays(-7)
$IssEnd = (Get-Date).AddDays(0)

$ExpUserCerts = $UserCertList | Where-Object {($_.CertExpiry -gt $ExpStart) -and ($_.CertExpiry -lt $ExpEnd)} | Sort-Object -Descending -Property CertExpiry
$IssUserCerts = $UserCertList | Where-Object {($_.CertIssue -gt $IssStart) -and ($_.CertIssue -lt $IssEnd)} | Sort-Object -Descending -Property CertIssue


$Message = "Expiring Smartcard Certificates ("+$ExpUserCerts.Count+")<br>"
$Message += "between "+ $ExpStart.ToString($cultureENGB) + " and " + $ExpEnd.ToString($cultureENGB) + "<br>"
$Message += "<br>"

Foreach ($usercert in $ExpUserCerts) {
    $message += $usercert.User + "," + $usercert.Email + "," + $usercert.CertExpiry.ToString($cultureENGB) + "<br>"
}

$Message += "<br>"
$Message += "Issued Smartcard Certificates in last 7 days ("+$IssUserCerts.Count+")<br>"
$Message += "<br>"

Foreach ($usercert in $IssUserCerts) {
    $message += $usercert.User + "," + $usercert.Email + "," + $usercert.CertIssue.ToString($cultureENGB) + "<br>"
}

$Groupmembers = Get-ADGroupMember -Identity "TSG-Password" | Select-Object name

$Message += "<br>"
$Message += "Members of TSG-Password Group ("+$Groupmembers.Count+")<br>"
$Message += "<br>"

Foreach ($Member in $Groupmembers) {
    $ADUser = Get-ADuser -Identity $Member.Name -Properties mail
    $message += $Member.Name + "," + $ADUser.mail + "<br>"
}

$message += "<br>"
$message += "END"

If ($Message -ne "") {

    #Settings for Email Message
    $rptDate = Get-date
    $messageParameters = @{ 
        Subject = "[Expiring Smartcard Certificates ("+$ExpUserCerts.Count+") on " + $rptDate.ToString($cultureENGB) + "]"
        Body = $Message
        From = "it.alerts@moorfields.nhs.uk" 
        To = "moorfields.italerts@nhs.net"
        #To = "moorfields.italerts@nhs.net", "d.rubinstein1@nhs.net", "hunain.dosani@nhs.net"
        SmtpServer = "smtp.moorfields.nhs.uk"
        #SmtpServer = "127.0.0.1"
    } 
    #Send Report Email Message
    Send-MailMessage @messageParameters -BodyAsHtml
}
