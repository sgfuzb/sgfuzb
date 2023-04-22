
# Uninstall-Module Posh-SSH # may need to do in ISE separately
# C:\Program Files\WindowsPowerShell\Modules
# Install-Module -Name SSHSessions
# https://www.edrockwell.com/blog/ssh-powershell-backup-cisco-devices-script/

Import-Module SSHSessions

$output = ""
$output2 = @()
$output3 = @()

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

# $switches = "MO-KHLA-IAS-01", "MO-KHGA-IAS-01"

Foreach ($switch in $switches){
    # use -verbose for debug info
    New-SSHSession -ComputerName $switch -Username "meyh" -Password "meyh2014" 
    $output = Invoke-SshCommand -ComputerName $switch -Command 'sho mac address-table' -Quiet
    
    $output2 = $output -split "`r`n"  | Select-String -SimpleMatch "STATIC"
    $output3 += $output2 | ForEach-Object {"$switch $_"}

    Get-SSHSession | Remove-SSHSession
}

$output3 | Out-GridView

