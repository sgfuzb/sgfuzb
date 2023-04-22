
$ComputerNames =@()
$MaxVMServer = 15

Get-SCVMMServer -ComputerName MEHSCVMM19

For ($i = 7; $i -le $MaxVMServer; $i++) {
    If ($i -lt 10) { $servername = "MEHVM-0" + $i.ToString() } else { $servername = "MEHVM-" + $i.ToString() }
    $ComputerNames += $servername
}

Foreach ($server in $ComputerNames) {

    $VMs = Get-SCVirtualMachine -VMHost $server

    foreach ($vm in $vms) {
  
        $VirtDiskDrive = Get-SCVirtualDiskDrive -VM $VM | Where-Object {$_.Bus -Eq 0 -And $_.Lun -Eq 0}
        
        Expand-SCVirtualDiskDrive -VirtualDiskDrive $VirtDiskDrive -VirtualHardDiskSizeGB 120

    }
}
