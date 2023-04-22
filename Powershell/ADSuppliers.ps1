# Get all AD users, enabled or not
$users = Get-ADuser -Filter * -Properties DisplayName,mail,Title,department,Company,LastLogontimestamp,lastLogon,Enabled,description,whenCreated,distinguishedName,pwdLastSet,passwordNeverExpires,office  -SearchBase "DC=moorfields,DC=nhs,DC=uk"|
Select-Object name,DisplayName,mail,Description,Company,Department, 
@{Name='LastLogontimestamp';Expression={[DateTime]::FromFileTime($_.LastLogontimestamp)}},
whenCreated,
@{Name='pwdLastSet';Expression={[DateTime]::FromFileTime($_.pwdLastSet)}},
enabled, distinguishedName,passwordNeverExpires, office

$users2 = $users | Where-Object {$_.office -like "*Supplier*"} | Sort-Object -Property Name

$users2.Count

$users2 | Out-GridView
#$users2 | Export-Csv -NoTypeInformation "ADSuppliers.csv"
