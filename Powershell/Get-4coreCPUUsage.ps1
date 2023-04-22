#
# Get 4 coure CPU usage and email if > 95%
#

$message = ""
$Counters = (Get-Counter -ListSet Processor).PathsWithInstances | ? {$_ -match "% Processor Time"}
$CoreUsage = Get-Counter $Counters -SampleInterval 10 -MaxSamples 5 | `
Select-Object -ExpandProperty CounterSamples | Select-Object InstanceName, CookedValue | `
Group-Object -Property InstanceName | ForEach-Object {
    $Stats = $_.Group | Measure-Object -Property CookedValue -Average -Maximum
    $_ | Select-Object Name, @{L="Average"; E={[math]::round(($Stats).Average,2)}}, @{L="Maximum"; E={[math]::round(($Stats).Maximum,2)}}
}

$TotalAv = $coreusage[$CoreUsage.Count-1].Average
$FourCoreUsage = ($coreusage[0].Average + $coreusage[1].Average + $coreusage[2].Average + $coreusage[3].Average)/4

# First four cores > 95% for 10s
if ($FourCoreUsage -gt 95) {

    # ===================================================
    # Send email
    # ===================================================

    $message += "Server Name: " + (Get-ComputerInfo).CsDNSHostName + "<br>"
    $message += "First four cores > $FourCoreUsage% for 10s" + "<br>"
    $message += "Total CPU = $TotalAv%" + "<br>"

    $WhatIfPreference = $false
    $Message = "<html>" + $message + "</html>"
    #$Message | Out-File ".\Update-ADUserDetails.htm"

    $EmailSMTP = "smtp.moorfields.nhs.uk"
    $EmailFrom = "DBCluster.Alerts@moorfields.nhs.uk"
    $EmailTo = "moorfields.italerts@nhs.net"

    $rptDate=(Get-date)

    $messageParameters = @{ 
        Subject = "[SQL 4 core warning on " + $rptDate.ToString($cultureENGB) + "]"
        Body = $global:Message
        From = $EmailFrom
        To = $EmailTo
        SmtpServer = $EmailSMTP
    } 

    Send-MailMessage @messageParameters -BodyAsHtml

} else {
    Write-Host "All OK, First Four cores: $FourCoreUsage%, Total CPU: $TotalAv%"
}
