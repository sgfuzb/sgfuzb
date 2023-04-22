$servers.Clear()

for ($i=1; $i -le 39; $i++) {
    if ($i -lt 10){	$servers += "MEHRDS-0"+ $i.ToString()}
    if ($i -gt 9){	$servers += "MEHRDS-"+ $i.ToString()}
}

Foreach ($server in $servers){
    #$server
    $events += Get-WinEvent -ComputerName $server -FilterHashTable @{LogName="Microsoft-Windows-TerminalServices-Printers/Admin"; ID=1111; StartTime=(Get-Date).AddDays(-30)} 
}
$events | Sort-Object Timecreated | fl



