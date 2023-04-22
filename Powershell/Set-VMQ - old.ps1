$Teams = Get-NetLbfoTeam
$proc = Get-WmiObject -Class win32_processor
$cores = $proc| Measure-Object -Property NumberOfCores -Sum|Select-Object -ExpandProperty sum
$LPs = $proc| Measure-Object -Property NumberOfLogicalProcessors -Sum|Select-Object -ExpandProperty sum
$HT = if($cores -eq $LPs){$false}else{$true}
function SetVMQsettings ($NIC, $base,$max){
    #$nic|Set-NetAdapterVmq -BaseProcessorNumber $base -MaxProcessors $max
    Write-Host "$($nic.name):: Proc:$base, Max:$max"
}
#$LPs = 4 #testing var
#$ht = $false #testing var
foreach ($team in $teams){
    $VmqAdapters = Get-NetAdapterVmq -name ($team.members)
    #Create settings
    $VMQindex = 0
    Foreach($VmqAdapter in $VmqAdapterS){
        $VmqAdapterVMQs =$VmqAdapter.NumberOfReceiveQueues
        #$VmqAdapterVMQs = 2 #testing var
        if ($VMQindex -eq 0){#first team nic
            #base proc 1+HT and max eq to num remaining cores, num queues, whatever is less
            $base = 1+[int]$ht
            $max = ($LPs/(1+$HT)-1), $VmqAdapterVMQs|Sort-Object|Select-Object -Index 0
            SetVMQsettings -nic $VmqAdapter -base $base -max $max
           }
        else{#all other nics excluding first team nic
            if ($VmqAdapterVMQs -gt ($LPs/(1+$HT))){ #queues exceeds core count, so just start at base+1
                $base = 1+[int]$ht
                $max = ($LPs/(1+$HT)-1), $VmqAdapterVMQs|Sort-Object|Select-Object -Index 0
                SetVMQsettings -nic $VmqAdapter -base $base -max $max
            }
            else{ #cores greater than Queues so ballancing is possible
                $StepSize = [int]((($LPs/(1+$HT))-$VmqAdapterVMQs-1)/($VmqAdapters.count-1))*$VMQindex+1
                $base = $StepSize * (1+$HT)
                $max = ($LPs/(1+$HT)-1), $VmqAdapterVMQs|Sort-Object|Select-Object -Index 0
                SetVMQsettings -nic $VmqAdapter -base $base -max $max
            }
        }
        $VMQindex++
    }
}

