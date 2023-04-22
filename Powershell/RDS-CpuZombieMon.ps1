<#======================================

Zombie TS Session monitor
Requires PSTerminialServer.msi Powersehell/Cassia extension (install in %ProgramFiles%\WindowsPowerShell\Modules)
Steven Gill
01/12/18 - Initial
22/12/21 - Updated with CPU monitoring and setting Kemp weighting
08/01/22 - Updated with parallel jobs and get kemp vs to speed up

======================================#>

Import-Module Kemp.LoadBalancer.Powershell
Import-Module PSTerminalServices
Import-Module RemoteDesktop

$computernames = @()
$queryResults = @()
$Global:KempStatus = @()
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
$LowDiskThreshold = 5

# Take 5 (CPUSamples) samples 3 (CPUSampleInterval) seconds apart
$CPUSamples = 10
$CPUSampleInterval = 3

# Sync Hash table for parallel job data passing
$Configuration = [hashtable]::Synchronized(@{})
$Configuration.CPUSamples = $CPUSamples
$Configuration.CPUSampleInterval = $CPUSampleInterval
$Configuration.Result = @()


For ($i = 1; $i -le $MaxRDSServer; $i++) {
    If ($i -lt 10) { $servername = "MEHRDS-0" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }
    $ComputerNames += $servername
}

# Set for testing
#$ComputerNames = "MEHRDS-71"
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
        $Global:MessageImp += (get-date).ToString($cultureENGB) + ", " + $SGlogMessage + "<br>"
        $global:Issues++ 
    }

}

Function QueryKemp
{
    $Global:KempStatus = @()

    foreach ($NLBIP in $NLBIPs) {
        $getvs = Get-AdcVirtualService -VirtualService $NLBIP -VSPort 3389 -VSProtocol tcp 
        
        if ($getvs.ReturnCode -eq 200){ 
            
            $Global:KempStatus += $getvs.Data.vs.rs

        } Else {
            Write-SGLog "Error querying kemp" 
        }
    }

    # $KempStatus | Out-GridView
}

Function GetRDSServer
{
    Param
    (
        [string] $RealServer
    )

    $RealIP = [System.Net.Dns]::GetHostAddresses($RealServer) | ForEach-Object { $_.IPAddressToString | findstr "192.168.17."}
    $RealServer = $RealServer + ".moorfields.nhs.uk"

    Foreach ($Kemprs in $Global:KempStatus) {
        if ($Kemprs.Addr -eq $RealIP) {
            switch ($Kemprs.Weight) {
                "1000" { $result = $true }
                "1" { $result = $false }
                Default { $result = $null }
            }            
        }
    }

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
    }
}

Function QueryRDSServers {

    $Configuration.Result = @()

    $Worker = {
        Param($Computer, $Configuration)

        Try {
            # Check CPU
            $queryCPU = Get-Counter -ComputerName $Computer '\Processor(_total)\% Processor Time' -MaxSamples $Configuration.CPUSamples -SampleInterval $Configuration.CPUSampleInterval
            $queryCPUAvg = [math]::round(($queryCPU | Select-Object -ExpandProperty CounterSamples | Group-Object -Property InstanceName | ForEach-Object { $_ | Select-Object -Property  @{n='Average';e={(($_.Group | Measure-Object -Property CookedValue -Average).Average)}};}).average,2)

            # Check Zombies
            $numzombies = 0
            $numnormal = (Get-TSSession -ComputerName $Computer |  where-object -Property username).count           
            $queryResults = Get-TSSession -ComputerName $Computer -State Disconnected -UserName ""
            foreach ($result in $queryResults) { if ($result.SessionId.ToString() -ne "0") { $numzombies++ } }
            
            # Check Disk
            #$DiskFreeGB = [Math]::Floor((Get-Volume | Where-Object {$_.DriveLetter -eq "C"}).SizeRemaining / 1gb)
            $DiskFreeGB = [Math]::Floor((Get-WmiObject Win32_LogicalDisk -ComputerName $Computer -Filter "DeviceID='C:'").FreeSpace /1GB)

            $isError = $false

        } Catch { 
            Write-Host "$Computer : " + $_.Exception.Message
            $queryCPUAvg = 0
            $DiskFreeGB = 0
            $numnormal = 0
            $numzombies = 0
            $isError = $true
        }

        Write-Host "$Computer : CPU $queryCPUAvg, CFree $DiskFreeGB, #NSess $numnormal, #ZSess $numzombies, Err $isError"

        $Configuration.Result += [PSCustomObject]@{
            Computer = $Computer
            CPUAvg = $queryCPUAvg
            DiskFree = $DiskFreeGB
            RDSNormal = $numnormal
            RDSZombies = $numzombies
            isError = $isError
        }
    }

    $MaxRunspaces = 72
    $SessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $MaxRunspaces, $SessionState, $Host)
    $RunspacePool.Open()

    $Jobs = New-Object System.Collections.ArrayList

    ForEach ($Computer in $ComputerNames) {

        #Write-Host "Creating runspace for $Computer"
        $PowerShell = [powershell]::Create()
        $PowerShell.RunspacePool = $RunspacePool
        $PowerShell.AddScript($Worker).AddArgument($Computer).AddArgument($Configuration) | Out-Null
        
        $JobObj = New-Object -TypeName PSObject -Property @{
            Runspace = $PowerShell.BeginInvoke()
            PowerShell = $PowerShell  
        }

        $Jobs.Add($JobObj) | Out-Null
    }

    while ($Jobs.Runspace.IsCompleted -contains $false) {
        #Write-Host (Get-date).Tostring() "Still running..."
        Start-Sleep -Milliseconds 500
    }

}

