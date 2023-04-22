
# Install-Module Posh-SSH -Repository PSGallery -Verbose -Force
# Install-Module posh-ssh -RequiredVersion '2.2' -Force
Import-Module 'Posh-SSH'

$output = ""
$output2 = @()
$output3 = @()

#Set Creds
$secpasswd = ConvertTo-SecureString "meyh2014" -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential ("meyh", $secpasswd)

$switches = "MO-KHLA-IAS-01",
"MO-KHGA-IAS-01",
"MO-KH1A-IAS-01",
"MO-KH1B-IAS-01",
"MO-KH2A-IAS-01",
"MO-KH2A-TEST-3850-01",
"MO-KH3A-IAS-01",
"MO-KH4A-IAS-01",
"MO-KH5A-IAS-01",
"MO-ESG-EAS-01",
"MO-ESGA-IAS-01",
"MO-ES2A-IAS-01",
"MO-CSGA-IAS-01",
"MO-CRGD-IAS-01",
"MO-CS1A-IAS-01",
"MO-CS2A-IAS-01",
"MO-CS3A-IAS-01",
"MO-CS4A-IAS-01",
"MO-CS5A-IAS-01",
"MO-IOLA-IAS-01",
"MO-RDLG-3850-LGCY-01",
"MO-RDLG-IAS-01",
"MO-RDGA-IAS-01",
"MO-RD1A-IAS-01",
"MO-RD2A-IAS-01",
"MO-RD3A-IAS-01",
"MO-RD4A-IAS-01",
"MO-RD5A-IAS-01",
"MO-CRLA-IAS-01",
"MO-CRLB-IAS-01",
"MO-CRLC-IAS-01",
"MO-CRLD-IAS-01",
"MO-CRLG-3850-LGCY-01",
"MO-CRLG-EAS-01",
"MO-CRGB-IAS-01",
"MO-CRGC-IAS-01",
"MO-CRGD-IAS-02",
"MO-CR1A-IAS-01",
"MO-CR1B-IAS-01",
"MO-CR2A-2960X-LGCY-01",
"MO-CR2A-IAS-01",
"MO-CR2A-IAS-02",
"MO-CR2B-2960X-LGCY-01",
"MO-CR2B-IAS-01",
"MO-CR2C-IAS-01",
"MO-CM2A-IAS-01",
"MO-CM4A-IAS-01",
"MO-CR3C-IAS-01",
"MO-CR3D-IAS-01",
"MO-CR4A-IAS-01",
"MO-CR4B-IAS-01",
"MO-CY01-IAS-01",
"MO-CY02-IAS-01",
"MO-CYNG-IAS-01",
"MO-EA01-IAS-01",
"MO-EA01-IAS-02",
"MO-EA01-IAS-03",
"MO-EA01-IAS-04",
"MO-ME01-IAS-01",
"MO-ME01-IAS-02",
"MO-NP01-IAS-01",
"MO-NP01-IAS-02",
"MO-PB01-IAS-01",
"MO-PB01-IAS-02",
"MO-PU01-IAS-01",
"MO-SA01-IAS-01",
"MO-ST01-IAS-01"

$switches = "MO-KHLA-IAS-01",
"MO-KHGA-IAS-01"

# only works on first switch then says timeout - use other ssh module

Foreach($switch in $switches){
    New-SSHSession -ComputerName $switch -Credential $creds -AcceptKey 
}

$sessions = Get-SSHSession

Foreach($session in $sessions){
    
    if ($session.count -ge 1) {
        
        # Build open stream for use in cisco devices
        #$session = Get-SSHSession | Select-Object -ExpandProperty SessionID -First 1
        #$stream = $session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)

        $stream = New-SSHShellStream -SSHSession $session
        
        # Cisco Commands
        #$stream.Write("terminal length 0`n")
        #$stream.Write("sho mac address-table`n")
        $stream.WriteLine("terminal length 0")
        $stream.Writeline("sho mac address-table")

        start-sleep 10
        $output = $stream.Read()
        $output2 = $output -split "`r`n"  | Select-String -SimpleMatch "STATIC"
        $output3 += $output2 | ForEach-Object {"$switch $_"}
        
        #$output3 = $output2 -split "\s+"

        #$stream.Write("logout`n")
        #Get-SSHSession | Remove-SSHSession
        #Remove-SSHSession -Index 0
        Remove-SSHSession -SessionId $session

    }
}

$output3 | Out-GridView
<#
Import-Module 'Posh-SSH'

if ($dev.devtype -eq 4) {
    # DEVTYPE 4 - PROCURVE SWITCH
    "`n[INFO] `t $date - $devnm backup started" | Out-File $log -append
    $Session = New-SSHSession -ComputerName $dev.ip -Credential $devcreds -acceptkey:$true
    $stream = $Session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
    sleep 10
    $stream.Write("`n")
    $stream.Write("no page`n")
    $clearbuff = $stream.Read()
    sleep 2
    $stream.Write("show run`n")
    sleep 5
    $cfg = $stream.Read() 
    $cfg = $cfg  -split "`n" | ?{$_ -notmatch "\x1B"}   # strip out ANSI Escape Chars
    sleep 1
    out-file -filepath $bloc -inputobject $cfg
    Remove-SSHSession -SSHsession $session | out-null
    "[INFO] `t $date - $devnm backup finished" | Out-File $log -append
  }
  #>