[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$From = "sg@moorfields.nhs.uk"
$To = "sg@nhs.net"
$Subject = "Test Email @ " + (get-date).ToString()
$Body = "This is a test message!"
$SMTPServer = "MEHSMTP"
$SMTPPort = "25"
Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort –DeliveryNotificationOption OnSuccess