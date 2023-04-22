$Date = (Get-Date).AddDays(-90)
$stalecomputers = Get-ADComputer -Filter * -Properties PasswordLastSet,Enabled,description | 
where { ($_.PasswordLastSet -le $Date) -and ($_.enabled -eq $true)} | Sort-Object DNSHostName

$staleUsers = Get-ADuser -Filter * -Properties lastLogon,Enabled,description -SearchBase "CN=Users,DC=moorfields,DC=nhs,DC=uk"| 
select Name, DistinguishedName, Description, @{Name='LastLogon';Expression={[DateTime]::FromFileTime($_.LastLogon)}}, enabled | where { ($_.LastLogon -le $Date) -and ($_.enabled -eq $true) -and ($_.LastLogon -gt "1/1/1601")} 

$Date
$stalecomputers.Count
$staleusers.Count
