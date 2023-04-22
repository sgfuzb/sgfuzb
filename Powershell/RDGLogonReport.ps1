$ServersToQuery = @("MEHGW-01","MEHGW-02")

[array]$Output = @()
[array]$FilteredOutput = @()
[datetime]$StartTime = (get-date).AddDays(-28)

ForEach($Server in $ServersToQuery) {

        $LogFilter = @{
            LogName = 'Microsoft-Windows-TerminalServices-Gateway/Operational'
            ID = 302, 303
            StartTime = $StartTime
            }

        $AllEntries = Get-WinEvent -FilterHashtable $LogFilter -ComputerName $Server

        $AllEntries | ForEach-Object { 
            $entry = [xml]$_.ToXml()
            [array]$Output += New-Object PSObject -Property @{
                TimeCreated = $_.TimeCreated
                User = $entry.Event.UserData.EventInfo.Username
                Resource = $entry.Event.UserData.EventInfo.resource
                EventID = $entry.Event.System.EventID
                ServerName = $Server  
                }        
            } 
   }

    $FilteredOutput = $Output | Select-Object TimeCreated, User, ServerName, Resource, @{Name='Action';Expression={
                if ($_.EventID -eq '302'){"logon"}
                if ($_.EventID -eq '303'){"logoff"}
                }
            }


$FilteredOutput | Sort-Object TimeCreated -descending | Export-CSV -NoTypeInformation ".\RDGLogonReport.csv"
#$FilteredOutput | Sort-Object TimeCreated -descending

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
    To = "moorfields.italerts@nhs.net" #, "alastair.salmon@nhs.net"
    SmtpServer = "smtp.moorfields.nhs.uk"
    #SmtpServer = "127.0.0.1"
    Attachments = ".\RDGLogonReport.csv"
    
} 
#Send Report Email Message
Send-MailMessage @messageParameters –BodyAsHtml


<#
<Event xmlns='http://schemas.microsoft.com/win/2004/08/events/event'>
	<System>
		<Provider Name='Microsoft-Windows-TerminalServices-Gateway' Guid='{4D5AE6A1-C7C8-4E6D-B840-4D8080B42E1B}'/>
		<EventID>303</EventID>
		<Version>0</Version>
		<Level>4</Level>
		<Task>3</Task>
		<Opcode>44</Opcode>
		<Keywords>0x4000000001000000</Keywords>
		<TimeCreated SystemTime='2018-08-16T10:51:11.995276700Z'/>
		<EventRecordID>11975</EventRecordID>
		<Correlation ActivityID='{10BE56AC-F637-43DE-B2FE-8ECB38390000}'/>
		<Execution ProcessID='4000' ThreadID='3524'/>
		<Channel>Microsoft-Windows-TerminalServices-Gateway/Operational</Channel>
		<Computer>MEHGW-01.moorfields.nhs.uk</Computer>
		<Security UserID='S-1-5-20'/>
	</System>	
	<UserData>
		<EventInfo xmlns='aag'>
			<Username>CITY_ROAD\JURKUTEN</Username>
			<IpAddress>192.168.20.4</IpAddress>
			<AuthType></AuthType><Resource>rds</Resource>
			<BytesReceived>4223901</BytesReceived>
			<BytesTransfered>3017755</BytesTransfered><SessionDuration>3775</SessionDuration>
			<ConnectionProtocol>HTTP</ConnectionProtocol>
			<ErrorCode>1226</ErrorCode>
		</EventInfo>
	</UserData>
</Event>
#>