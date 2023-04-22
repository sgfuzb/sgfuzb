# REMOVE ALL CANON DRIVERS
# To be run in an elevated PowerShell session. Ensure ExecutionPolicy = Unrestricted

# 1. Set up for output to Windows Event logs
$log = "Application"
$source = "PowerShell Script"
if ([System.Diagnostics.EventLog]::SourceExists($source) -eq $false) 
    {
        [System.Diagnostics.EventLog]::CreateEventSource($source, $log)
     }

# 2. Check registry to build list of all Canon drivers (note the registry is hard-coded for 64-bit machines)
$Error.Clear()
cd \
cd HKLM:
cd "SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Drivers\Version-3"
$PrntList = dir | where {$_.Name -match "Canon"}
$PrntList = $PrntList -Replace "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Print\\Environments\\Windows x64\\Drivers\\Version-3\\", ""
cd \
cd c:

# 3. Stop Print Spooler service, rename implicated print processors, start Print Spooler
Stop-Service -Name "Spooler" -Force
Rename-Item "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Print Processors\winprint" -NewName winprintOLD
Rename-Item "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Print Processors\ApjPrint" -NewName ApjPrintOLD
Start-Service -Name "Spooler"
 
Start-Sleep -s 3

# 4. Run PrintUI to remove each Canon driver found
Foreach($Prnt in $PrntList)
    {
    Write-Host $Prnt . "`n"
    $Command = 'rundll32 printui.dll,PrintUIEntry /dd /m "' + $Prnt + '"'
    Invoke-Expression $Command
    Start-Sleep -s 3
    }

# 5. Stop Print Spooler service, rename implicated print processors back to original names
Stop-Service -Name "Spooler" -Force
Rename-Item "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Print Processors\ApjPrintOLD" -NewName ApjPrint
Rename-Item "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Print Processors\winprintOLD" -NewName winprint

# 6. Delete Canon driver files
Remove-Item C:\Windows\System32\spool\drivers\x64\3\AUSSDRV*
Remove-Item C:\Windows\System32\spool\drivers\x64\3\CAN*
Remove-Item C:\Windows\System32\spool\drivers\x64\3\CN*
Remove-Item C:\Windows\System32\spool\drivers\x64\3\CPC*
Remove-Item C:\Windows\System32\spool\drivers\x64\3\UCS32P*

# 7. Start Print Spooler service back up
Start-Service -Name "Spooler"
 
Start-Sleep -s 3

# 8. Write to Windows logs
If ($Error -ne "")
    {
        $Message = "Removing printer drivers for printers: `n" + $PrntList + "`n generate an error " + $Error
        write-eventlog -logname $log -source $source -eventID 201 -entrytype Warning -message $Message -category 1 -rawdata 10,20
    }
Else
    {
        $Message = "Removing printer drivers for printers: `n" + $PrntList + "`n was successful"
        write-eventlog -logname $log -source $source -eventID 101 -entrytype Information -message $Message -category 1 -rawdata 10,20
    } 

