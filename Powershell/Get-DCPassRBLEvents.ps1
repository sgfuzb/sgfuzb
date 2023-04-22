#
# Use to check for broken Compucare, Medisoft, etc installs
# Use to check for failed printer installs
#
# Steven Gill 12/10/21

$MaxServers = 4
$Computernames = @()
$AllEvents = @()

$LogFilters = 
@{LogName="Application";ProviderName="Password Firewall";ID=1992},
@{LogName="Application";ProviderName="Password Firewall";ID=1991},
@{LogName="Application";ProviderName="Password Firewall";ID=1990}

For ($i = 1; $i -le $MaxServers; $i++) {
    If ($i -lt 10) { $servername = "MEHDC" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }
    $ComputerNames += $servername
}

#$computernames = "MEHRDS-54"

Foreach ($Filter in $LogFilters) {

    ForEach ($computer in $computernames){

        $EventInfo = Get-WinEvent -ErrorAction SilentlyContinue -ComputerName $computer -FilterHashTable $Filter -MaxEvents 1000 #|
        #Where-Object {$_.Message -match $matchtext } | 
        #Select-Object -First 20
        
        If ($EventInfo.count -gt 0) {
            
            ForEach ($event in $EventInfo) {

                $AllEvents += [PSCustomObject]@{
                    ComputerName = $computer
                    Log = $filter.LogName
                    EventID = $event.ID
                    Datetime = $event.TimeCreated
                    Message = $event.Message
                }
            }
            #$EventInfo.Clear()
        }   
    }
}

Write-Host  "Done - See Gridview!"
$AllEvents | Sort-Object -Property "DateTime" -Descending | Out-GridView
$AllEvents | Export-Csv -NoTypeInformation .\Get-DCPassRBLEvents.csv