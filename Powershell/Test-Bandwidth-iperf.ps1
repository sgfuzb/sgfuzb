########################################
# Test bandwith using iperf between various hosts
# Steven Gill
########################################

# Set Working Directory
if ($env:computername -eq "INTRANET3"){ Set-Location "C:\PowerShell" }
if ($env:computername -eq "M016815"){ Set-Location "M:\PowerShell" }
$TestTable = @()

$TestTable += 
[PSCustomObject]@{Timestamp=(Get-Date);Site="BRC";Type="Phy";From="MEHUBI-BRC";To="MEHVMS3";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="HOX";Type="Phy";From="M020489";To="MEHVMS3";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="CR";Type="Phy";From="MEHVMS4";To="MEHVMS3";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="CRO";Type="VM";From="MEHIC9";To="RES-SQL02";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="CRO";Type="VM";From="MEHICCRO";To="RES-SQL02";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="CRO";Type="Phy";From="MEHVM-CRO";To="MEHVMS3";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="EAL";Type="VM";From="MEHICEAL";To="RES-SQL02";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="EAL";Type="Phy";From="MEHVM-EAL";To="MEHVMS3";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(get-date);Site="GCP-OE-VPC";Type="GCP";From="MEHVMS3";To="192.168.43.6";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="ME";Type="VM";From="MEHICME";To="RES-SQL02";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="ME";Type="Phy";From="MEHVM-ME";To="MEHVMS3";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="NWP";Type="VM";From="MEHICNWP";To="RES-SQL02";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="NWP";Type="Phy";From="MEHVM-NWP";To="MEHVMS3";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="PB";Type="VM";From="MEHICPB";To="RES-SQL02";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="PB";Type="Phy";From="MEHVM-PB";To="MEHVMS3";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="SLG";Type="VM";From="MEHIC6";To="RES-SQL02";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="STA";Type="VM";From="MEHICSTA";To="RES-SQL02";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="STA";Type="Phy";From="MEHVM-STA";To="MEHVMS3";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="STG";Type="VM";From="MEHICSG";To="RES-SQL02";PingFrom=0;PingTo=0;iperf1=0;iperf10=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="STG";Type="Phy";From="MEHVM-STG";To="MEHVMS3";PingFrom=0;PingTo=0;iperf1=0;iperf10=0}


$WhatIfPreference = $false # True for debug

$TestTable = @()
$TestTable += [PSCustomObject]@{Timestamp=(Get-Date);Site="CRO";Type="VM";From="RES-SQL02";To="MEHICCRO";PingFrom=0;PingTo=0;iperf1=0;iperf10=0}


# Add reverse direction(s)
ForEach ($Test in $TestTable) {
    $TestTable += [PSCustomObject]@{Timestamp=(get-date);Site=$Test.Site;Type=$Test.Type;From=$Test.To;To=$Test.From;PingFrom=0;PingTo=0;iperf1=0;iperf10=0}
}

