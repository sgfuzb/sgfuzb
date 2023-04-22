# Originally from 
# http://blogs.technet.com/b/networking/archive/2013/09/10/vmq-deep-dive-1-of-3.aspx
# and
# https://www.tomvanbrienen.nl/virtual-machine-queue-vmq-configuration-hyper-v-2012r2-2016/
# https://techcommunity.microsoft.com/t5/networking-blog/synthetic-accelerations-in-a-nutshell-windows-server-2019/ba-p/653976 

# Reset back to default;
# Reset-NetAdapterAdvancedProperty -DisplayName *


$Teams = Get-NetLbfoTeam
$proc = Get-WmiObject -Class win32_processor
$procs = ($proc).Count
$cores = $proc| Measure-Object -Property NumberOfCores -Sum|Select-Object -ExpandProperty sum
$LPs = $proc| Measure-Object -Property NumberOfLogicalProcessors -Sum|Select-Object -ExpandProperty sum
$HT = if($cores -eq $LPs){$false}else{$true}

function SetVMQsettings ($NIC, $base, $max, $maxnum){
    $nic|Set-NetAdapterVmq -BaseProcessorNumber $base -MaxProcessors $max -MaxProcessorNumber $maxnum
    Write-Host "$($nic.name):: Proc:$base, MaxProc:$max, MaxProcNum:$maxnum"
}

foreach ($team in $teams){
    $VmqAdapters = Get-NetAdapterVmq -name ($team.members)
    #Create settings
    $VMQindex = 0
    Foreach($VmqAdapter in $VmqAdapters){
        $VmqAdapterVMQs =$VmqAdapter.NumberOfReceiveQueues

        if($HT){
            if ($VMQindex -eq 0){ # first team nic
                $base = 2
                $maxproc = $cores/2
                $maxprocnum = $LPs/2
                SetVMQsettings -nic $VmqAdapter -base $base -max $maxproc -maxnum $maxprocnum
            }
            if ($VMQindex -eq 1){ # second team nic
                $base = ($LPs/2) + 2
                $maxproc = ($cores/2)
                $maxprocnum = $LPs
                SetVMQsettings -nic $VmqAdapter -base $base -max $maxproc -maxnum $maxprocnum
            }
        }

        $VMQindex++
    }
}

Get-NetAdapterVmq


<#

Proc 0	0	1		
	1		HT	
	2	2		Base
	3		HT	
	4	3		X
	5		HT	
	6	4		X
	7		HT	
	8	5		X
	9		HT	
	10	6		X
	11		HT	
	12	7		X
	13		HT	
	14	8		X
	15		HT	
Proc 1	16	1		
	17		HT	
	18	2		Base
	19		HT	
	20	3		X
	21		HT	
	22	4		X
	23		HT	
	24	5		X
	25		HT	
	26	6		X
	27		HT	
	28	7		X
	29		HT	
	30	8		X
	31		HT	


    Embedded FlexibleLOM 1 Port 1:: Proc:2, MaxProc:8, MaxProcNum:16
Embedded FlexibleLOM 1 Port 2:: Proc:18, MaxProc:8, MaxProcNum:32

Name                           InterfaceDescription              Enabled BaseVmqProcessor MaxProcessors NumberOfReceiveQ
                                                                                                        ueues           
----                           --------------------              ------- ---------------- ------------- ----------------
MEH-Backend                    Microsoft Network Adapter Mult... True    0:0                            379             
Embedded LOM 1 Port 3          HPE Ethernet 1Gb 4-port 331i...#2 False   0:0              16                            
Embedded LOM 1 Port 2          HPE Ethernet 1Gb 4-port 331i...#3 False   0:0              16                            
Embedded LOM 1 Port 4          HPE Ethernet 1Gb 4-port 331i...#4 False   0:0              16                            
Embedded FlexibleLOM 1 Port 1  HPE Ethernet 10Gb 2-port 562FL... True    0:2              8             189             
Embedded LOM 1 Port 1          HPE Ethernet 1Gb 4-port 331i A... False   0:0              16                            
Embedded FlexibleLOM 1 Port 2  HPE Ethernet 10Gb 562SFP+ Adapter True    0:18             8             190  

#>