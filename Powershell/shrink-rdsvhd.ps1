
$Driveletter = "E"
#$Filename = ".\MEHRDS-GOLD_disk_1.vhdx"
$Filename = ".\MEHRDS-GOLD_disk_1_dyn.vhdx"

# Mount
Mount-vhd $Filename
Get-PartitionSupportedSize -DriveLetter $Driveletter

# Defrag and Resize down a few times to get to 75
For ($i = 85gb; $i -gt 75gb ; $i=$i-1gb) {
    Optimize-Volume -DriveLetter $Driveletter -Verbose
    Resize-partition -DriveLetter $Driveletter -size $i
}

# Unmount and shrink file
Dismount-VHD $Filename

# Shrink
Resize-VHD -path $Filename -ToMinimumSize
Optimize-VHD -Path $Filename
Resize-VHD -path $Filename -SizeBytes 100gb

# Resize partition back
mount-vhd $Filename
Resize-partition -DriveLetter $Driveletter -size 99gb
Dismount-VHD $Filename

# Done!