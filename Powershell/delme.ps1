
#$directory = "M:\temp\JUT\"
#$resultFile = "M:\Temp\JUT-All.log"
#Get-ChildItem -Path $directory -Include *.log -Recurse | Get-Content | Out-File -FilePath $resultFile -NoClobber


$Counters = (Get-Counter -ListSet Processor).PathsWithInstances | ? {$_ -match "% Processor Time"}
$CoreUsage = Get-Counter $Counters -SampleInterval 10 -MaxSamples 5 | `
Select-Object -ExpandProperty CounterSamples | Select-Object InstanceName, CookedValue | `
Group-Object -Property InstanceName | ForEach-Object {
    $Stats = $_.Group | Measure-Object -Property CookedValue -Average -Maximum
    $_ | Select-Object `
            Name, `
            @{L="Average"; E={[math]::round(($Stats).Average,2)}}, `
            @{L="Maximum"; E={[math]::round(($Stats).Maximum,2)}}
}

Write-Host (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.ms")
$CoreUsage
