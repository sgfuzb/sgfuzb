########################################################
#
# Change print driver on all matching printers
# Steven Gill 10/10/19
#
########################################################

$OldDriverName = "Canon Generic PCL6 Driver"
#$NewDriverName = "Canon Generic Plus PCL6"
$NewDriverName = "Canon Generic Plus PCL6"
$IncludeName = "*"
$ExcludeName = "\\*" # don't change on remote print servers!

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
    $isOnline = Test-Connection -Cn $IP -BufferSize 16 -Count 1 -ea 0 -quiet
    $i = $filterPrinters.IndexOf($printer) +1

    if ($name -notlike $ExcludeName){
        if ($isOnline){
            try{
                # & rundll32 printui.dll PrintUIEntry /Xs /n $name DriverName $NewDriverName
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
