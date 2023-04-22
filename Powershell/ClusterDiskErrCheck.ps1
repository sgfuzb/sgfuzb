# Get CLuster CSV error logs
# Steven Gill Nov 2020

$whatifpreference = $true

$ClusterServers =
"MEHSQL1", "MEHSQL2", 
"MEHSQLDEV1", "MEHSQLDEV2", 
"MEHSQL3", "MEHSQL4", 
"MEHSQLDEV3", "MEHSQLDEV4", 
"MEHVMC3", "MEHVMC4", "MEHVMC5", "MEHVMC6", "MEHVMC7", "MEHVMC8", "MEHVMC9", "MEHVMC10"

# Override for testing
#$ClusterServers = "MEHVMC8"

$BaseDir = "C:\MEH\"
$message = $null
$numerrors = 0

Import-Module FailoverClusters

$Message = "<br>"
$Message += "===================================================<br>"
$Message += "Cluster CSV Errors <br><br>"
$Message += "===================================================<br>"

ForEach($Cluster in $ClusterServers)
{
  Try {
    Get-ClusterLog -Node $Cluster -TimeSpan 1440 -Destination $basedir

    $logname = $BaseDir + $cluster + "_cluster.log"

    $pattern1 = "CSV-VM", "Cluster Shared Volume"
    $pattern2 = " ERR ", " WARN "

    $thislog = (Get-Content -Path $logname | Select-String -Pattern $pattern1 )
    $thislog = ($thislog | Select-String -Pattern $pattern2 | Out-String)

    $thisnumerrors = ($thislog | Measure-Object -Line).Lines
    $numerrors += $thisnumerrors

    $Message += "===================================================<br>"
    $Message += $Cluster + " Errors: "+$thisnumerrors + "<br>"
    $Message += "===================================================<br>"
    $Message += $thislog + "<br>"

    Remove-Item $logname
  } Catch {
      $message += $cluster + " : " + $Error[0]
  }
}

$Message += "===================================================<br>"
$Message +=  "Errors: " + $numerrors + "<br>"
$Message +=  "DONE!!" + "<br>"

#Settings for Email Message
$rptDate=(Get-date)
if ($whatifpreference -eq 1) {
    $subjectprefix = "###TEST### " 
    $Message
} else {$subjectprefix = "" } 

$messageParameters = @{ 
    Subject = "[" + $subjectprefix + "Cluster CSV Errors " + $rptDate.ToString($cultureENGB) + "]"
    Body = $Message
    From = "DBCluster.Alerts@moorfields.nhs.uk" 
    #To = "moorfields.italerts@nhs.net"
    To = "sg@nhs.net"
    SmtpServer = "smtp.moorfields.nhs.uk"
    #SmtpServer = "127.0.0.1"
} 
#Send Report Email Message
Send-MailMessage @messageParameters -BodyAsHtml
