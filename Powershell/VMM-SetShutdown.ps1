#  https://www.altaro.com/hyper-v/hyper-v-core-scheduler/

# VMM PS import
#C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoExit -Command " if ((Get-ExecutionPolicy) -eq 'Restricted'){Set-ExecutionPolicy RemoteSigned -Scope Process -Force }; ipmo 'virtualmachinemanager\virtualmachinemanager.psd1'" 
#Import-Module -Name "virtualmachinemanager"

Function Enable-Shutdown
{
    PARAM (
        [PARAMETER(Mandatory=$True,Position=0,HelpMessage ="VM Name")][String]$VMname,
        [PARAMETER(Mandatory=$True,Position=1,HelpMessage ="VM Host name")][String]$VMHostname
        )

        $VM = Get-SCVirtualMachine -Name $VMName
        # Shut down VM
        
        Stop-SCVirtualMachine -VM $VM | Out-Null
        
        # wait to stop
        if (!$WhatIfPreference) {
            While (Test-Connection -ComputerName $VMName -Count 1 -Quiet) { 
                Write-Host "Waiting for $VMName to stop"
                Start-Sleep 1 
            }                
        } 

        # Set Shutdown Action
        Set-SCVirtualMachine -VM $VM -StopAction ShutdownGuestOS | Out-Null

        # Start VM
        Start-SCVirtualMachine -VM $VM | Out-Null
}

# Get VM, Hostname, tier
$AllServers = Get-SCVMMServer -computername "mehscvmm19" | Get-SCVirtualMachine
$Servers = $AllServers | Select-Object name, VMHost,Version,StopAction, @{Name="Tier";Expression={$_.CustomProperty.Tier}}, @{Name="VMHostOS";Expression={$_.VMHost.OperatingSystem.Name}} 
#$Servers = $Servers | Where-Object VMHostOS -match "2019"
$Servers = $Servers | Where-Object StopAction -eq "SaveVM"

$Servers = $Servers | Where-Object Name -ne "LoadMaster VLM01"

# $Servers = $Servers | Where-Object Name -like "MEHOPTOS-CALI*"
# $Servers = $Servers | Where-Object Tier -eq 2
# $Servers = $Servers | Where-Object Name -eq "MEHWEB-02"
$Servers = $Servers | Where-Object VMHost -match "mehvms3"

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

    Write-Host "Changing StopAction to ShutdownGuestOS on $VMName hosted on $VMHostname"

    Enable-Shutdown -VMName $VMname -VMHostname $VMHostname

}