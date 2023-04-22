[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$From = "no-reply@moorfields.nhs.uk"
$To = "sg@nhs.net"
$Subject = "Test Email @ " + (get-date).ToString()
$Body = "This is a test message!"
$SMTPServer = "smtp.moorfields.nhs.uk"
$SMTPPort = "25"
Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -DeliveryNotificationOption OnSuccess