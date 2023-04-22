$Logfile = "C:\MEH\DBClusterAlert.log"
$LogTime = Get-Date -Format "yyy-MM-dd hh:mm:ss"

Import-Module FailoverClusters
Get-ClusterLog -Node MEHSQL2.moorfields.nhs.uk -Destination C:\MEH -TimeSpan 1440
$message=(Get-Content -Path C:\MEH\MEHSQL2.moorfields.nhs.uk_cluster.log | Select-String -Pattern "SQL Server(.)*OnlinePending`-`->Online" | Out-String)

if ($message) { 
  $emailFrom = "DBCluster.Alerts@moorfields.nhs.uk"
  $emailTo = "moorfields.dbcluster.alerts@nhs.net"
  $subject="SQL 2014 Prod Cluster Failover Alert"
  $smtpserver="smtp.moorfields.nhs.uk" 
  Send-MailMessage -To $emailTo -Subject $subject -From $emailFrom -Body $message -SmtpServer $smtpserver
  Add-content $Logfile -value $message
} else {
  $message = $logtime + " No Change"
  Add-content $Logfile -value $message
  }

Remove-Item C:\MEH\MEHSQL2.moorfields.nhs.uk_cluster.log
