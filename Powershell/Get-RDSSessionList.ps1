<#
RDS Session lists
Requires PSTerminialServer.msi Powershell/Cassia extension (install in %ProgramFiles%\WindowsPowerShell\Modules)
#>

$TSSessionsAll =@()
$ComputerNames = @()
$LoginOKSessions = @()
$LoginBADSessions = @()

$MaxRDSServer = 79
For ($i = 1; $i -le $MaxRDSServer; $i++) {
    If ($i -lt 10) { $servername = "MEHRDS-0" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }
    $ComputerNames += $servername
}

#$ComputerNames = "MEHRDS-73"

ForEach ($Computer in $ComputerNames) {

    if (Test-Connection -Quiet -Count 1 -ComputerName $Computer){

        Write-Host "$computer - Checking"

        $TSSessionThis = Get-TSSession -ComputerName $Computer | Where-Object UserName -NE ""
        $TSProcessesThis = Get-TSProcess -ComputerName $Computer

        $TSSessionsAll += $TSSessionThis

        # Users that have logged in OK have explorer.exe
        $LoginOKSessionIDs = $TSProcessesThis | Where-Object {$_.ProcessName -eq "explorer.exe"} 
        $LoginOKSessions += $TSSessionThis | Where-Object SessionId -in $LoginOKSessionIDs.SessionId
        $LoginBADSessions += $TSSessionThis | Where-Object SessionId -NotIn $LoginOKSessionIDs.SessionId
    } else {
        Write-Host "$computer - is off"
    }
}

Write-Host "Total Sessions:" $TSSessions.Count

#Write-Host "Happy Sessions:" 
#$LoginOKSessions 
#Write-Host "Unhappy Sessions:" 
#$LoginBADSessions | Select-Object @{Name='ServerName'; Expression={$_.Server.ServerName}},SessionId,ConnectionState,ClientName,UserName,LoginTime,LastInputTime | Out-GridView

#$TSSessionsAll | Out-GridView

# break

$disconnected = $TSSessionsAll | Where-Object {$_.state -eq "Disconnected"} 

$disconnected.Count

foreach ($session in $disconnected ) {
    $session
    try {
        Stop-TSSession -ComputerName $session.Server.ServerName -Id $session.SessionId -Force    
    }
    catch {
        Write-Host "error"
    }   
}
