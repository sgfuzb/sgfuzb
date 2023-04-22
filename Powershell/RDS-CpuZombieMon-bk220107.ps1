<#======================================

Zombie TS Session monitor
Requires PSTerminialServer.msi Powersehell/Cassia extension (install in %ProgramFiles%\WindowsPowerShell\Modules)
Steven Gill
01/12/18 - Initial
22/12/21 - Updated with CPU monitoring and setting Kemp weighting

======================================#>

Import-Module Kemp.LoadBalancer.Powershell
Import-Module PSTerminalServices
Import-Module RemoteDesktop

$computernames = @()
$queryResults = @()
$Totalzombies = 0

$Global:Message = ""
$Global:MessageImp = ""
$Global:Issues = 0
$cultureENGB = New-Object System.Globalization.CultureInfo("en-GB")

$MaxRDSServer = 72
$NLBIPs = "192.168.17.100","192.168.17.170","192.168.17.70","192.168.17.180","192.168.17.54","192.168.17.54"
$MaxZombies = 5
$HighCPUThreshold = 95
$LowCPUThreshold = 40
$CPUSamples = 1
$CPUSampleInterval = 1
#$CPUSamples = 1
#$CPUSampleInterval = 1


For ($i = 1; $i -le $MaxRDSServer; $i++) {
    If ($i -lt 10) { $servername = "MEHRDS-0" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }
    $ComputerNames += $servername
}



<# change computernames to custom object, computername, enabled, cpu
$returning = New-Object -TypeName System.Collections.Generic.List[psobject]
$returning.Add( 
    [pscustomobject]@{
            Source = 'Citrix'
            PhaseName = 'App/Desktop Icon Clicked until ICA File Downloaded'
            StartTime = $clickTime
            EndTime   = $clientStartup.WfIcaTimestamp
            Duration  = ($ClientStartup.SCD - $ClientStartup.SCCD) / 1000 } )
        #>


# Set for testing
#$ComputerNames = "MEHRDS-30"
#$WhatifPreference = $false

# Setup Kemp access
$username = "bal"
$passwd = "Password1234"
$secpasswd = ConvertTo-SecureString "$passwd" -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential ($username, $secpasswd)

Initialize-LmConnectionParameters -Address 192.168.17.120 -LBPort 443 -Credential $creds | Out-Null

Function Write-SGLog
{
    Param
    (
        [string] $SGlogMessage,
        [boolean] $SGlogIssues = $false
    )

    $Text = (get-date).ToString() + ", " + $SGlogMessage
    Write-Host $Text

    $global:Message += $SGlogMessage + "<br>"
    If ($SGlogIssues) { 
        $Global:MessageImp += $SGlogMessage + "<br>"
        $global:Issues++ 
    }

}
Function GetRDSServer
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

    switch ($getrs.Data.Rs.Enable) {
        "Y" { $result = $true }
        "N" { $result = $false }
        Default { $result = $null }
    }

    #Write-SGLog "GetRDSServer: $realserver .enabled = $result"

    Return $result
}

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

    #Write-SGLog "GetRDSServer: $realserver .enabled = $result"

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
        ##Set-RDSessionHost -ConnectionBroker $CB -SessionHost $RealServer -NewConnectionAllowed NotUntilReboot
        # might need this? enable-psremoting –force
        
        #Direct WMI method
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

        ##Set-RDSessionHost -ConnectionBroker $CB -SessionHost $RealServer -NewConnectionAllowed Yes

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

