Function GetRDSServerW
{
    # Get  Realserver enabled status in Kemp
    Param
    (
        [string] $RealServer
    )

    $RealIP = [System.Net.Dns]::GetHostAddresses($RealServer) | ForEach-Object { $_.IPAddressToString | findstr "192.168.17."}
    $RealServer = $RealServer + ".moorfields.nhs.uk"

    #Write-SGLog "GetRDSServer: Getting $realserver on $realip"

    # Try Each Virtual Service
    
    foreach ($NLBIP in $NLBIPs) {

        $getrs = Get-AdcRealServer -RealServer $RealIP -RSPort 3389 -VirtualService $NLBIP -VSPort 3389 -VSProtocol tcp 

        if ($getrs.ReturnCode -eq 422){ 
            #Write-SGLog "$realserver  not in $NLBIP"
        }
        if ($getrs.ReturnCode -eq 200){ 
            #Write-SGLog "$realserver  is in $NLBIP"
            break
        }
    }

    switch ($getrs.Data.Rs.Weight) {
        "1000" { $result = $true }
        "1" { $result = $false }
        Default { $result = $null }
    }

    # Write-SGLog "GetRDSServer: $realserver .enabled = $result"

    Return $result
}

Function SetRDSServer
{
    # Disable Realserver in Kemp
    Param
    (
     [string] $RealServer,
     [ValidateSet("Enable","Disable")] [string] $Action
    )

    #Write-SGLog "SetRDSServer: Setting $realserver to $Action"

    $RealIP = [System.Net.Dns]::GetHostAddresses($RealServer) | ForEach-Object { $_.IPAddressToString | findstr "192.168.17."}

    $RealServer = $RealServer + ".moorfields.nhs.uk"
    #$CB = "MEHCB-01.moorfields.nhs.uk"

    if ($Action -eq "Disable") {
        
        # Set weight method
        foreach ($NLBIP in $NLBIPs) {

            $setrs = Set-AdcRealServer -RealServer $RealIP -Weight 1 -VirtualService $NLBIP -VSProtocol tcp -VSPort 3389 -RealServerPort 3389
    
            if ($setrs.ReturnCode -eq 422){ 
                #Write-SGLog "$realserver  not in $NLBIP"
            }
            if ($setrs.ReturnCode -eq 200){ 
                #Write-SGLog "$realserver  is in $NLBIP"
                break
            }
        }

        # Enable/disable method - but overlaps with manual enabling
        #Disable-AdcRealServer -RSIpaddress $RealIP

        #CB Method
        #Set-RDSessionHost -ConnectionBroker $CB -SessionHost $RealServer -NewConnectionAllowed NotUntilReboot
        # might need this? enable-psremoting –force
        
        #WMI method
        #$WMIHandle = Get-WmiObject -Class "Win32_TerminalServiceSetting" -Namespace "root\CIMV2\terminalservices" -ComputerName $RealServer -Authentication PacketPrivacy -Impersonation Impersonate -ErrorAction "Stop"
        #$WMIHandle.SessionBrokerDrainMode = 1
    }
    if ($Action -eq "Enable") {

        # Set weight method
        foreach ($NLBIP in $NLBIPs) {

            $setrs = Set-AdcRealServer -RealServer $RealIP -Weight 1000 -VirtualService $NLBIP -VSProtocol tcp -VSPort 3389 -RealServerPort 3389

            if ($setrs.ReturnCode -eq 422){ 
                #Write-SGLog "$realserver  not in $NLBIP"
            }
            if ($setrs.ReturnCode -eq 200){ 
                #Write-SGLog "$realserver  is in $NLBIP"
                break
            }
        }

        # Enable/disable method - but overlaps with manual enabling
        #Enable-AdcRealServer -RSIpaddress $RealIP

        #Set-RDSessionHost -ConnectionBroker $CB -SessionHost $RealServer -NewConnectionAllowed Yes

        #$WMIHandle = Get-WmiObject -Class "Win32_TerminalServiceSetting" -Namespace "root\CIMV2\terminalservices" -ComputerName $RealServer -Authentication PacketPrivacy -Impersonation Impersonate -ErrorAction "Stop"
        #$WMIHandle.SessionBrokerDrainMode = 0
    }

    <#
    https://support.kemptechnologies.com/hc/en-us/articles/4405983364621-Kemp-LoadMaster#MadCap_TOC_17_2

    3.7 Fixed Weighted
    The highest weight Real Server is only used when other Real Server(s) are given lower weight values. 
    However, if the highest weighted server fails, the Real Server with the next highest priority number will be available to serve clients. 
    The weight for each Real Server should be assigned based on the priority among the Real Server(s).
    #>

}