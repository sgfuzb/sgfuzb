
$MaxRDSServer = 79
$Computernames = @()
$vmmserver = "mehscvmm19.moorfields.nhs.uk"

For ($i = 1; $i -le $MaxRDSServer; $i++) {
    If ($i -lt 10) { $servername = "MEHRDS-0" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }
    $ComputerNames += $servername
}

#$ComputerNames = "MEHRDS-GOLD2"

ForEach ($RDSServer in $Computernames) {

    $VM = Get-SCVirtualMachine -VMMServer $vmmserver -Name $RDSServer
    $VirtualDiskDrive = $VM.VirtualDiskDrives[0]
    $DrivesizeGB = (Get-SCVirtualHardDisk -VM $RDSServer).MaximumSize / 1gb

    # Expand if less than 130 GB
    If ($DrivesizeGB -lt 130) {
        Write-Host "$RDSServer Expanding to 130GB"
        Expand-SCVirtualDiskDrive -VirtualDiskDrive $VirtualDiskDrive -VirtualHardDiskSizeGB 130 
        Invoke-Command -ComputerName $RDSServer -ScriptBlock { Resize-Partition -DriveLetter c -Size (Get-PartitionSupportedSize -DriveLetter c).sizeMax}
    } else {
        Write-Host "$RDSServer Already 130GB"
    }
}