Function CheckRDSServers
{
    ForEach ($Computer in $ComputerNames) {

        $SvrMessage = ""
        $SvrIssues = 0

        #$SvrMessage += "================================================="
        $SvrMessage += "$Computer"

        # Query RDS sessions
        $queryResults = Get-TSSession -ComputerName $Computer -State Disconnected -UserName ""
        $queryResultsNormal = Get-TSSession -ComputerName $Computer |  where-object -Property username
        $numzombies = 0
        $numnormal = $queryResultsNormal.count

        foreach ($result in $queryResults)
        {
            if ($result.SessionId.ToString() -ne "0") { $numzombies++ }
        }
        $Totalzombies += $numzombies

        $SvrMessage += ", Zombie sessions: $numzombies, Total sessions: $numnormal"

        if ($numzombies -gt 0){ $SvrIssues++ }

        # disable if lots of zombies
        if ($numzombies -gt $MaxZombies){
            
            $SvrMessage += ", [More than $MaxZombies Zombie sessions, disabling]"
            $SvrIssues++
            SetRDSServer -RealServer $Computer -Action Disable
        }
        
        #$Text = $Computer + ", Zombie/OK sessions: " + $numzombies + "/"+ $numnormal 
        #$SvrMessage += $Text + "<br>"      
        
        # Query RDS average CPU, try two more times if fails
        $Failure = 1
        while (($Failure -gt 0) -and ($Failure -lt 4)) {
            try {
                $queryCPU = Get-Counter -ComputerName $Computer '\Processor(_total)\% Processor Time' -MaxSamples $CPUSamples -SampleInterval $CPUSampleInterval
                $queryCPUAvg = [math]::round(($queryCPU | Select-Object -ExpandProperty CounterSamples | Group-Object -Property InstanceName | ForEach-Object { $_ | Select-Object -Property  @{n='Average';e={(($_.Group | Measure-Object -Property CookedValue -Average).Average)}};}).average,2)
                $Failure = 0
            }
            catch {
                $Text = $Computer + ", Query Failed:" + $_.Exception.Message 
                $SvrMessage += $Text
                $SvrIssues++ # rem out of do not need email on failures
                $Failure++
            }
        }

        $SvrMessage += ", CPU Average: $queryCPUAvg %"

        # only output to email if there is high cpu
        if ($queryCPUAvg -gt $HighCPUThreshold){

            #Write-SGLog "[CPU Average > $CPU %, disabling] "

            SetRDSServer -RealServer $Computer -Action Disable

            $Text = ", [High CPU - Disabled - AvCPU: " + $queryCPUAvg + "]"
            $SvrMessage += $Text
            $SvrIssues++
            #Write-SGLog -SGlogMessage $Text -SGLogIssues $true
        }

        # if disabled by this script - re-enable
        if ($queryCPUAvg -lt $LowCPUThreshold){
            if(!(GetRDSServerW $Computer)){
                SetRDSServer -RealServer $Computer -Action Enable

                $Text = ", [Normal CPU - Enabled - AvCPU: " + $queryCPUAvg + "]"
                $SvrMessage += $Text
                $SvrIssues++
                #Write-SGLog -SGlogMessage $Text -SGLogIssues $true
            }
        }

        If($SvrIssues -gt 0) {
            Write-SGLog -SGlogMessage $SvrMessage -SGlogIssues $true
        } else {
            Write-SGLog -SGlogMessage $SvrMessage -SGlogIssues $false
        }
    }
    
    Write-SGLog -SGlogMessage "Total Issues: $global:Issues" -SGlogIssues $false

    If ($Totalzombies -gt 0){
        $Text = "TotalZombies: " + $Totalzombies 
        #$SvrMessage += $Text + "<br>"
        Write-SGLog -SGlogMessage $Text -SGlogIssues $true
    }
}

Function SendEmail {

    If ($global:Issues -gt 0){
   
        #Settings for Email Message
        $rptDate=(Get-date)
        $messageParameters = @{ 
            Subject = "[RDS Health - High CPU or Zombie Sessions ("+$Totalzombies+") on " + $rptDate.ToString($cultureENGB) + "]"
            Body = "===========<br>" + "RDS Health : Enabled/Disabled servers - changes weighting in Kemp" + "<br>===========<br>" + $Global:MessageImp + "===========<br>"
            From = "it.alerts@moorfields.nhs.uk" 
            To = "moorfields.italerts@nhs.net","sg@nhs.net"
            #, "vikash@nhs.net", "alan.florence@nhs.net", "roy.gray@nhs.net", "m.sears@nhs.net", "h.juttla@nhs.net"
            SmtpServer = "smtp.moorfields.nhs.uk"
            #SmtpServer = "127.0.0.1"
        } 
        #Send Report Email Message
        Send-MailMessage @messageParameters -BodyAsHtml
    }
    
    $global:Message = ""
}


#While ($true) {
    CheckRDSServers
    SendEmail
#}


        <#

        $NameSpace = "root\CIMV2\terminalservices"
        $wmi = [WMISearcher]""
        $wmi.options.timeout = (New-Timespan -Seconds 5)
        $query = 'Select * from Win32_TerminalServiceSetting'
        $wmi.scope.path = "\\$Computer\$NameSpace"
        $wmi.query = $query
        $wmi.Scope.Options.Authentication = "PacketPrivacy"
        $wmi.Scope.Options.Impersonation = "Impersonate"
        $WMIHandle = $wmi.Get()
        
        #$WMIHandle = Get-WmiObject -Class "Win32_TerminalServiceSetting" -Namespace "root\CIMV2\terminalservices" -ComputerName $Computer -Authentication PacketPrivacy -Impersonation Impersonate -ErrorAction "Stop"
        $Drainmode = $WMIHandle.SessionBrokerDrainMode
        $Drainmodetxt = switch ($Drainmode)
        {
        0 { "Allow all connections" }
        1 { "Allow reconnections, but prevent new logons until the server is restarted" }
        2 { "Allow reconnections, but prevent new logons" }
        default {"Unknown"}
        }

        #>