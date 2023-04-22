#
# Use to check for broken Compucare, Medisoft, etc installs
#
# Steven Gill 12/10/21

$MaxRDSServer = 72
$Computernames = @()
$AllEvents = @()

For ($i = 1; $i -le $MaxRDSServer; $i++) {
    If ($i -lt 10) { $servername = "MEHRDS-0" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }
    $ComputerNames += $servername
}

$matchtext = "Word"
$computernames = "MEHdcnwp"

ForEach ($computer in $computernames){

#;ID=11729

    $EventInfo = Get-WinEvent -ErrorAction SilentlyContinue -ComputerName $computer -FilterHashTable @{LogName="Microsoft-Windows-TerminalServices-LocalSessionManager/Operational";ID=40,25} -MaxEvents 1000 
     # | Where-Object {$_.Message -match $matchtext }
     # | Select-Object -First 100
    
    if ($EventInfo.count -gt 0) {
        #$computer
        #$EventInfo

        Foreach ($event in $EventInfo){

            #$message = $Event.Message.Trim() -replace "`n|`r",","
            $Mess = $Event.Message.Trim() -split "`n"
            $AllEvents += [PSCustomObject]@{
                ServerName = $computer
                Time = $Event.TimeCreated
                ID = $Event.ID
                level = $Event.LevelDisplayName
                message0 = $mess[0]
                message1 = $mess[1]
                message2 = $mess[2]
                message3 = $mess[3]
                message4 = $mess[4]
                message5 = $mess[5]
            }
        }

        $EventInfo.clear()
    }   
}

$AllEvents | Out-GridView
#$AllEvents | Export-Csv -NoTypeInformation Get-RDSOfficeErrors.csv