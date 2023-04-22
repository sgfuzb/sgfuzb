#
# Use to check for broken Compucare, Medisoft, etc installs
# Use to check for failed printer installs
#
# Steven Gill 12/10/21

$Computernames = @()
$AllEvents = @()

$computernames = "MEHVMC11","MEHVMC12","MEHVMC13","MEHVMC14","MEHVMC15","MEHVMC16","MEHVMC17","MEHVMC18"
#$computernames = "MEHVM15","MEHVM16","MEHVM17","MEHVM18"

$computercount = $Computernames.Count

# Level Error = 2
# Go to log properties and get "full name"

# VMC HPE NIC reset errors - Cluster instability
$LogFilters = 
@{LogName="Microsoft-Windows-Hyper-V-StorageVSP-Admin";ID=9}, # An I/O request for device took x milliseconds to complete (look for long)
@{LogName="Microsoft-Windows-Hyper-V-VMMS-Admin";ID=19100}, # background disk merge failed to complete
@{LogName="Microsoft-Windows-Hyper-V-VMMS-Admin";ID=10103}, # cannot be hot backed up since it has no SCSI controllers attached
@{LogName="Microsoft-Windows-Hyper-V-VMMS-Admin";ID=14070}, # Virtual machine x quit unexpectedly
@{LogName="Microsoft-Windows-Hyper-V-Worker-Admin";ID=4093}, # Volume Shadow Copy integration service is not enabled
@{LogName="Microsoft-Windows-FailoverClustering/Operational";ID=1650}, # Cluster Networking heartbeats
@{LogName="Microsoft-Windows-FailoverClustering/Operational";ID=5155}, # autopause timing slowest node
@{LogName="Microsoft-Windows-FailoverClustering-CsvFs/Operational"; ID=9296}, # CSVFS autopause
@{LogName="Microsoft-Windows-SMBServer/Operational";ID=1020}, # SMB Server The underlying file system has taken too long to respond to an operation
@{LogName="System";ID=5120}, # CSV - All I/O will temporarily be queued until a path to the volume is reestablished
@{LogName="System";ID=1069}, # Cluster resource xxx Resources' failed
@{LogName="System";ID=16945}, # MAC conflict
@{LogName="System";ID=10400}, # Intel NIC driver crashing
@{LogName="System";ID=153}, # IO operation for logical block was retried
@{LogName="System";ID=5142}, # CSV is no longer accessible connectivity to the storage device and network connectivity?
@{LogName="System";ID=0} # Dummy no comma

# @{LogName="Microsoft-Windows-Storage-Storport/Operational";ID=549}, # The io latency was 1 ms

$lastxdays = 1
$MaxEvents = 1000
#$StartTime = Get-Date -Year 2022 -Month 9 -Day 19 -Hour 11 -Minute 45
#$EndTime = Get-Date -Year 2022 -Month 9 -Day 19 -Hour 12 -Minute 15
#$StartTime = (Get-Date).AddDays(-$lastxdays)
$StartTime = (Get-Date).AddHours(-48)
$EndTime = (Get-Date)


ForEach ($computer in $computernames){

    # Generate progress bar
    $Index = [array]::IndexOf($Computernames,$computer)
    $Percentage = $Index / $computercount
    $Message = "Reading event logs ($Index of $computercount)"
    Write-Progress -Activity $Message -PercentComplete ($Percentage * 100) -CurrentOperation $computer -id 2
    
    $EventInfo = @()

    foreach ($LogFilter in $LogFilters) {

        $filter = @{LogName=$LogFilter.logname; ID=$logfilter.ID; StartTime=$StartTime; EndTime=$EndTime}

        $EventInfo += Get-WinEvent -ErrorAction SilentlyContinue -ComputerName $computer -FilterHashTable $Filter -MaxEvents $MaxEvents #| Where-Object {$_.Message -match $matchtext } 
    }

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
                Level = $event.LevelDisplayName
                Datetime = $event.TimeCreated
                User = $username
                Message = $event.Message
            }
        }
    }   
}

Write-Progress -Id 2 -Status "Ready" -Activity "Complete" -Completed
Write-Host  "Done - See Gridview!"

$output = $AllEvents | Sort-Object -Property Datetime -Descending
$output | Export-Csv -NoTypeInformation -Force "Get-LogClusterErrors.csv"
$output | Out-GridView

# report of just ID 9 with ms times extracted greped out