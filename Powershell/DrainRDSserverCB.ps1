Function SetRDSServer
{
    # Disable Realserver in Kemp and on load balancer
    # SG Dec 2018

    Param
    (
     [string] $RealServer,
     [ValidateSet("Enable","Disable")] [string] $Action
    )

    Import-Module RemoteDesktop

    $RealIP = [System.Net.Dns]::GetHostAddresses($RealServer) | foreach { $_.IPAddressToString | findstr "192.168.17."}
    
    $RealServer = $RealServer + ".moorfields.nhs.uk"
    $CB = "MEHCB-01.moorfields.nhs.uk"

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

        #CB Method
        Set-RDSessionHost -ConnectionBroker $CB -SessionHost $RealServer -NewConnectionAllowed NotUntilReboot
        # might need this? enable-psremoting –force
        
        #Direct WMI method
        #$WMIHandle = Get-WmiObject -Class "Win32_TerminalServiceSetting" -Namespace "root\CIMV2\terminalservices" -ComputerName $RealServer -Authentication PacketPrivacy -Impersonation Impersonate -ErrorAction "Stop"
        #$WMIHandle.SessionBrokerDrainMode = 1
    }
    if ($Action -eq "Enable") {
        Enable-AdcRealServer -RSIpaddress $RealIP

        Set-RDSessionHost -ConnectionBroker $CB -SessionHost $RealServer -NewConnectionAllowed Yes

        #$WMIHandle = Get-WmiObject -Class "Win32_TerminalServiceSetting" -Namespace "root\CIMV2\terminalservices" -ComputerName $RealServer -Authentication PacketPrivacy -Impersonation Impersonate -ErrorAction "Stop"
        #$WMIHandle.SessionBrokerDrainMode = 0
    }
}

SetRDSServer -RealServer "MEHRDS-27" -Action disable

