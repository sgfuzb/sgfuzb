# Fortinet Fortigate Powershell access

# Docs: https://fortipower.github.io/PowerFGT/ 

# If not installed on machine;
#Install-Module PowerFGT

$whatifpreference = $false

Import-Module PowerFGT

#$username = "fwadmin"
#$pwdTxt = "xx"
#$securePwd = $pwdTxt | ConvertTo-SecureString -AsPlainText -Force
$securePwd = (Get-Credential)
$credential = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $securePwd

# Get cred manually
#$credential =Get-Credential

Break

Connect-FGT -Server fw.moorfields.nhs.uk -Credentials $credential -vdom "N3"
Connect-FGT -Server fw.moorfields.nhs.uk -Credentials $credential -vdom "Internet"
Connect-FGT -Server fw.moorfields.nhs.uk -Credentials $credential -vdom "ISFW"

#Addresses
Get-FGTFirewallAddress | Out-GridView

#Users
Get-FGTUserLocal | Out-GridView

# Policies
Get-FGTFirewallPolicy | Out-GridView

# VIPs
Get-FGTFirewallVip | Out-GridView

#Get-FGTFirewallPolicy -skip -vdom "Internet" -name "Advatek Firewall remote access" 
Get-FGTFirewallPolicy -skip -vdom "*" | 
Select-Object policyid, name, status, 
@{Name='srcintf';Expression={[string]::join(";", ($_.srcintf.name))}}, 
@{Name='dstintf';Expression={[string]::join(";", ($_.dstintf.name))}}, 
@{Name='srcaddr';Expression={[string]::join(";", ($_.srcaddr.name))}}, 
@{Name='dstaddr';Expression={[string]::join(";", ($_.dstaddr.name))}}, 
@{Name='service';Expression={[string]::join(";", ($_.service.name))}}, 
ips-sensor, logtraffic, comments | 
where-object {(($_.srcintf -Like "*vlan.53*") -or ($_.srcintf -Like "*vlan.90*") ) -and ($_.status -eq "enable")} |
Out-GridView
#Export-Csv M:\FGT-Policies.csv -NoTypeInformation

<#
Connect-FGT -Server fw.moorfields.nhs.uk -vdom "Internet"
$x= Get-FGTUserLocal 
$x | Export-Csv FGT-Users.csv -NoTypeInformation
$x | Out-GridView
#>