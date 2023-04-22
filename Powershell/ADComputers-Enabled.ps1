
$computers = Get-ADComputer -Filter * -Properties operatingSystem,lastLogonTimestamp,PasswordLastSet,Enabled,description | 
Select-Object Name, DistinguishedName, operatingSystem,@{Name='LastLogontimestamp';Expression={[DateTime]::FromFileTime($_.LastLogontimestamp)}},PasswordLastSet,Enabled,description

$computers = $computers | Where-Object { !(($_.description -like "*failover*") -or ($_.description -like "*cisco*"))} | Sort-Object DNSHostName
$computers | Out-GridView

# $enabledcomputers = $computers | Where-Object { ($_.enabled -eq $true) }
# $enabledcomputers | Out-GridView

#$enabledcomputers | Export-Csv -NoTypeInformation M:\Powershell\ADComputers-Enabled3.csv
#M:\Powershell\ADComputers-Enabled.csv