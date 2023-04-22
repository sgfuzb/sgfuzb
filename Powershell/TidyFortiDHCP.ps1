# ===================================================
# Delete stale entries in DNS for forti-VPN dhcp
# Steven Gill 18/03/20
# ===================================================
#Start-Transcript -path TidyFortiDHCP.log
# debug
$whatifpreference = 0 
# ===================================================

$Message =  "===================================================<br>"
$Message += "Delete stale entries in DNS for forti-VPN dhcp <br>"
$Message += "===================================================<br>"

$DNSEntries = Get-DnsServerResourceRecord -ZoneName "moorfields.nhs.uk" -ComputerName "mehdc1" -RRType A 

#$RALaptops = $DNSEntries | Where-Object {$_.RecordData.ipv4address -like "192.168.208*"} | Sort-Object RecordData.ipv4address 

$RAClients = $DNSEntries | 
Where-Object {$_.RecordData.ipv4address -like "192.168.208*"} |
Select-Object @{label=’IPAddress’; expression={$_.recorddata | Select-Object -expandproperty ipv4address}},timestamp, hostname |
Sort-Object ’IPAddress’, timestamp -Descending

$UniqueIPs = $RAClients | Select-Object IPAddress | Get-Unique -AsString

foreach ($IP in $UniqueIPs) {
    
    $RADupues = $RAClients | Where-Object {$_.’IPAddress’ -eq $IP.IPAddress} 

    if ($RADupues.Count -gt 1){ 
        
        # start at 1 to miss first entry must sort desc
        for ($i = 1; $i -lt $RADupues.Count; $i++) {
            $text = "Deleting entry for" + $RADupues[$i].hostname + $RADupues[$i].’IPAddress’ + "<br>"
            $Message += $text | Write-host
            Remove-DnsServerResourceRecord -ComputerName "MEHDC1" -ZoneName "moorfields.nhs.uk" -RRType "A" -Name $RADupues[$i].hostname -RecordData $RADupues[$i].’IPAddress’ -Force
        }
    }
}

#Stop-Transcript

# ===================================================
# Report and email
# ===================================================

$Message += "===================================================<br>"
$Message += "DONE!<br>"


#Settings for Email Message
$rptDate=(Get-date)
if ($whatifpreference -eq 1) {
    $subjectprefix = "###TEST### " 
    $Message
} else {$subjectprefix = "" } 

$messageParameters = @{ 
    Subject = "[" + $subjectprefix + "DNS delete stake entries on " + $rptDate.ToString($cultureENGB) + "]"
    Body = $Message
    From = "it.alerts@moorfields.nhs.uk" 
    To = "moorfields.italerts@nhs.net"
    SmtpServer = "smtp.moorfields.nhs.uk"
    #SmtpServer = "127.0.0.1"
} 
#Send Report Email Message
Send-MailMessage @messageParameters -BodyAsHtml
