#  https://www.altaro.com/hyper-v/hyper-v-core-scheduler/

# VMM PS import
#C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoExit -Command " if ((Get-ExecutionPolicy) -eq 'Restricted'){Set-ExecutionPolicy RemoteSigned -Scope Process -Force }; ipmo 'virtualmachinemanager\virtualmachinemanager.psd1'" 
#Import-Module -Name "virtualmachinemanager"

Function Enable-VMSMT
{
    PARAM (
        [PARAMETER(Mandatory=$True,Position=0,HelpMessage ="VM Name")][String]$SMTname,
        [PARAMETER(Mandatory=$True,Position=1,HelpMessage ="VM Host name")][String]$SMTHostname
       )

        # Shut down VM
        $VM = Get-SCVirtualMachine -Name $SMTname
        Stop-SCVirtualMachine -VM $VM | Out-Null
        # Stop-VM -ComputerName $SMTHostname -Name $SMTname

        # wait to stop
        if (!$WhatIfPreference) {
            While (Test-Connection -ComputerName $SMTname -Count 1 -Quiet) { 
                Write-Host "Waiting for $SMTname to stop"
                Start-Sleep 1 
            }
                
            # Upgrade config version to 9.0
            Update-VMVersion -ComputerName $SMTHostname -Name $SMTname -Force
        } 

        # Check if CPU set to compatibility and disable
        If (Get-VMProcessor -ComputerName $SMTHostname -VMName $SMTname | Select-Object -Property CompatibilityForMigrationEnabled){
            Set-VMProcessor -ComputerName $SMTHostname -VMName $SMTname -CompatibilityForMigrationEnabled $false
            Write-Host "Disabled CPU Compat. on $SMTname"
        }

        # Set Hwthreadcountpercore to 0 to enable SMT
        # Get-VMProcessor -ComputerName $Hostname -VMName $VMname | Select-Object -Property HwThreadCountPerCore
        Set-VMProcessor -ComputerName $SMTHostname -VMName $SMTname -HwThreadCountPerCore 0

        # Start VM
        $VM = Get-SCVirtualMachine -Name $SMTname
        Start-SCVirtualMachine -VM $VM | Out-Null
        # Start-VM -ComputerName $SMTHostname -Name $SMTname
}

# Get VM, Hostname, tier
$AllServers = Get-SCVMMServer -computername "mehscvmm19" | Get-SCVirtualMachine
$Servers = $AllServers | Select-Object name, VMHost,Version, @{Name="Tier";Expression={$_.CustomProperty.Tier}}, @{Name="VMHostOS";Expression={$_.VMHost.OperatingSystem.Name}} 
$Servers = $Servers | Where-Object VMHostOS -match "2019"
$Servers = $Servers | Where-Object Version -ne "9.0"

$Servers = $Servers | Where-Object Name -notlike "MO-*"
# $Servers = $Servers | Where-Object Name -like "MEHOPTOS-CALI*"
# $Servers = $Servers | Where-Object Tier -eq 1
# $Servers = $Servers | Where-Object Name -eq "MEHEHR"
# $Servers = $Servers | Where-Object VMHost -match "mehvms4"

# Confirm selection
$Servers | Out-String | Write-Host
Write-Host 'Press any key to continue...'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

# Debug
$WhatIfPreference = $false

ForEach ($server in $Servers){
    $VMname = $server.Name
    $VMHostname = $server.VMHost.Name
    $VMHostOS = $server.VMHostOS

    # If host 2019 and not already set
    If ($VMHostOS -match "2019") {
        $VMSMT = Get-VMProcessor -ComputerName $VMHostname -VMName $VMname | Select-Object -Property HwThreadCountPerCore
        If ($VMSMT.HwThreadCountPerCore -eq 1) {
            Write-Host "Enabling SMT on $VMName hosted on $VMHostname"
            Enable-VMSMT -SMTname $VMname -SMTHostname $VMHostname
        } else {
            Write-Host "SMT already enabled on $VMName hosted on $VMHostname"
        }
    }
}