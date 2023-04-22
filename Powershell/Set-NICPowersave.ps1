
# Disable on all NICS "Turn off this device to save power"

$adapters = Get-NetAdapter -Physical | Get-NetAdapterPowerManagement
foreach ($adapter in $adapters){
    Write-Host $adapter.Caption Power Setting: $adapter.AllowComputerToTurnOffDevice
    $adapter.AllowComputerToTurnOffDevice = 'Disabled'
    $adapter | Set-NetAdapterPowerManagement #-WhatIf
}

# Set Computer as high perf power profile
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c