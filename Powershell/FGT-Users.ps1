# Fortinet Fortigate Powershell
# Script to semi-automate managing SSLVPN users
# (Would be a lot easier if the firewall had a last login time for each user, and fortipower had group/user delete!)

# Docs: https://fortipower.github.io/PowerFGT/ 
# If not installed on machine;
# Install-Module PowerFGT
# Update-Module PowerFGT
# Get-Command -Module PowerFGT


$whatifpreference = $false

Import-Module PowerFGT

# Get cred manually
$credential = Get-Credential
Connect-FGT -Server fw.moorfields.nhs.uk -port 8443 -Credentials $credential -vdom "Internet"



# Users
$FGTUsers = Get-FGTUserLocal
$FGTUsers2 = $FGTUsers | Select-Object name, status, type, two-factor, email-to
$FGTUsersDisabled = $FGTUsers2 | Where-Object {($_.status -eq "disable") -and ($_.'two-factor' -eq "disable")}
$FGTUsersDisabledFTC = $FGTUsers2 | Where-Object {($_.status -eq "disable") -and ($_.'two-factor' -eq "fortitoken-cloud")}
#$FGTUsers2 | Out-GridView

$FGTGroups = Get-FGTUserGroup
#$FGTWebMembers = ($FGTGroups | Where-Object {$_.name -eq "FW-SSLVPN-Web"}).member
#$FGTipadMembers = ($FGTGroups | Where-Object {$_.name -eq "FW-SSLVPN-Web+Tunnel-ipad"}).member
#$FGTOEMembers = ($FGTGroups | Where-Object {$_.name -eq "FW-SSLVPN-OE"}).member
#$FGTAdminMembers = ($FGTGroups | Where-Object {$_.name -eq "FW-SSLVPN-Full-Admin"}).member

$FGTUsersGroups = @()

Foreach ($user in $FGTUsers) {
    
    $usergroup = ""

    ForEach ($group in $FGTGroups) {
        if ($Group | Where-Object {$_.member.name -eq $user.name}){
            $usergroup = $group.name
        }
    }

    $FGTUsersGroups += [PSCustomObject]@{
        Name = $user.name
        Email = $user.'email-to'
        Status = $user.status
        TwoFA = $user.'two-factor'
        Type = $user.type
        Group = $usergroup
    }
}

$FGTUsersGroups | Out-GridView

break

# Create CLI script to change user group ############################
$FGTCLIscript = ""
$FGTCLIscript += "config vdom`n"
$FGTCLIscript += "edit Internet`n"

# Remove users from web group
$FGTCLIscript += "config user group`n" 
$FGTCLIscript += "edit FW-SSLVPN-Web`n" 
foreach ($User in $FGTWebMembers) {
    $Username = $User.name
    $FGTCLIscript += "  unselect member $Username`n"
}
$FGTCLIscript += "end`n`n"

# Add users to ipad group
### Warning set/select REMOVES ALL CURRENT USERS! use append ###

$FGTCLIscript += "config user group`n" 
$FGTCLIscript += "edit FW-SSLVPN-Web+Tunnel-ipad`n"
foreach ($User in $FGTWebMembers) {
    $Username = $User.name
    $FGTCLIscript += "  append member $Username`n"
}
$FGTCLIscript += "end`n`n"

$FGTCLIscript | Out-File .\FGT-Users-CLIScript.txt

break

# Create CLI script to remove and disable users #############################
$FGTCLIscript = ""

$FGTCLIscript += "config vdom`n"
$FGTCLIscript += "edit Internet`n"

# Remove disabled users from web group
$FGTCLIscript += "config user group`n" 
$FGTCLIscript += "edit FW-SSLVPN-Web`n" 
foreach ($User in $FGTUsersDisabled) {
    $Username = $User.name
    $FGTCLIscript += "  unselect member $Username`n"
}
$FGTCLIscript += "end`n`n"

# Delete disabled users 
$FGTCLIscript += "config user local`n"
foreach ($User in $FGTUsersDisabled) {
    $Username = $User.name
    $FGTCLIscript += "  delete $Username`n"
}
$FGTCLIscript += "end`n`n"

# Disable FTC for users from CSV
$Users = Import-Csv .\FGT-Users-Disable.csv
$Users2 = $users + $FGTUsersDisabledFTC.name
$FGTCLIscript += "config user local`n"
foreach ($User in $Users2) {
    $Username = $User.Username
    if ($Username) {
        $FGTCLIscript += "  edit $Username`n"
        $FGTCLIscript += "    set status disable`n"
        $FGTCLIscript += "    set two-factor disable`n"
        $FGTCLIscript += "  next`n"
    }
}
$FGTCLIscript += "end`n`n"

$FGTCLIscript | Out-File .\FGT-Users-CLIScript.txt

break

# Get all AD users, enabled or not ############################

$users = Get-ADuser -Filter * -Properties LastLogontimestamp,Enabled -SearchBase "DC=moorfields,DC=nhs,DC=uk"|
Select-Object name,DisplayName,@{Name='LastLogontimestamp';Expression={[DateTime]::FromFileTime($_.LastLogontimestamp)}},enabled
$users = $users | Where-Object {$_.enabled -eq "True"}

# Outputs for Excel
$users | Out-GridView
$FGTUsers | Out-GridView