Function ValidateRDSServers
{
    ForEach ($Result in $Configuration.Result) {

        $SvrMessage = ""
        $SvrIssues = 0

        $computer = $Result.Computer
        $queryCPUAvg = $Result.CPUAvg
        $DiskFreeGB = $Result.DiskFree
        $numnormal = $Result.RDSNormal
        $numzombies = $Result.RDSZombies
        $isError = $Result.isError

        #$SvrMessage += "================================================="
        $SvrMessage += "$computer"

        if ($isError -eq $false) {

            # ZOMBIES
            $SvrMessage += ", Zombie/Total: $numzombies/$numnormal"
            $Totalzombies += $numzombies

            # Warn of >2 zombies
            if ($numzombies -gt 2){ $SvrIssues++ }

            # Disable if lots of zombies
            if ($numzombies -gt $MaxZombies){
                
                $SvrMessage += ", [More than $MaxZombies Zombie sessions, disabling]"
                $SvrIssues++
                SetRDSServer -RealServer $Computer -Action Disable
            }

            # DISK
            $SvrMessage += ", Disk Free: $DiskFreeGB GB"

            # Disable if C < threshold
            if ($DiskFreeGB -lt $LowDiskThreshold){
        
                $SvrMessage += ", [C drive less than $LowDiskThreshold GB, disabling]"
                $SvrIssues++
                SetRDSServer -RealServer $Computer -Action Disable

                # Run Delprof
                Invoke-Command -ComputerName $Computer -ScriptBlock { c:\source\delprof2.exe /u}

            }

            # Re-Enable if C > threshold
            if ($DiskFreeGB -gt $LowDiskThreshold){

                # Check if already enabled
                if(!(GetRDSServer -RealServer $Computer)){

                    $SvrMessage += ", [C drive more than $LowDiskThreshold GB, enabling]"
                    #$SvrIssues++
                    SetRDSServer -RealServer $Computer -Action Enable
                }
            }
            
            # CPU
            $SvrMessage += ", CPU Avg: $queryCPUAvg %"

            # Disable if high cpu
            if ($queryCPUAvg -gt $HighCPUThreshold){

                # Check if already disabled
                if((GetRDSServer -RealServer $Computer)){

                    #Write-SGLog "[CPU Average > $CPU %, disabling] "

                    SetRDSServer -RealServer $Computer -Action Disable

                    $Text = ", [High CPU - Disabled - AvCPU: " + $queryCPUAvg + "]"
                    $SvrMessage += $Text
                    $SvrIssues++
                    #Write-SGLog -SGlogMessage $Text -SGLogIssues $true
                }
            }

            # Re-Enable if CPU back to normal
            if ($queryCPUAvg -lt $LowCPUThreshold){

                # Check if already enabled
                if(!(GetRDSServer -RealServer $Computer)){
                    
                    SetRDSServer -RealServer $Computer -Action Enable

                    #$Text = ", [Normal CPU - Enabled - AvCPU: " + $queryCPUAvg + "]"
                    #$SvrMessage += $Text
                    #$SvrIssues++
                    #Write-SGLog -SGlogMessage $Text -SGLogIssues $true
                }
            }
        } else {
            $Text = "Error"
            $SvrMessage += $Text
            #$SvrIssues++
        }

        If($SvrIssues -gt 0) {
            Write-SGLog -SGlogMessage $SvrMessage -SGlogIssues $true
        } else {
            Write-SGLog -SGlogMessage $SvrMessage -SGlogIssues $false
        }
    }
    
    Write-SGLog -SGlogMessage "Total Issues: $global:Issues" -SGlogIssues $false

    If ($Totalzombies -gt 2){
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
            Subject = "[RDS Health - High CPU or Zombie Sessions]"
            Body = `
            "=================================================================<br>" + `
            "RDS Health : Enabled/Disabled servers - changes weighting in Kemp <br>" + `
            $rptDate.ToString($cultureENGB) + "<br>" +`
            "=================================================================<br>" + `
            $Global:MessageImp + `
            "=================================================================<br>"
            From = "it.alerts@moorfields.nhs.uk" 
            To = "moorfields.italerts@nhs.net","sg@nhs.net"
            #, "vikash@nhs.net", "alan.florence@nhs.net", "roy.gray@nhs.net", "m.sears@nhs.net", "h.juttla@nhs.net"
            SmtpServer = "smtp.moorfields.nhs.uk"
            #SmtpServer = "127.0.0.1"
        } 
        #Send Report Email Message
        Send-MailMessage @messageParameters -BodyAsHtml
    }
    
    $Global:Message = ""
    $Global:MessageImp = ""
    $Global:Issues = 0
}

# Main

While ($true) {

    $QueryKempTime = Measure-Command { QueryKemp }
    $QueryRDSTime = Measure-Command { QueryRDSServers }
    $ValidateTime = Measure-Command { ValidateRDSServers }

    Write-Host "Query Kemp Time (s): " $QueryKempTime.TotalSeconds
    Write-Host "Query RDS Time (s): " $QueryRDSTime.TotalSeconds
    Write-Host "Validate Time (s): " $ValidateTime.TotalSeconds

    $Configuration.Result | Out-GridView
    break

    If ($global:Issues -gt 10 ) {
        SendEmail
    }

    # Wait a minute!
    Start-Sleep -Seconds 60       
}