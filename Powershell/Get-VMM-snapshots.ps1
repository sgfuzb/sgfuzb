$daysold = 120
$whatifpreference = 0

$Checkpoints = Get-SCVMMServer -computername mehscvmm | Get-SCVirtualMachine | Get-SCVMCheckpoint 

$oldCheckpoints = $checkpoints | Where-Object {$_.Addedtime -lt (Get-Date).AddDays(-$daysold) } 
$currentCheckpoints = $checkpoints | Where-Object {$_.Addedtime -gt (Get-Date).AddDays(-$daysold) } 

$oldCheckpoints  | Remove-SCVMCheckpoint #runs jobs in vmm, can see logs there

$currentcheckpointslist = $currentCheckpoints | Select-Object VM,Addedtime,description | Out-String
$oldcheckpointslist = $oldCheckpoints | Select-Object VM,Addedtime,description | Out-String 

$Message = "===================================================`n"
$Message += "VMM Checkpoint Maintenance`n"
$Message += "===================================================`n"
$Message += "Deleted Checkpoints older than " + $daysold + " days`n"
$Message += $oldCheckpointslist
$Message += "===================================================`n"
$Message += "Remaining Checkpoints newer than " + $daysold + " days`n"
$Message += $currentcheckpointslist

# ===================================================
# Report and email
# ===================================================

$Message += "`n"
$Message += "===================================================`n"
$Message += "DONE!`n"


#Settings for Email Message
$rptDate=(Get-date)
if ($whatifpreference -eq 1) {
    $subjectprefix = "###TEST### " 
    $Message
} else {$subjectprefix = "" } 

$messageParameters = @{ 
    Subject = "[" + $subjectprefix + "VMM Checkpoint maintenance on " + $rptDate.ToString($cultureENGB) + "]"
    Body = $Message
    From = "it.alerts@moorfields.nhs.uk" 
    To = "moorfields.italerts@nhs.net" #, "andrew.peters1@nhs.net"
    SmtpServer = "smtp.moorfields.nhs.uk"
    #SmtpServer = "127.0.0.1"
} 
#Send Report Email Message
Send-MailMessage @messageParameters #-BodyAsHtml



<#

#direct without vmm - issue with 2012r2

$Hypervs = Get-ADObject -Filter 'ObjectClass -eq "serviceConnectionPoint" -and Name -eq "Microsoft Hyper-V"'
$HyperVsNames = @()
foreach($Hyperv in $Hypervs) {            
 $temp = $Hyperv.DistinguishedName.split(",")            
 $HypervDN = $temp[1..$temp.Count] -join ","            
 if ( !($HypervDN -match "CN=LostAndFound")) {
     $Comp = Get-ADComputer -Id $HypervDN -Prop *            
     if ($comp.Enabled){
        $HyperVsNames += $Comp.Name 
     }
}}

foreach ($HVServer in $HyperVsNames) {

    #Get-VMSnapshot -ComputerName $HVServer -VMName *
    #Get-SCVirtualMachine $HVServer

    if(Test-Connection -Cn $HVServer -BufferSize 16 -Count 1 -ea 0 -quiet) {
        Get-VM -ComputerName $HVServer | 
        Get-VMSnapshot | 
        Where-Object {$_.CreationTime -lt (Get-Date).AddDays(-7) } | 
        Select-Object VMName,Name,SnapshotType,CreationTime,ComputerName
    }
}
#>

# Issue connecting to Win2012 R2 hosts - these need to be upgraded

#|Get-VMSnapshot
#Get-VMSnapshot -ComputerName "MEHVMC3" -VMName "MEHQV" | Remove-VMSnapshot
#Get-SCVMMServer -computername mehscvmm | get-vm | Get-VMCheckpoint  | Remove-VMCheckpoint


