################################
# Use to check for broken Compucare, Medisoft, etc installs
# Use to check for failed printer installs
#
# Steven Gill 12/10/21
################################

$MaxRDSServer = 79
$Computernames = @()
$AllEvents = @()

$lastxdays = 3
$MaxEvents = 100

For ($i = 1; $i -le $MaxRDSServer; $i++) {
    If ($i -lt 10) { $servername = "MEHRDS-0" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }
    $ComputerNames += $servername
}

#$ComputerNames = "MEHHEYEX2"

# Level Error = 2
# Go to log properties and get "full name"

#RDS
$LogFilters =
@{LogName="Application";ID=11729}, # MSI Installer Configuration failed.
@{LogName="Application";ID=11706}, # MSI Installer ?
@{LogName="Application";ID=1000}, # Any crashing applications
@{LogName="Application";ID=3001}, # The process X was terminated by the process Y
@{LogName="Application";ID=4005}, # Winlogon terminating
@{LogName="Application";ProviderName="RESWAS";Level=2},
@{LogName="Microsoft-Windows-PrintService/Admin";ID=215}, 
@{LogName="Microsoft-FSLogix-Apps/Operational";ID=51},
@{LogName="Microsoft-FSLogix-Apps/Operational";ID=26}

#@{LogName="Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Admin";ID=105}, # RDP TLS encryption warning

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
                $username = (New-Object System.Security.Principal.SecurityIdentifier $event.UserId.Value).Translate([System.Security.Principal.NTAccount]).Value
            } catch {
                $username = ""
            }

            $AllEvents += [PSCustomObject]@{
                ComputerName = $computer
                Log = $event.LogName
                EventID = $event.Id
                Datetime = $event.TimeCreated
                User = $username
                Message = $event.Message
            }
        }
        #$EventInfo.clear()
    }   
}

Write-Progress -Id 1 -Status "Ready" -Activity "Complete" -Completed
Write-Host  "Done - See Gridview!"
$output = $AllEvents | Sort-Object -Property Datetime -Descending
$output | Export-Csv -NoTypeInformation -Force "Get-RDSLogErrors.csv"
$output | Out-GridView
