# Get all AD users, enabled or not
$users = Get-ADuser -Filter * -Properties name,DisplayName,givenname,sn,mail,Description,Company,Department,LastLogontimestamp,whenCreated,pwdLastSet,enabled,distinguishedName,passwordNeverExpires, office,certificates -SearchBase "DC=moorfields,DC=nhs,DC=uk"|
Select-Object name,DisplayName,givenname,sn,mail,Description,Company,Department, @{Name='LastLogontimestamp';Expression={[DateTime]::FromFileTime($_.LastLogontimestamp)}},whenCreated,@{Name='pwdLastSet';Expression={[DateTime]::FromFileTime($_.pwdLastSet)}},enabled, distinguishedName,passwordNeverExpires, office,certificates

# $users = $users | Where-Object {$_.enabled -eq "True"}

$users.Count

#$users | Out-GridView
$users | Select-Object name, displayname, givenname,sn, mail, LastLogontimestamp, enabled | Where-Object enabled -eq True | Out-GridView
# $users | Export-Csv -NoTypeInformation "AdActiveUsers.csv"
