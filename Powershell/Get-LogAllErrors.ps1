#
# Use to check for broken Compucare, Medisoft, etc installs
# Use to check for failed printer installs
#
# Steven Gill 12/10/21

$Computernames = @()
$AllEvents = @()

$MaxEvents = 1000

#$MaxRDSServer = 72
#For ($i = 1; $i -le $MaxRDSServer; $i++) {
#    If ($i -lt 10) { $servername = "MEHRDS-0" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }
#    $ComputerNames += $servername
#}

$computernames = "MEHVMC11","MEHVMC12","MEHVMC13","MEHVMC14","MEHVMC15","MEHVMC16","MEHVMC17","MEHVMC18"
#$computernames = "MEHVM15","MEHVM16","MEHVM17","MEHVM18"

#$computernames = "MEHVMC13"

$computercount = $Computernames.Count

ForEach ($computer in $computernames){

    # Generate progress bar
    $Index = [array]::IndexOf($Computernames,$computer)
    $Percentage = $Index / $computercount
    $Message = "Reading event logs on computer ($Index of $computercount)"
    Write-Progress -Activity $Message -PercentComplete ($Percentage * 100) -CurrentOperation $computer -id 2
    
    $EventInfo =@()
    $LogsFilter = "*" # e.g. *stor*
    $LogLevel = 2 # 3=warning 2=error
    $StartTime = (Get-Date).AddHours(-6)
    $EndTime = Get-Date
    #$StartTime = Get-Date -Year 2022 -Month 9 -Day 19 -Hour 11 -Minute 45
    #$EndTime = Get-Date -Year 2022 -Month 9 -Day 19 -Hour 12 -Minute 15
    #$StartTime = Get-Date -Hour 04 -Minute 00
    #$EndTime = Get-Date -Hour 05 -Minute 00

    $LogList = Get-WinEvent -ComputerName $computer -ListLog $LogsFilter -ErrorAction SilentlyContinue `
    | where-object { $_.recordcount -AND $_.lastwritetime -gt [datetime]::today}
        
    foreach ($log in $loglist) {
        $logname = $log.logname
        $filter = @{LogName=$logname;StartTime=$StartTime;EndTime=$EndTime;Level=$LogLevel}
        $EventInfo += Get-Winevent -ComputerName $computer -FilterHashtable $filter -MaxEvents $MaxEvents -ErrorAction SilentlyContinue
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


#Write-Progress -Id 1 -Status "Ready" -Activity "Complete" -Completed
Write-Progress -Id 2 -Status "Ready" -Activity "Complete" -Completed
Write-Host  "Done - See Gridview!"
$output = $AllEvents | Sort-Object -Property Datetime -Descending
$output | Export-Csv -NoTypeInformation -Force "Get-AllLogErrors.csv"
$output | Out-GridView

<#
https://learn.microsoft.com/en-us/powershell/scripting/samples/Creating-Get-WinEvent-queries-with-FilterHashtable?view=powershell-7.2

Key name	Value data type	Accepts wildcard characters?
LogName	<String[]>	Yes
ProviderName	<String[]>	Yes
Path	<String[]>	No
Keywords	<Long[]>	No
ID	<Int32[]>	No
Level	<Int32[]>	No
StartTime	<DateTime>	No
EndTime	<DateTime>	No
UserID	<SID>	No
Data	<String[]>	No
<named-data>	<String[]>	No

Informational 4 
Warning 3 
Error 2 
Critical 1 


#>