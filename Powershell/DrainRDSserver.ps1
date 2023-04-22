SetRDSServer -RealServer "MEHRDS-10" -Action disable
SetRDSServer -RealServer "MEHRDS-02" -Action disable
SetRDSServer -RealServer "MEHRDS-06" -Action disable

SetRDSServer -RealServer "MEHRDS-12" -Action disable
SetRDSServer -RealServer "MEHRDS-20" -Action disable
SetRDSServer -RealServer "MEHRDS-26" -Action disable
SetRDSServer -RealServer "MEHRDS-22" -Action disable
SetRDSServer -RealServer "MEHRDS-24" -Action disable

SetRDSServer -RealServer "MEHRDS-30" -Action disable

Function SetRDSServer
{

    # Disable Realserver in Kemp and on load balancer
    # SG Dec 2018

    Param
    (
     [string] $RealServer,
     [ValidateSet("Enable","Disable")] [string] $Action
    )

    $RealIP = [System.Net.Dns]::GetHostAddresses($RealServer) | foreach { $_.IPAddressToString | findstr "192.168.17."}
    
    #alternative
    #$ping = New-Object System.Net.NetworkInformation.Ping
    #$RealIP = $($ping.Send($RealServer).Address).IPAddressToString

    $username = "bal"
    $passwd = "Password1234"
    $secpasswd = ConvertTo-SecureString "$passwd" -AsPlainText -Force
    $creds = New-Object System.Management.Automation.PSCredential ($username, $secpasswd)

    Initialize-LmConnectionParameters -Address 192.168.17.120 -LBPort 443 -Credential $creds

    if ($Action -eq "Disable") {
        Disable-AdcRealServer -RSIpaddress $RealIP

        $WMIHandle = Get-WmiObject -Class "Win32_TerminalServiceSetting" -Namespace "root\CIMV2\terminalservices" -ComputerName $RealServer -Authentication PacketPrivacy -Impersonation Impersonate -ErrorAction "Stop"
        $WMIHandle.SessionBrokerDrainMode = 1
    }
    if ($Action -eq "Enable") {
        Enable-AdcRealServer -RSIpaddress $RealIP

        $WMIHandle = Get-WmiObject -Class "Win32_TerminalServiceSetting" -Namespace "root\CIMV2\terminalservices" -ComputerName $RealServer -Authentication PacketPrivacy -Impersonation Impersonate -ErrorAction "Stop"
        $WMIHandle.SessionBrokerDrainMode = 0
    }

}