function Test-IPerf {
    param (
        
        [ValidateSet("Win-Win", "IP-Win","Win-IP")][String]$TestType = "Win-Win",
        [ValidateSet(1, 10)][int]$NumStreams = 1,
        [String]$From,
        [String]$To
    )
    
    $Speed = 0
    
    switch ($TestType) {
        "Win-Win" {  

            for ($i = 0; $i -lt 2; $i++) {

                # Kill any currently running servers
                $output = Invoke-Command -scriptblock {TaskKill -IM iperf3.exe /F} -computername $From -ErrorAction SilentlyContinue

                # Copy commands
                Copy-Item -Path ".\iperf\iperf3.exe" -Destination "\\$From\c$\Windows\System32\"
                Copy-Item -Path ".\iperf\cygwin1.dll" -Destination "\\$From\c$\Windows\System32\"  
                Copy-Item -Path ".\iperf\iperf3.exe" -Destination "\\$To\c$\Windows\System32\"
                Copy-Item -Path ".\iperf\cygwin1.dll" -Destination "\\$To\c$\Windows\System32\"

                #Write-Host "Testing 1xTCP stream from $From to $To : " -NoNewline

                $job = Invoke-Command -scriptblock {iperf3.exe -s -1} -computername $From -AsJob

                switch ($NumStreams) {
                    1 { $scriptblock = {param($From) iperf3.exe -J -c $From} }
                    10 { $scriptblock = {param($From) iperf3.exe -J -c $From -t 10 -i 10 -w 512K -P 10} }
                    Default { }
                }

                $Results = Invoke-Command -scriptblock $scriptblock -ArgumentList $From -computername $To
                $resjson = $results | ConvertFrom-Json

                # Try again if error else break
                if ($resjson.error -like "*error*") { 
                    Write-Host "Error trying again..."
                } else {break}
            }

            $Speed = ($resjson.end.sum_received.bits_per_second / 1Mb).ToString("#.##")

        }
        "IP-Win" {

            # From fixed iperf server to Windows Machine

            # Copy commands
            Copy-Item -Path ".\iperf\iperf3.exe" -Destination "\\$To\c$\Windows\System32\"
            Copy-Item -Path ".\iperf\cygwin1.dll" -Destination "\\$To\c$\Windows\System32\"

            #Write-Host "Testing 1xTCP stream from $From to $To : " -NoNewline

            switch ($NumStreams) {
                1 { $scriptblock = {param($From) iperf3.exe -J -c $From} }
                10 { $scriptblock = {param($From) iperf3.exe -J -c $From -t 10 -i 10 -P 10} }
                #10 { $scriptblock = {param($From) iperf3.exe -J -c $From -t 10 -i 10 -w 512K -P 10} }
                Default {  }
            }

            $Results = Invoke-Command -scriptblock $scriptblock -ArgumentList $From -computername $To
            $resjson = $results | ConvertFrom-Json
            
            $Speed = ($resjson.end.sum_received.bits_per_second / 1Mb).ToString("#.##")

        }
        "Win-IP" {

            # From fixed iperf server to Windows Machine

            # Copy commands
            Copy-Item -Path ".\iperf\iperf3.exe" -Destination "\\$From\c$\Windows\System32\"
            Copy-Item -Path ".\iperf\cygwin1.dll" -Destination "\\$From\c$\Windows\System32\"

            #Write-Host "Testing 1xTCP stream from $To to $From : " -NoNewline

            switch ($NumStreams) {
                1 { $scriptblock = {param($To) iperf3.exe -J -R -c $To} }
                10 { $scriptblock = {param($To) iperf3.exe -J -R -c $To -t 10 -i 10 -P 10} }
                #10 { $scriptblock = {param($To) iperf3.exe -J -R -c $To -t 10 -i 10 -w 512K -P 10} }
                Default { }
            }

            $Results = Invoke-Command -scriptblock $scriptblock -ArgumentList $To -computername $From
            $resjson = $results | ConvertFrom-Json
            
            $Speed = ($resjson.end.sum_received.bits_per_second / 1Mb).ToString("#.##")

        }
        Default {}
    }

    if ($Speed -eq ""){
        $Speed = "0.00"
    }

    Return $Speed

}

function IsValidIPv4Address ($ip) {
    return ($ip -match "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$" -and [bool]($ip -as [ipaddress]))
}


ForEach ($Test in $TestTable) {

    $From = $Test.From
    $To = $Test.To
    $Test.Timestamp = (Get-Date)

    $PingFrom = Test-Connection -ComputerName $From -Count 3
    $PingTo = Test-Connection -ComputerName $To -Count 3

    if (($PingFrom) -and ($PingTo)){

        $Test.PingFrom = $PingFrom[0].ResponseTime
        $Test.PingTo = $PingTo[0].ResponseTime

        If (!(IsValidIPv4Address($From)) -and !(IsValidIPv4Address($To))) { $TestType = "Win-Win" }
        If (!(IsValidIPv4Address($From)) -and (IsValidIPv4Address($To))) { $TestType = "Win-IP" }
        If ((IsValidIPv4Address($From)) -and !(IsValidIPv4Address($To))) { $TestType = "IP-Win" }

        Write-Host "Testing 1xTCP stream from $From to $To : " -NoNewline
        $Test.iperf1 = Test-IPerf -TestType $TestType -NumStreams 1 -From $From -To $To
        Write-Host $Test.iperf1 Mb/s

        Write-Host "Testing 10xTCP stream from $From to $To : " -NoNewline
        $Test.iperf10 = Test-IPerf -TestType $TestType -NumStreams 10 -From $From -To $To
        Write-Host $Test.iperf10 Mb/s
        
    } else {
        # one or more offline
    }
}

$TestTable | Out-GridView

Break

$TestTable | Export-Csv ".\Test-Bandwidth-iperf.csv" -NoTypeInformation

# ===================================================
# Report and email
# ===================================================

$EmailSMTP = "smtp.moorfields.nhs.uk"
$EmailFrom = "iperf@moorfields.nhs.uk"
$EmailTo = "moorfields.italerts@nhs.net"

$Message = "Iperf report attached"

#Settings for Email Message
$rptDate=(Get-date)

$messageParameters = @{ 
    Subject = "[iPerf Bandwidth Report on " + $rptDate.ToString($cultureENGB) + "]"
    Body = $Message
    From = $EmailFrom
    To = $EmailTo
    Attachments = ".\Test-Bandwidth-iperf.csv"
    SmtpServer = $EmailSMTP
} 
#Send Report Email Message
Send-MailMessage @messageParameters -BodyAsHtml
