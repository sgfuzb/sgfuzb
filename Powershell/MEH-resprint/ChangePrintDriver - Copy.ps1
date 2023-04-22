########################################################
#
# Change print driver on all matching printers
# Steven Gill 10/10/19
#
########################################################

# Parameters

$InDebug = $false
#$OldDriverName = "Canon Generic PCL6 Driver"
$OldDriverName = "Microsoft XPS Document Writer"
$NewDriverName = "Canon Generic Plus PCL6"
#$NewDriverName = "Microsoft XPS Document Writer"
$IncludeName = "*"
$ExcludeName = "\\*" # don't change on remote print servers!
$BypassOnlineCheck = $false
$logfile = "c:\meh\ChangePrintDriver" + (get-date -Format "yyMMddhhmmss") + ".log"

########################################################

Start-Transcript -Path $Logfile

Write-Host "Server: "$env:COMPUTERNAME
Write-Host "Changing drivers on printers with: "
Write-Host "This driver: " $OldDriverName
Write-Host "To this driver: " $NewDriverName
Write-Host "Collecting printer info..."

$printers = gwmi win32_printer
$filterPrinters = @($printers|Where{$_.name -like $IncludeName -and $_.DriverName -like $OldDriverName})
$NumPrinters = $filterPrinters.count

Write-Host "Checking" $numprinters "Printers..."
foreach($printer in $filterPrinters){
    $name = $printer.name
    $IP = $printer.PortName
    if ($BypassOnlineCheck){
            $isOnline = $true 
        } else {
            $isOnline = Test-Connection $IP -BufferSize 16 -Count 1 -quiet
        }
    $i = $filterPrinters.IndexOf($printer) +1

    if ($name -notlike $ExcludeName){
        if ($isOnline){
            try{
            if (-not $InDebug){
                & rundll32 printui.dll PrintUIEntry /Xs /n $name DriverName $NewDriverName
            }
                Write-Host $i ": Changed Driver           : " $name
            } catch { 
                Write-Host $i ": ERROR changing driver on : " $name
            }
        } else {
                Write-Host $i ": Offline                  : " $name , $IP
        }
    } else {
                Write-Host $i ": Excluded                 : " $name
    }
}

Stop-Transcript