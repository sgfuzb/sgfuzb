
$Computers = @()
$output = @()

For ($i = 1; $i -le 16; $i++) {
    If ($i -lt 10) { $servername = "MEHVM-0" + $i.ToString() } else { $servername = "MEHVM-" + $i.ToString() }
    $Computers += $servername
}

Foreach($Computer in $Computers) {

    $ServerCim = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Computer |
    Select PSComputername,
    @{Name = "TotalMemoryGB";Expression={$_.totalVisibleMemorySize/1MB -as [int]}},
    @{Name = "FreeMemoryGB";Expression={[Math]::Round($_.FreePhysicalMemory/1MB,2)}}

    $GuestCPU = (Get-Counter -ComputerName $Computer -Counter "\Hyper-V Hypervisor Logical Processor(_Total)\% Guest Run Time").CounterSamples  | Measure-Object -property cookedvalue -Average | Select Average
    $GuestCPU = [math]::Round($GuestCPU.Average,2)
    $VMs = Get-WmiObject -ComputerName $Computer -Class Msvm_ComputerSystem -Namespace "root\virtualization\v2" | ? {$_.Caption -eq "Virtual Machine" } | Where-Object {$_.elementname -like "MEHRDS*"}

    $DiskInfoE = (Get-WmiObject Win32_LogicalDisk -ComputerName $Computer -Filter "DeviceID='E:'").size /1GB
    $DiskInfoH = (Get-WmiObject Win32_LogicalDisk -ComputerName $Computer -Filter "DeviceID='H:'").size /1GB
    if ($DiskInfoE -gt 0) {$HVdiskSize = [Math]::Round($DiskInfoE,2)}
    if ($DiskInfoH -gt 0) {$HVdiskSize = [Math]::Round($DiskInfoH,2)}

    $DiskInfoE = (Get-WmiObject Win32_LogicalDisk -ComputerName $Computer -Filter "DeviceID='E:'").FreeSpace /1GB
    $DiskInfoH = (Get-WmiObject Win32_LogicalDisk -ComputerName $Computer -Filter "DeviceID='H:'").FreeSpace /1GB
    if ($DiskInfoE -gt 0) {$HVdiskFree = [Math]::Round($DiskInfoE,2)}
    if ($DiskInfoH -gt 0) {$HVdiskFree = [Math]::Round($DiskInfoH,2)}

    Write-Host Server: $Computer RTot: $ServerCim.TotalMemoryGB RFree: $ServerCim.FreeMemoryGB CPU: $GuestCPU RDS-VMs: $VMs.Count HVDisk: $HVdiskSize HVDiskFree: $HVdiskFree

    $output += [PSCustomObject]@{
        Server = $Computer
        TotalRAM = $ServerCim.TotalMemoryGB
        FreeRAM = $ServerCim.FreeMemoryGB
        GuestCPU = $GuestCPU
        TotalVMs = $VMs.Count
        HVDiskSize = $HVdiskSize
        HVDiskFree = $HVdiskFree
    }
}

$RAMSum = 0
$VMCount = 0
$HVdiskSizeSum = 0
$HVdiskFreeSum = 0

($output.TotalRAM | foreach {$RAMSum += $_})
($output.FreeRAM | foreach {$FreeRAMSum += $_})
($output.TotalVMs | foreach {$VMCount += $_})
($output.HVDiskSize | foreach {$HVdiskSizeSum += $_})
($output.HVDiskFree | foreach {$HVdiskFreeSum += $_})

Write-Host RTot: $RAMSum RFree: $FreeRAMSum RDS-VM-Tot: $VMCount HVDiskTot: $HVdiskSizeSum HVDiskFreeTot: $HVdiskFreeSum

$output | Out-GridView
