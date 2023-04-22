# Shut down VMs on cluster host
# Remember to do linux ones manually

$VMMServerName = "MEHSCVMM19"
$HostName = "mehvmc5.moorfields.nhs.uk"
$VMs = Get-SCVirtualMachine -VMMServer $VMMServerName | Where-Object HostName -eq $HostName | Select-Object Name

Stop-Computer -ComputerName $VMs.name -verbose -force #-whatif

<#
$job = Start-Job -ScriptBlock {
    Stop-Computer -ComputerName $VMs.name -verbose -force
}
Receive-Job $job -Wait
#>

<#
ForEach ($VM in $VMs) {
    If(Test-Connection -Verbose -ComputerName $VM.Name -ErrorAction SilentlyContinue){
        Write-Host "Restarting: " $VM.Name
        Stop-Computer -ComputerName $VM.Name -verbose -Force
    }
}
#>

<#
Restart-Async($VMs,5)

Workflow Restart-Async {
    param (
        [object[]]$ArrayOfVms,
        [int]$Threads
      )
    ForEach -parallel -Throttlelimit $Threads ($VM in $ArrayOfVms) {
        If(Test-Connection -Verbose -ComputerName $VM.Name -ErrorAction SilentlyContinue){
            Write-Host "Restarting: " $VM.Name
            Stop-Computer -ComputerName $VM.Name -verbose -Force
        }
    }
}

$j = Stop-Computer -ComputerName $VMs.name -verbose -force &
$results = $j | Receive-Job
$results

#>