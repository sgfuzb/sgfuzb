$job = Invoke-Command -cn $computers { Get-TSSession -ComputerName "MEHRDS-10" -State Disconnected -UserName "" } -AsJob
Wait-Job $job -Timeout 60


$Timeout = 10 ## seconds
$jobs = Get-Job
$Condition = {param($jobs) 'Running' -notcontains $jobs.State }
$ConditionArgs = $jobs
$RetryInterval = 5 ## seconds
## Start the timer
$timer = [Diagnostics.Stopwatch]::StartNew()
## Start checking the condition scriptblock. Do this as long as the action hasn't exceeded
## the timeout or the condition scriptblock returns something other than $false or $null.
while (($timer.Elapsed.TotalSeconds -lt $Timeout) -and (& $Condition $ConditionArgs)) {
 
    ## Wait a specific interval
    Start-Sleep -Seconds $RetryInterval
 
    ## Check the time
    $totalSecs = [math]::Round($timer.Elapsed.TotalSeconds,0)
    Write-Verbose -Message "Still waiting for action to complete after [$totalSecs] seconds..."
}
## The action either completed or timed out. Stop the timer.
$timer.Stop()
## Return status of what happened
if ($timer.Elapsed.TotalSeconds -gt $Timeout) {
    throw 'Action did not complete before timeout period.'
} else {
    Write-Verbose -Message 'Action completed before the timeout period.'
}