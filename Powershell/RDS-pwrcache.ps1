Set-StrictMode -Version latest
$priorityhash = @{-2="Idle";-1="BelowNormal";0="Normal";1="AboveNormal";2="High";3="RealTime"} 
$cultureENGB = New-Object System.Globalization.CultureInfo("en-GB")

$MaxRDSServer = 72

For ($i = 1; $i -lt $MaxRDSServer; $i++) {

    If ($i -lt 10) { $servername = "MEHRDS-0" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }

    #$servername = "MEHRDS-67"

    #Get-Counter -ComputerName $servername '\Processor(*)\% Processor Time' -Continuous -SampleInterval 5
    #Get-WmiObject Win32_PerfFormattedData_PerfProc_Process -filter "Name = 'pwrcache'" -Computer $servername | Where-Object { $_.PercentProcessorTime -gt 30 } | Select-Object Name, PercentProcessorTime

    #$Processes = Get-Counter -ComputerName $servername -Counter "\Process(*)\% Processor Time"
    #$Processes.CounterSamples | Where-Object InstanceName -eq "pwrcache" 

    # get specific pwrcache.exe not all named powercache ?? by id or path?

    $processes = get-process -Computer $servername | Where-Object ProcessName -eq "pwrcache"
    $cores = 0
    foreach ($proc in (Get-WmiObject -Computer $servername Win32_Processor)){
        if($null -eq $proc.numberofcores){ $cores++ }else{ $cores = $cores + $proc.numberofcores }
    } 
    foreach($process in $processes){
        $processName = $process.ProcessName
        if ($processName -notmatch "^Idle" ) {
            $cpuusage = -1
            $cpuusage = [Math]::round(((((Get-Counter -ComputerName $servername "\Process($processName)\% Processor Time" -MaxSamples 2).Countersamples)[0].CookedValue)/$cores),2)
            Write-Host "$servername : $processName : CPU: $cpuusage"
            if ($cpuusage -gt 10) {
                Write-Host "$servername : Killing : $processName"
                #Stop-Process  -Name $processName -PassThru -ErrorAction Continue
                #(Get-WmiObject Win32_Process -ComputerName $servername | ?{ $_.ProcessName -match $processName }).Terminate()

                #TASKKILL /s $servername /f /IM $processName
               # TASKKILL /s $servername /f /PID $process.ID

                <#
                [int]$AffinityMask = [math]::pow(2,$cores) -1
                
                write-host $process.ID $process.ProcessName (get-date).ToString($cultureENGB)
                write-host "was: " $process.priorityclass , $process.ProcessorAffinity
                ($process).priorityclass = $priorityhash[-2]
                ($process).ProcessorAffinity = $AffinityMask
                write-host "now: " ($process).priorityclass , $process.ProcessorAffinity
                #>
            }
        }
    }
}
