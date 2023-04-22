$servers = @()

for ($i=1; $i -le 70; $i++) {
    if ($i -lt 10){	$servers += "MEHRDS-0"+ $i.ToString()}
    if ($i -gt 9){	$servers += "MEHRDS-"+ $i.ToString()}
}

Foreach ($server in $servers){
    $server

    
    $NameSpace = "root\CIMV2\terminalservices"
    $wmi = [WMISearcher]""
    $wmi.options.timeout = (New-Timespan -Seconds 5)
    $query = "Select * from Win32_TSGeneralSetting"
    $wmi.scope.path = "\\$Server\$NameSpace"
    $wmi.query = $query
    $wmi.Scope.Options.Authentication = "PacketPrivacy"
    $wmi.Scope.Options.Impersonation = "Impersonate"
    $WMIHandle = $wmi.Get()
    
    $WMIHandle.SSLCertificateSHA1Hash
    
    
    #try {
    #    $certhash = Get-WmiObject -ComputerName $server -class "Win32_TSGeneralSetting" -Namespace "root\cimv2\terminalservices" -Filter "TerminalName='RDP-tcp'" -ErrorAction SilentlyContinue | select SSLCertificateSHA1Hash
    #}

    #$certhash
}

