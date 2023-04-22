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

Function Test-ComputerConnection 
{
	<#	
		.SYNOPSIS
			Test-ComputerConnection sends a ping to the specified computer or IP Address specified in the ComputerName parameter.
		
		.DESCRIPTION
			Test-ComputerConnection sends a ping to the specified computer or IP Address specified in the ComputerName parameter. Leverages the System.Net object for ping
			and measures out multiple seconds faster than Test-Connection -Count 1 -Quiet.
		
		.PARAMETER ComputerName
			The name or IP Address of the computer to ping.

		.EXAMPLE
			Test-ComputerConnection -ComputerName "THATPC"
			
			Tests if THATPC is online and returns a custom object to the pipeline.
			
		.EXAMPLE
			$MachineState = Import-CSV .\computers.csv | Test-ComputerConnection -Verbose
		
			Test each computer listed under a header of ComputerName, MachineName, CN, or Device Name in computers.csv and
			and stores the results in the $MachineState variable.
			
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$True,
		ValueFromPipeline=$True, ValueFromPipelinebyPropertyName=$true)]
		[alias("CN","MachineName","Device Name")]
		[string]$ComputerName	
	)
	Begin
	{
		[int]$timeout = 20
		[switch]$resolve = $true
		[int]$TTL = 128
		[switch]$DontFragment = $false
		[int]$buffersize = 32
		$options = new-object system.net.networkinformation.pingoptions
		$options.TTL = $TTL
		$options.DontFragment = $DontFragment
		$buffer=([system.text.encoding]::ASCII).getbytes("a"*$buffersize)	
	}
	Process
	{
		$ping = new-object system.net.networkinformation.ping
		try
		{
			$reply = $ping.Send($ComputerName,$timeout,$buffer,$options)	
		}
		catch
		{
			$ErrorMessage = $_.Exception.Message
		}
		if ($reply.status -eq "Success")
		{
			$props = $True
			
		}
		else
		{
			$props = $False			
			
		}
		
$props
	}
	End{}
}

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
            #$isOnline = Test-Connection $IP -BufferSize 16 -Count 1 -quiet
            $isOnline = Test-ComputerConnection $IP
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
