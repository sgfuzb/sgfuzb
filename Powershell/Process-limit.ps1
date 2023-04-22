$priorityhash = @{-2="Idle";-1="BelowNormal";0="Normal";1="AboveNormal";2="High";3="RealTime"} 
$cultureENGB = New-Object System.Globalization.CultureInfo("en-GB")
$cores = 8
[int]$AffinityMask = [math]::pow(2,$cores) -1

while ($true){
    $processes = Get-Process -Name *notepad*
    foreach ($process in $processes) {
        write-host $process.ID $process.ProcessName (get-date).ToString($cultureENGB)
        write-host "was: " $process.priorityclass , $process.ProcessorAffinity
        ($process).priorityclass = $priorityhash[-2]
        ($process).ProcessorAffinity = $AffinityMask
        write-host "now: " ($process).priorityclass , $process.ProcessorAffinity
    }
    Start-Sleep -Second 10
}