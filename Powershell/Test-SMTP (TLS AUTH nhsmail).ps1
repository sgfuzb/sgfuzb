[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$From = "sg@nhs.net"
$To = "sg@nhs.net"
$Subject = "Test Email @ " + (get-date).ToString()
$Body = "This is a test message!"
$SMTPServer = "send.nhs.net"
$SMTPPort = "587"
Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential (Get-Credential) -DeliveryNotificationOption OnSuccess

break

$From = "moorfields.ssrs@nhs.net"
$To = "sg@nhs.net"
$Subject = "Test Email @ " + (get-date).ToString()
$Body = "This is a test message!"
$SMTPServer = "smtp.office365.com"
$SMTPPort = "587"
Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential (Get-Credential) -DeliveryNotificationOption OnSuccess

break
