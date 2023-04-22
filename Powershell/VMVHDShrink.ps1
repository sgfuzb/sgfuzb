
$FixDiskPath = ".\MEHRDS-GOLD_disk_1.vhdx"
$DynDiskPath = ".\MEHRDS-GOLD_disk_1_dyn.vhdx"
$Driveletter = "D"

# Move disk file manually to server with space
Convert-VHD -Path $FixDiskPath -DestinationPath $DynDiskPath -VHDType Dynamic

# mount
mount-vhd $DynDiskPath

# resize down, minsize +20%, adjust as required may need to defrag a few times to get to target
# defrag
Optimize-Volume -DriveLetter $Driveletter -Verbose
$Minsize = (Get-PartitionSupportedSize -DriveLetter $Driveletter).SizeMin *1.2
Resize-partition -DriveLetter $Driveletter -size $Minsize
Optimize-Volume -DriveLetter $Driveletter -Verbose
Resize-partition -DriveLetter $Driveletter -size $Minsize

# unmount and shrink file
Dismount-VHD $DynDiskPath

# Shrink
Resize-VHD -path $DynDiskPath -ToMinimumSize
Optimize-VHD -Path $DynDiskPath
Resize-VHD -path $DynDiskPath -SizeBytes 100gb

# Resize back
mount-vhd $DynDiskPath
Resize-partition -DriveLetter $Driveletter -size 99gb
Dismount-VHD $DynDiskPath

