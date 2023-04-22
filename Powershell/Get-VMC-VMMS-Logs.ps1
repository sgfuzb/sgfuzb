$ServersToQuery = @("MEHVMC3","MEHVMC4","MEHVMC5","MEHVMC6","MEHVMC7","MEHVMC8","MEHVMC9","MEHVMC10")

[array]$Output = @()
[array]$FilteredOutput = @()
[datetime]$StartTime = (get-date).AddDays(-1)

ForEach($Server in $ServersToQuery) {

    $LogFilter = @{
        LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
        #ID = 21024,21028
        Level = 2 #error
        StartTime = $StartTime
        }

    $AllEntries = Get-WinEvent -FilterHashtable $LogFilter -ComputerName $Server

    $AllEntries | ForEach-Object { 
        $entry = [xml]$_.ToXml()
        [array]$Output += New-Object PSObject -Property @{
            ServerName = $Server  
            TimeCreated = $_.TimeCreated
            EventID = $_.Id
            Message = $_.Message
        }        
    } 

    $LogFilter = @{
        LogName = 'Microsoft-Windows-Hyper-V-VMMS-Storage'
        #ID = 21024,21028
        Level = 2 #error
        StartTime = $StartTime
        }

    $AllEntries = Get-WinEvent -FilterHashtable $LogFilter -ComputerName $Server

    $AllEntries | ForEach-Object { 
        $entry = [xml]$_.ToXml()
        [array]$Output += New-Object PSObject -Property @{
            ServerName = $Server  
            TimeCreated = $_.TimeCreated
            EventID = $_.Id
            Message = $_.Message
        }        
    } 


}

    $FilteredOutput = $Output | Select-Object ServerName, TimeCreated, EventID, Message

#$FilteredOutput | Sort-Object TimeCreated -descending | Export-CSV -NoTypeInformation ".\RDGLogonReport.csv"
$FilteredOutput | Sort-Object TimeCreated -descending | Out-GridView

#============= OUTPUT

$HTML=@" 
<style>
TABLE{border-width: 1px;border-style: solid;border-color: black;}
TH{border-width: 1px;padding: 5px;border-style: solid;border-color: black;text-align: center;}
TD{border-width: 1px;padding: 5px;border-style: solid;border-color: black;text-align: left;}
</style>
"@

$rptDate= Get-date  

#Settings for Email Message
$messageParameters = @{ 
    Subject = "[RDG Login Report for last 7 days on " + $rptDate + "]"
    Body = "Attached is the report"
    From = "it.alerts@moorfields.nhs.uk" 
    To = "moorfields.italerts@nhs.net", "alastair.salmon@nhs.net"
    SmtpServer = "smtp.moorfields.nhs.uk"
    #SmtpServer = "127.0.0.1"
    Attachments = ".\RDGLogonReport.csv"
    
} 
#Send Report Email Message
#Send-MailMessage @messageParameters –BodyAsHtml

