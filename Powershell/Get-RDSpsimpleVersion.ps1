
$MaxRDSServer = 72
$Computernames = @()

For ($i = 1; $i -le $MaxRDSServer; $i++) {
    If ($i -lt 10) { $servername = "MEHRDS-0" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }
    $ComputerNames += $servername
}

$ComputerNames += "MEHRDS-GOLD2"

#$computernames = "MEHRDS-54"

ForEach ($computer in $computernames){

    $DLL = "\\$computer\c$\silverlink\pcsv38\simple\psimple.dll"

    if (!(Test-Path $DLL)) {
        throw "File '{0}' does not exist" -f $DLL
    }
     
    try {
        $version =
            Get-ChildItem $DLL | Select-Object -ExpandProperty VersionInfo |
                Select-Object FileVersion | Select-Object -ExpandProperty FileVersion
     
        if ($version -ne "3.6.2.1490") {
            Write-host $computer - $version
        }
        
    } catch {
        throw "Failed to get DLL file version: {0}." -f $_
    }

}