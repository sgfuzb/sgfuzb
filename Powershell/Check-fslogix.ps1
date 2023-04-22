$MaxRDSServer = 72
$Computernames = @()

For ($i = 1; $i -le $MaxRDSServer; $i++) {
    If ($i -lt 10) { $servername = "MEHRDS-0" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }
    $ComputerNames += $servername
}

# $Computernames = "MEHUAT-01","MEHUAT-02"
 #$Computernames = "MEHRDS-70","MEHRDS-71","MEHRDS-72"

Write-Host "Checking VHDLocations reg key..."

$incorrect = 0

ForEach ($computer in $computernames){
    
    if(Test-Connection -ComputerName $computer -Count 1) {

        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
        $RegKey= $Reg.OpenSubKey("SOFTWARE\\FSLogix\\Profiles")
        $Procon = $RegKey.GetValue("VHDLocations")

        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
        $RegKey= $Reg.OpenSubKey("SOFTWARE\\Policies\\FSLogix\\ODFC")
        $Offcon = $RegKey.GetValue("VHDLocations")

        #$Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
        #$RegKey= $Reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Control\\Terminal Server\\ClusterSettings")
        #$SessDirCluName = $RegKey.GetValue("SessionDirectoryClusterName")

        #$isPaslink = Test-Path "\\$computer\C$\source\OraclePaslink"
        $isvfp = Test-Path "\\$computer\C$\Progrem Files (x86)\Common Files\Microsoft Shared\VFP\vfp9err.log"

        Write-Host "$computer,$isvfp"
                
        if (($Procon -eq "\\mehsofs\ProCon" ) -and ($Offcon -eq "\\MEHSOFS\OffCon")){

        } else {
            $incorrect++
            Write-Host $computer
            $Procon
            $Offcon
        }
    }
}

if ($incorrect -eq 0){
    Write-Host "All OK"
} else {
    Write-Host "$incorrect not set correctly"
}

break

$lasterrortime = (get-date -format "hh:mm:ss")

while ($true) {

    Write-Host "Checking FSlogix Profile Logs..."

    $logs = @()
    $numerrors = 0

    ForEach ($computer in $computernames)
    { 
        $BaseDirPro = "\\$computer\C$\ProgramData\FSLogix\Logs\Profile\"
        $BaseDirOff = "\\$computer\C$\ProgramData\FSLogix\Logs\ODFC\"
        $FilenamePro = "Profile-" + (get-date -format "yyyyMMdd") +".log"
        $FilenameOff = "ODFC-" + (get-date -format "yyyyMMdd") +".log"
        $lognamePro = $BaseDirPro + $FilenamePro
        $lognameOff = $BaseDirOff + $FilenameOff
        
        $pattern1 = "ERROR:","WARN:"
        #, "DBG"

        if(Test-Connection -ComputerName $computer -Count 1) {
            $thislogPro = (Get-Content -Path $lognamePro -ErrorAction SilentlyContinue | Select-String -Pattern $pattern1)
            $thislogOff = (Get-Content -Path $lognameOff -ErrorAction SilentlyContinue | Select-String -Pattern $pattern1)

            # -context 3,3

            $thisnumerrors = (($thislogPro | Measure-Object -Line).Lines) + (($thislogOff | Measure-Object -Line).Lines)
            $numerrors += $thisnumerrors
            
            #Write-Host $computer " Errors: " $thisnumerrors 
            foreach ($log in $thislogPro) {
                
                $entry = $log.ToString().Replace("[", "").split("]")

                # Extract VHDX names
                $index1 = $log.ToString().indexof('\S') + 1
                $index2 = $log.ToString().lastindexof('X ') + 1
                if (($index1 -gt 0) -and ($index2 -gt 0)) {
                    $VHDXName = $log.tostring().substring($index1, ($index2- $index1))
                }

                # Create array of custom objects
                $logs += [PSCustomObject]@{
                    Server = $computer
                    Time = $entry[0]
                    ErrorCode = $entry[2]
                    VHDXName = $VHDXName
                    Log = $entry[3]
                }
            }
            foreach ($log in $thislogOff) {
                
                $entry = $log.ToString().Replace("[", "").split("]")

                # Extract VHDX names
                $index1 = $log.ToString().indexof('\S') + 1
                $index2 = $log.ToString().lastindexof('X ') + 1
                if (($index1 -gt 0) -and ($index2 -gt 0)) {
                    $VHDXName = $log.tostring().substring($index1, ($index2- $index1))
                } else {
                    #$VHDXName = ""
                }

                # Create array of custom objects
                $logs += [PSCustomObject]@{
                    Server = $computer
                    Time = $entry[0]
                    ErrorCode = $entry[2]
                    VHDXName = $VHDXName
                    Log = $entry[3]
                }
            }

        } else {
            Write-Host $computer " not contactable"
        }
    }

    Write-Host  "Errors: " $numerrors

    #$logs | Sort-Object -Property Time -Descending | Where-Object -property "Errorcode" -EQ "ERROR:00000020" | Select-Object -first 100 | Out-GridView

    $lastlogs = $logs | Sort-Object -Property Time -Descending | Where-Object -property Time -gt $lasterrortime
    
    If ($lastlogs.count -gt 0) {
        
        $lasterrortime = $lastlogs[0].Time
        $computername = $lastlogs[0].Server

        <#
        #$computername2 = "MEHSOFS02"
        $computername2 = $computername

        Write-Host $computername2 " Checking Handles..."
        $s = New-PsSession -ComputerName $computername2
        $handles = Invoke-Command -Session $s {C:\windows\system32\handle.exe -accepteula vhdx}
        Remove-PSSession $s

        $lastlogs[0]
        $handles
        #>
        
    }
    $lasterrortime
    $lastlogs

    $logs | Sort-Object -Property Time -Descending | Out-GridView
    break

    Start-Sleep 10
}

<#

$s = New-PsSession -ComputerName "MEHSOFS"
$openfiles = Invoke-Command -Session $s {Get-SmbopenFile}
# Invoke-Command -Session $s {Get-SmbShare}
# Invoke-Command -Session $s {Get-SmbShareAccess 'ProCon'}

# $a=@(1,2,3,1,2)
# $b=$a | select –unique

# $openfiles | Out-GridView

# Loop through, compare, list client ip and vhdx of matches
foreach ($openfile in $openfiles){
    foreach ($log in $logs){
        if ($openfile.ShareRelativePath.ToString() -eq $log.VHDXName) {
            
            # $openfile | fl
            $openfile.ShareRelativePath

        }
    }
}
#>

#$openfiles.count
#$openfiles[50]
