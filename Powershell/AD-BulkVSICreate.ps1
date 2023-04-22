
$WhatIfPreference = $false

$path="CN=Users,DC=moorfields,DC=nhs,DC=uk"
$userbase="VSI"
$usergroup = "LoginVSIUsers"


for ($i = 11; $i -le 30; $i++) {

    if ($i -lt 10){ $username = $userbase + "0" + $i.ToString() }
    if ($i -ge 10){ $username = $userbase + $i.ToString() }

    New-AdUser -Name $username -Path $path -Enabled $True -ChangePasswordAtLogon $false  `
    -AccountPassword (ConvertTo-SecureString "MER?zVk{#36:" -AsPlainText -force) -Verbose -Description "LoginVSI Testing account"

    Add-ADGroupMember -Identity $usergroup -Members $username

}
