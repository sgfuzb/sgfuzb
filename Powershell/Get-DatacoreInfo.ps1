# Datacore Powershell commands
#
# https://docs.datacore.com/SSV-WebHelp/SSV-WebHelp/DC_Cmdlet_Ref_Gde.htm
# Get-Command –module DataCore.Executive.Cmdlets

# Get the installation path of SANsymphonyV
$bpKey = 'BaseProductKey'
$regKey = Get-Item "HKLM:\Software\DataCore\Executive"
$strProductKey = $regKey.getValue($bpKey)
$regKey = Get-Item "HKLM:\$strProductKey"
$installPath = $regKey.getValue('InstallPath')

Import-Module "$installPath\DataCore.Executive.Cmdlets.dll" -DisableNameChecking -ErrorAction Stop

# Connect
Connect-DcsServer MEHSAN3

# Get Useful Info
$DcsVirtualDisks = Get-DcsVirtualDisk 
$DcsPools = Get-DcsPool
$DcsPoolmembers = Get-DcsPoolMember
$DcsHosts = Get-DcsClient

# Gridviews
$DcsVirtualDisks | Out-GridView
$DcsPools | Out-GridView
$DcsPoolmembers | Out-GridView
$DcsHosts | Out-GridView

<#
$FilterDisks = $DcsVirtualDisks | `
Where-Object {
    ($_.MirrorTrunkMappingEnabled -eq $false) -and #
    ($_.type -eq "MultiPathMirrored") -and # NonMirrored, MultiPathMirrored
    ($_.RecoveryPriority -eq "Critical") # Low, High, Regular, Critical
} | Select-Object -First 10

$FilterDisks | Select-Object Caption

$FilterDisks | Set-DcsVirtualDiskProperties -MirrorTrunkMappingEnabled $true | Out-Null
#>
