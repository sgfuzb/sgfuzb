################################
# Check RDS disonnect errors
#
# Steven Gill 03/11/22
################################

$MaxRDSServer = 72
$Computernames = @()
$AllEvents = @()

$lastxdays = 1
$MaxEvents = 1000

For ($i = 1; $i -le $MaxRDSServer; $i++) {
    If ($i -lt 10) { $servername = "MEHRDS-0" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }
    $ComputerNames += $servername
}

# Level Error = 2
# Go to log properties and get "full name"

#RDS
$LogFilters = @{LogName="Microsoft-Windows-TerminalServices-LocalSessionManager/Operational";ID=40}, # Session xx has been disconnected, reason code xx
@{LogName="Microsoft-Windows-TerminalServices-LocalSessionManager/Operational";ID=24}, # Remote Desktop Services: Session has been disconnected:
@{LogName="Microsoft-Windows-TerminalServices-LocalSessionManager/Operational";ID=21} # Remote Desktop Services: Session logon succeeded:

<#
http://woshub.com/rdp-connection-logs-forensics-windows/

EventID – 40 (Session <A> has been disconnected, reason code <B>). Here you must check the disconnection reason code in the event description. For example:
reason code 0 (No additional information is available) means that a user has just closed the RDP client window;
reason code 5 (The client’s connection was replaced by another connection) means that a user has reconnected to the previous RDP session;
reason code 11 (User activity has initiated the disconnect) a user has clicked the Disconnect button in the start menu.
#>


$computercount = $Computernames.Count
#$filtercount = $LogFilters.Count

ForEach ($computer in $computernames){

    # Generate progress bar
    $Index = [array]::IndexOf($Computernames,$computer)
    $Percentage = $Index / $computercount
    $Message = "Reading event logs ($Index of $computercount)"
    Write-Progress -Activity $Message -PercentComplete ($Percentage * 100) -CurrentOperation $computer -id 1
    
    $EventInfo = Get-WinEvent -ErrorAction SilentlyContinue -ComputerName $computer -FilterHashTable $LogFilters -MaxEvents $MaxEvents `
            | Where-Object {((get-date).DayOfYear - $_.TimeCreated.DayOfYear ) -le $lastxdays} 
            #| Where-Object {$_.Message -match $matchtext } 
            #| Select-Object -First 10
    
    If ($EventInfo.count -gt 0) {
        
        ForEach ($event in $EventInfo) {

            try {
                #$username = (New-Object System.Security.Principal.SecurityIdentifier $event.UserId.Value).Translate([System.Security.Principal.NTAccount]).Value
            } catch {
                #$username = ""
            }

            switch ($event.Id) {
                21 {
                    $username = $Event.Properties.value[0]
                    $sessionID = $Event.Properties.value[1]
                    $SourceIP = $Event.Properties.value[2]
                    $disconnectreason = ""
                }
                24 { 
                    $username = $Event.Properties.value[0]
                    $sessionID = $Event.Properties.value[1]
                    $SourceIP = $Event.Properties.value[2]
                    $disconnectreason = ""
                 }
                40 {
                    #$username = ""
                    $sessionID = $Event.Properties.value[0]
                    #$SourceIP = ""
                    $disconnectreason = $Event.Properties.value[1]
                }
                Default {}
            } 

            #$Event.Properties.value[0]
            #$Event.Properties.value[1]
            #$Event.Properties.value[2]

            $AllEvents += [PSCustomObject]@{
                ComputerName = $computer
                Log = $event.LogName
                EventID = $event.Id
                Datetime = $event.TimeCreated
                User = $username
                SessionID = $sessionID
                SourceIP = $SourceIP
                DisconReason = $disconnectreason
                Message = $event.Message
            }
        }
        #$EventInfo.clear()
    }   
}

Write-Progress -Id 1 -Status "Ready" -Activity "Complete" -Completed
Write-Host  "Done - See Gridview!"
$output = $AllEvents | Sort-Object -Property Computername, DateTime -Descending
$output | Export-Csv -NoTypeInformation -Force "Get-RDSDisconnects.csv"
$output | Out-GridView
