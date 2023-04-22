
$MaxServer = 72
$Serverlist = @()

For ($i = 1; $i -le $MaxServer; $i++) {
    If ($i -lt 10) { $servername = "MEHRDS-0" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }
    $Serverlist += $servername
}

# override
$serverlist = "MEHRDS-GOLD2" 

$DesiredIP = "192.168.21.127"
$Hostname = "ORALIVE.moorfields.nhs.uk"
$TimeOut = 10
$Action = "Add"
#$Action = "Remove"

ForEach ($server in $ServerList){
    
    if(Test-Connection -ComputerName $server -Count 1 -Quiet) {

        $path = "\\$server\C$\Windows\System32\drivers\etc\hosts"
        $remoteEtcDirectory = Split-Path $path

        $canGetHostsFileResult = $path | Start-Job { Get-Item } | Wait-Job -Timeout $TimeOut
        If ($canGetHostsFileResult) {
            
            Copy-Item $path -Destination $remoteEtcDirectory\hosts.bak # Make a backup of the remote hosts file
            
            $hostsFile = Get-Content $path
            #Write-Host "About to add $desiredIP for $Hostname to hosts file" -ForegroundColor Gray
            
            $escapedHostname = [Regex]::Escape($Hostname)
            $patternToMatch = If ($CheckHostnameOnly) { ".*\s+$escapedHostname.*" } Else { ".*$DesiredIP\s+$escapedHostname.*" }
            If (($hostsFile) -match $patternToMatch)  {
                
                if ($action -eq "Remove") {
                    # Remove
                    $hostsFile -notmatch ".*$DesiredIP\s+$escapedHostname.*" | Out-File $path
                    Write-Host "$server - Removing from hosts file" + $desiredIP.PadRight(20," ") $Hostname -ForegroundColor DarkYellow

                } else {
                    # Host and IP matches
                    Write-Host "$server - not adding; already in hosts file" + $desiredIP.PadRight(20," ") $Hostname -ForegroundColor DarkYellow
                }
            } 
            Else {
                if ($action -eq "Add") {
                    # Host and IP does not match
                    Write-Host "$server - adding to hosts file... " + $desiredIP.PadRight(20," ")  $Hostname -ForegroundColor Yellow -NoNewline
                    $hostsFile +=  ("$DesiredIP".PadRight(20, " ") + "$Hostname")
                    $hostsFile | Out-File $path
                    Write-Host " done"
                } else {
                    # Host and IP does not matchand not adding
                    Write-Host "$Server - not in host file" -ForegroundColor DarkYellow
                }           
            }
        }
    } else {
        Write-Host "$server Offline" -ForegroundColor red
    }

}

