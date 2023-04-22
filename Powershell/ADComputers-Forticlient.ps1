
$enabledcomputers = Get-ADComputer -Filter * -Properties PasswordLastSet,Enabled,description | 
Where-Object { ($_.enabled -eq $true) -and !(($_.description -like "*failover*") -or ($_.description -like "*cisco*"))} | 
Select-Object name,  
@{n="OU";e={$_.distinguishedname.split(",")[1]}} |
Sort-Object Name

#$enabledcomputers | Out-GridView

$enabledcomputers | Export-Csv -NoTypeInformation M:\Powershell\ADComputers-Forticlient.csv
M:\Powershell\ADComputers-Forticlient.csv