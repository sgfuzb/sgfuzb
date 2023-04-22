$priorityhash = @{-2="Idle";-1="BelowNormal";0="Normal";1="AboveNormal";2="High";3="RealTime"} 
$cultureENGB = New-Object System.Globalization.CultureInfo("en-GB")


    $processes = Get-Process -Name *octdataparser*
    foreach ($process in $processes) {
        write-host $process.ID $process.ProcessName (get-date).ToString($cultureENGB)
        write-host "was: " $process.priorityclass
        ($process).priorityclass = $priorityhash[-2]
        write-host "now: " ($process).priorityclass
    }
