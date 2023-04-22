# Check VM Cluster Error logs
# 
# Steven Gill 15/09/22

$Computernames = @()
$AllEvents = @()

$lastxdays = 1
$MaxEvents = 1000

$computernames = "MEHVMC11","MEHVMC12","MEHVMC13","MEHVMC14","MEHVMC15","MEHVMC16","MEHVMC17","MEHVMC18"

# Go to log properties and get "full name"

# VMC HPE NIC reset errors - Cluster instability
$LogFilters = 
@{LogName="System";ID=153} # IO operation for logical block was retried
#@{LogName="Microsoft-Windows-Hyper-V-StorageVSP-Admin";ID=9},
#@{LogName="Microsoft-Windows-Hyper-V-VMMS-Admin";ID=19100},
#@{LogName="Microsoft-Windows-FailoverClustering/Operational";ID=1650},
#@{LogName="System";ID=10400}

$computercount = $Computernames.Count
$filtercount = $LogFilters.Count

<#
Foreach ($Filter in $LogFilters) {

    # Generate progress bar
    $Index = [array]::IndexOf($LogFilters,$Filter)
    $Percentage = $Index / $filtercount
    $Message = "LogFilter ($Index of $filtercount)"
    Write-Progress -Activity $Message -PercentComplete ($Percentage * 100) -CurrentOperation $Filter.LogName -id 1
    #>

    ForEach ($computer in $computernames){

        # Generate progress bar
        $Index = [array]::IndexOf($Computernames,$computer)
        $Percentage = $Index / $computercount
        $Message = "Reading event logs ($Index of $computercount)"
        Write-Progress -Activity $Message -PercentComplete ($Percentage * 100) -CurrentOperation $computer -id 2
        
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

#}

Write-Progress -Id 2 -Status "Ready" -Activity "Complete" -Completed

$output = $AllEvents | Sort-Object -Property Datetime -Descending

$output | Export-Csv -NoTypeInformation -Force "Get-VMClusterErrLogs.csv"
#$output | Out-GridView

######### SEND EMAIL

$HTML=@"
<style>
TABLE{border-width: 1px;border-style: solid;border-color: black;}
TH{border-width: 1px;padding: 5px;border-style: solid;border-color: black;text-align: center;}
TD{border-width: 1px;padding: 5px;border-style: solid;border-color: black;text-align: left;}
</style>
"@

$rptDate = Get-Date

$message = "Latest 100 errors; <br>" + ($output | select-object -First 100 | ConvertTo-html)

#Settings for Email Message
$messageParameters = @{ 
    Subject = "[Cluster Error logs on " + $rptDate.ToString($cultureENGB) + "]"
    Body = ("$message")
    From = "it.alerts@moorfields.nhs.uk" 
    To = "moorfields.italerts@nhs.net"
    SmtpServer = "smtp.moorfields.nhs.uk"
    Attachments = ".\Get-VMClusterErrlogs.csv"
    
} 
#Send Report Email Message
Send-MailMessage @messageParameters -BodyAsHtml