
$ComputerNames = @()
$IPaddrs = @()

$MaxServer = 16
For ($i = 1; $i -le $MaxServer; $i++) {
    If ($i -lt 10) { $servername = "MEHVM-0" + $i.ToString() } else { $servername = "MEHVM-" + $i.ToString() }
    $ComputerNames += $servername
}

$MaxServer = 72
For ($i = 1; $i -le $MaxServer; $i++) {
    If ($i -lt 10) { $servername = "MEHRDS-0" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }
    $ComputerNames += $servername
}

#$computernames = "MEHVMC11","MEHVMC12","MEHVMC13","MEHVMC14","MEHVMC15","MEHVMC16","MEHVMC17","MEHVMC18"
#$computernames = "MEHVM-07"

ForEach ($computer in $computernames){

    $scriptblock = { Get-NetAdapter -Physical }
    $params = @{ 'ComputerName'=$computer; 'ScriptBlock'=$scriptblock }
    $Outputs = Invoke-Command @params

    foreach ($output in $outputs) {

        $Alias = $Output.interfacealias
        $scriptblock = { Param($Alias) Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $Alias -ErrorAction SilentlyContinue | Select-Object ipaddress }
        $params = @{ 
            'ComputerName'=$computer; 
            'ScriptBlock'=$scriptblock; 
        }
        $Output2 = Invoke-Command @params -ArgumentList $Alias

        $IPaddrs += [PSCustomObject]@{
            Server = $Output.PSComputerName
            Interface = $Output.interfacealias
            LinkSpeed = $output.LinkSpeed
            MediaConnectionState = $output.MediaConnectionState
            IPAddress = $Output2.ipaddress
        }
    }
}

$IPaddrs | Out-GridView