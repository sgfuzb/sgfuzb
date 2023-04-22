Get-VMMServer -ComputerName MEHSCVMM19 | out-null

$VMs = Get-SCVirtualMachine | Where-Object {($_.StartAction -eq "NeverAutoTurnOnVM") -and ($_.name -like "mehrds-*" )}

foreach ($vm in $VMs){

    Set-SCVirtualMachine -VM $VM -StartAction AlwaysAutoTurnOnVM
    Start-SCVirtualMachine -VM $VM
}