
# Backup for 8 hours starting at 9pm
# Remainder of the day after an 8 hour backup window starting at 9pm


$startTime = "9:00pm"
$duration = 8
$mpg = Get-DPMProtectionGroup

Set-DPMConsistencyCheckWindow -ProtectionGroup $mpg -StartTime $startTime -DurationInHours $duration
Set-DPMBackupWindow -ProtectionGroup $mpg -StartTime $startTime -DurationInHours $duration

# Disable default schedule
Set-DedupSchedule * -Enabled:$false

$dedupDuration = 16
$dedupStart = "6:00am"
#On weekends GC and scrubbing start one hour earlier than optimization job.
# Once GC/scrubbing jobs complete, the remaining time is used for weekend
# optimization.
$shortenedDuration = $dedupDuration - 1
$dedupShortenedStart = "7:00am"
#if the previous command disabled priority optimization schedule
#reenable it
if ($null -ne (Get-DedupSchedule -name PriorityOptimization -ErrorAction SilentlyContinue))
{
    Set-DedupSchedule -Name PriorityOptimization -Enabled:$true
}
#set weekday and weekend optimization schedules
New-DedupSchedule -Name DailyOptimization -Type Optimization -DurationHours $dedupDuration -Memory 50 -Priority Normal -InputOutputThrottleLevel None -Start $dedupStart -Days Monday,Tuesday,Wednesday,Thursday,Friday
New-DedupSchedule -Name WeekendOptimization -Type Optimization -DurationHours $shortenedDuration -Memory 50 -Priority Normal -InputOutputThrottleLevel None -Start $dedupShortenedStart -Days Saturday,Sunday
#re-enable and modify scrubbing and garbage collection schedules
Set-DedupSchedule -Name WeeklyScrubbing -Enabled:$true -Memory 50 -DurationHours $dedupDuration -Priority Normal -InputOutputThrottleLevel None -Start $dedupStart -StopWhenSystemBusy:$false -Days Sunday
Set-DedupSchedule -Name WeeklyGarbageCollection -Enabled:$true -Memory 50 -DurationHours $dedupDuration -Priority Normal -InputOutputThrottleLevel None -Start $dedupStart -StopWhenSystemBusy:$false -Days Saturday
#disable background optimization
if ($null -ne (Get-DedupSchedule -name BackgroundOptimization -ErrorAction SilentlyContinue))
{
    Set-DedupSchedule -Name BackgroundOptimization -Enabled:$false
}


# Monitor using
Get-DedupStatus
Get-DedupVolume