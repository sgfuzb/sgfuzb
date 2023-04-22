$rdptemplate = @"
authentication level:i:0
connection type:i:2
desktopheight:i:768
desktopwidth:i:1024
redirectclipboard:i:1
enablecredsspsupport:i:0
negotiate security layer:i:1
prompt for credentials:i:0
promptcredentialonce:i:0
screen mode id:i:1
"@

$MaxRDSServer = 72
$Computernames = @()

For ($i = 1; $i -le $MaxRDSServer; $i++) {
    If ($i -lt 10) { $servername = "MEHRDS-0" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }
    $ComputerNames += $servername
}

$MaxUser = 3
$usernames = @()
For ($i = 1; $i -le $MaxUser; $i++) {
    If ($i -lt 10) { $username = "city_road\vsi0" + $i.ToString() } else { $username = "city_road\vsi" + $i.ToString() }
    $usernames += $username
}

# Override for testing
$ComputerNames = "rds.moorfields.nhs.uk"

$rdpFileName = "M:\powershell\rdptest\RDPFile.rdp"
#$username = "city_road\vsi01"
$password = ("MER?zVk{#36:" | ConvertTo-SecureString -AsPlainText -Force) | ConvertFrom-SecureString

$certThumb =(Get-ChildItem cert:currentuser\my\ -CodeSigningCert).Thumbprint[1]

Write-Host (Get-Date)

While ($true) {

foreach ($Computer in $ComputerNames) {

    $isconnectable = New-Object System.Net.Sockets.TCPClient -ArgumentList $Computer,3389

    if ($isconnectable) {
        foreach ($username in $usernames){

            #if (-not (Test-Path $rdpFileName)) {
                $out = @()
                $out += "full address:s:" + $Computer
                $out += "username:s:" + $username
                $out += "password 51:b:" + $password
                $out += $rdptemplate
                $out | out-file $rdpFileName -Force
            #}

            #Invoke-Command {rdpsign /sha256 01b5d534757b4061de5efe671b3cd99231b94579 $rdpFileName | Out-Null}  
            Invoke-Command {rdpsign /sha256 $certThumb $rdpFileName | Out-Null} 
            
            # Start in new thread and carry on
            $secs = (measure-command { Start-Process mstsc $rdpFileName -WindowStyle Minimized | Out-Null }).Seconds
            # Start and wait till closed
            #$secs = (measure-command {mstsc $rdpFileName | Out-Null }).Seconds

            Write-Host Server:$Computer User: $username TimeTaken: $secs
            
            # Delay between invocations
            Start-Sleep -Seconds 35
        }
    } else { 
        Write-Host Server:$Computer Cant connect to 3389
    }

}

}

<#

$hash = @{i=1}
$sync = [System.Collections.Hashtable]::Synchronized($hash)

Workflow Test-RDS {
    param (
        [Object[]] $computers
    )

    ForEach -ThrottleLimit 2 -Parallel ($Computer in $computers) {
        $connectable = New-Object System.Net.Sockets.TCPClient -ArgumentList $Computer,3389

        $rdpFileName = "M:\powershell\rdptest\"+$Computer+".rdp"

        if (-not (Test-Path $rdpFileName)) {
            $out = @()
            $out += "full address:s:" + $Computer
            $out += $rdptemplate
            $out | out-file $rdpFileName
        }

        #$filename = "m:\powershell\rdptest\" + $Computer + ".rdp"
        $opentime = measure-command { mstsc $rdpFileName | Out-Null}

        $synccopy = $using:sync
        $process = $syncCopy.$($PSItem.Id)

        $process.Id = $PSItem.Id
        $process.Activity = "Id $($PSItem.Id) starting"
        $process.Status = "Processing"

        #Write-Host $Computer RDP:($connectable.connected) LogonscreenTime: ($opentime.Seconds -30)
    }
}

Test-RDS($ComputerNames)

#>

<#
$hash = @{i=1}
$sync = [System.Collections.Hashtable]::Synchronized($hash)

$job = $Computernames | Foreach-Object -ThrottleLimit 3 -AsJob -Parallel {

    $connectable = New-Object System.Net.Sockets.TCPClient -ArgumentList $Computer,3389

    $rdpFileName = "M:\powershell\rdptest\"+$_+".rdp"

    if (-not (Test-Path $rdpFileName)) {
        $out = @()
        $out += "full address:s:" + $_
        $out += $rdptemplate
        $out | out-file $rdpFileName
    }

    $opentime = measure-command { mstsc $rdpFileName | Out-Null}

    $synccopy = $using:sync
    $process = $syncCopy.$($PSItem.Id)

    $process.Id = $PSItem.Id
    $process.Activity = "Id $($PSItem.Id) starting"
    $process.Status = "Processing"

    $process.Activity = $Computer +"RDP:" + ($connectable.connected) + "LogonscreenTime: " + ($opentime.Seconds -30)
}

while($job.State -eq 'Running')
{
    $sync.Keys | Foreach-Object {
        # If key is not defined, ignore
        if(![string]::IsNullOrEmpty($sync.$_.keys))
        {
            # Create parameter hashtable to splat
            $param = $sync.$_

            # Execute Write-Progress
            Write-Progress @param
        }
    }

    # Wait to refresh to not overload gui
    Start-Sleep -Seconds 0.1
}

$rdptemplate = @"
allow desktop composition:i:1
allow font smoothing:i:1
alternate shell:s:
audiocapturemode:i:0
audiomode:i:0
authentication level:i:0
autoreconnection enabled:i:1
bandwidthautodetect:i:1
bitmapcachepersistenable:i:1
compression:i:1
connection type:i:2
desktopheight:i:768
desktopwidth:i:1024
disable cursor setting:i:0
disable full window drag:i:0
disable menu anims:i:0
disable themes:i:0
disable wallpaper:i:0
displayconnectionbar:i:1
drivestoredirect:s:
enablecredsspsupport:i:0
enableworkspacereconnect:i:0
gatewaybrokeringtype:i:0
gatewaycredentialssource:i:4
gatewayhostname:s:
gatewayprofileusagemethod:i:0
gatewayusagemethod:i:0
kdcproxyname:s:
keyboardhook:i:2
negotiate security layer:i:1
networkautodetect:i:1
prompt for credentials:i:0
promptcredentialonce:i:0
rdgiskdcproxy:i:0
redirectclipboard:i:1
redirectcomports:i:0
redirectdirectx:i:1
redirectposdevices:i:0
redirectprinters:i:1
redirectsmartcards:i:1
remoteapplicationmode:i:0
screen mode id:i:1
session bpp:i:32
shell working directory:s:
use multimon:i:0
use redirection server name:i:0
videoplaybackmode:i:1
winposstr:s:0,3,0,0,800,570
"@

#>

