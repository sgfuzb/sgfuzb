#Windows Server 2016 Standard (64-bit) Build:14393 10.2 08.12.2020 17:16:41
netsh int ip show interfaces
Get-NetAdapterLso -Name '*'
Get-NetAdapterChecksumOffload '*'
Get-NetTCPSetting -SettingName automatic
netsh int tcp show global
Get-NetOffloadGlobalSetting

# https://docs.microsoft.com/en-us/windows-server/networking/technologies/network-subsystem/net-sub-performance-tuning-nics

Get-NetTCPSetting | Select SettingName,AutoTuningLevelLocal
Set-NetTCPSetting -AutoTuningLevelLocal Experimental 


Set-NetTCPSetting -SettingName automatic -AutoTuningLevelLocal normal
Set-NetTCPSetting -SettingName automatic -ScalingHeuristics disabled
netsh int tcp set supplemental automatic congestionprovider=ctcp
Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing disabled

Set-NetTCPSetting -SettingName automatic -EcnCapability Disabled
Set-NetTCPSetting -SettingName automatic -Timestamps disabled
Set-NetTCPSetting -SettingName automatic -MaxSynRetransmissions 2
Set-NetTCPSetting -SettingName automatic -NonSackRttResiliency disabled
Set-NetTCPSetting -SettingName automatic -InitialRto 2000 
Set-NetTCPSetting -SettingName automatic -MinRto 300

Set-NetTCPSetting -SettingName automatic -ScalingHeuristics Enabled
#Set-NetTCPSetting -SettingName automatic -AutoTuningLevelGroupPolicy GroupPolicy
Set-NetTCPSetting -SettingName automatic -AutoTuningLevelEffective Experimental


netsh int tcp set heuristics wsh=enabled forcews=enabled 
