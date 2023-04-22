Import-Module Kemp.LoadBalancer.Powershell


Function SetRDSServer
{
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


Function KempAction
{
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
    }
    if ($Action -eq "Enable") {
    Enable-AdcRealServer -RSIpaddress $RealIP
    }

}


SetRDSServer -RealServer "MEHRDS-34" -Action    Disable

#KempAction -RealServer "MEHRDS-" -Action Enable
