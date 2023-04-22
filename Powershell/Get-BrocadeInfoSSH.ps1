# Uninstall-Module Posh-SSH # may need to do in ISE separately
# C:\Program Files\WindowsPowerShell\Modules
# Install-Module -Name SSHSessions
# https://www.edrockwell.com/blog/ssh-powershell-backup-cisco-devices-script/

Import-Module SSHSessions

$porterrs = @()
$switches = @()

$switches = 
"MO-ESG-SN6600B-01",
"MO-ESG-SN6600B-02",
"MO-ESG-SN6600B-03",
"MO-RDLG-SN6600B-01",
"MO-RDLG-SN6600B-02",
"MO-RDLG-SN6600B-03"

#$switches = "MO-ESG-SN6600B-01"

#$User = "admin"
#$PWord = ConvertTo-SecureString -String "xxx" -AsPlainText -Force
#$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$creds = Get-Credential

function Clear-FCPortErrors {
    param (
        $Switches,
        [PSCredential] $creds
    )
    
    $outputs = @()

    Foreach ($switch in $switches){
        # use -verbose for debug info
        New-SSHSession -ComputerName $switch -Credential $creds
        $outputs += Invoke-SshCommand -ComputerName $switch -Command 'portStatsClear -i 0-63' -Quiet
        Get-SSHSession | Remove-SSHSession
    }
}

function Get-FCAliases {
    param (
        [array[]] $Switches,
        [PSCredential] $creds
    )
    # TODO
    # brocade; nsaliasshow
    $outputs = @()
    $FCDeets = @()

    Foreach ($switch in $switches){
        # use -verbose for debug info
        New-SSHSession -ComputerName $switch -Credential $creds
        $outputs += Invoke-SshCommand -ComputerName $switch -Command 'nsaliasshow' -Quiet
        Get-SSHSession | Remove-SSHSession
    }

    #$outputs | Out-GridView

    $FCDeets = @()

    # Process command output

    Foreach($out in $outputs){
        $lines = $out.result.Split([Environment]::NewLine) | Where-Object { $_ -ne "" }

        $i = 0
        While ( $i -lt $lines.Count - 1) {

            While ($lines[$i].Substring(0,5) -ne " N   "){ 
                $i++
            }

            Write-Host "Start of record"

            #$FCItem = ($lines[$i].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value

            $FCDeet = [PSCustomObject]@{
                "SwitchName" = $out.ComputerName
                "SCR" = ($lines[$i+1].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
                "FC4s" = ($lines[$i+2].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
                "Fabric Port Name" = ($lines[$i+3].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
                "Permanent Port Name" = ($lines[$i+4].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
                "Device type" =($lines[$i+5].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
                "Port Index" =($lines[$i+6].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
                "Share Area" =($lines[$i+7].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
                "Redirect" =($lines[$i+8].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
                "Partial" =($lines[$i+9].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
                "LSAN" =($lines[$i+10].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
                "Slow Drain Device" = ($lines[$i+11].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
                "Device link speed" =($lines[$i+12].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
                "Connected through AG" =($lines[$i+13].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
                "Real device behind AG" =($lines[$i+14].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
                "FCoE" =($lines[$i+15].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
                "FC4 Features [FCP]" =($lines[$i+16].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
                "Aliases" = ($lines[$i+17].trim() -Replace ":","," | ConvertFrom-Csv -Header Item,Value).Value
            }

            $FCDeets += $FCDeet
            $i = $i+18
        }
    }
    
    $FCDeets | Out-GridView

Return $FCAliases

}

function Get-FCPortErrors {
    param (
        [array[]] $Switches,
        [PSCredential] $creds
    )
    
    $porterrs = @()
    $outputs = @()

    Foreach ($switch in $switches){
        # use -verbose for debug info
        New-SSHSession -ComputerName $switch -Credential $creds
        $outputs += Invoke-SshCommand -ComputerName $switch -Command 'porterrshow' -Quiet
        Get-SSHSession | Remove-SSHSession
    }

    #$outputs | Out-GridView

    # Process command output

    Foreach($out in $outputs){
        $lines = $out.result.Split([Environment]::NewLine) | Where-Object { $_ -ne "" }

        for ($i = 3; $i -lt $lines.Count - 1; $i++ )
        {   
            $PortErr = $lines[$i].trim() -Replace "\s+","," -Replace ":","" | ConvertFrom-Csv -Header Port,Frametx,Framerx,encin,crcerr,crcg_eofc,tooshrt,toolong,badeof,encout,discc3,linkfail,losssync,losssig,frjt,fbsy,c3timeouttx,c3timeoutrx,pcserr,uncorerr
            
            $Porterrs += [PSCustomObject]@{
                SwitchName = $out.ComputerName
                Port = $porterr.port
                Frametx = $porterr.Frametx
                Framerx = $porterr.Framerx
                encin = $porterr.encin
                crcerr = $porterr.crcerr
                crcg_eofc = $porterr.crcg_eofc
                tooshrt = $porterr.tooshrt
                toolong = $porterr.toolong
                badeof = $porterr.badeof
                encout = $porterr.encout
                discc3 = $porterr.discc3
                linkfail = $porterr.linkfail
                losssync = $porterr.losssync
                losssig = $porterr.losssig
                frjt = $porterr.frjt
                fbsy = $porterr.fbsy
                c3timeouttx = $porterr.c3timeouttx
                c3timeoutrx = $porterr.c3timeoutrx
                pcserr = $porterr.pcserr
                uncorerr = $porterr.uncorerr

            }        
        }
    }

    Return $Porterrs
}

break

# Clear Port Errors
Clear-FCPortErrors -Switches $switches -creds $creds

break

# Get port errors
$Porterrs = Get-FCPortErrors -Switches $switches -creds $creds

# Output errors
#$Porterrs | Out-GridView # All
#$Porterrs | Where-Object {($_.crcerr -gt 0)} | Out-GridView # Ports with CRC errors
$porterrs | Where-Object {($_.Framerx -gt 0)} | Out-GridView # Only active ports

break

$FCAliases = Get-FCAliases -Switches $switches -creds $creds

$FCAliases | Out-GridView 
