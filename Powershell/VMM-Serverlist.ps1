$Servers = Get-SCVMMServer -computername "mehscvmm19" | Get-SCVirtualMachine

# Subset
$Servers | select name, memoryassignedmb, dynamicmemorydemandmb, memoryavailablepercentage | Out-GridView

$Servers | select name, VMHost, Description  | Out-GridView

# All info
$Servers | Out-GridView