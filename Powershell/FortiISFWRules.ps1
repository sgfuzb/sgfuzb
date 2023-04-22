$i=26
$vlans = @("17","18","19","20","21","22","28","41")
cls
Write-host "config firewall policy"

foreach  ($svlan in $vlans){
    foreach ($dvlan in $vlans){
        if ($svlan -ne $dvlan) {
            Write-host "
                edit  $i
                    set srcintf ""vlan.$svlan""
                    set dstintf ""vlan.$dvlan""
                    set srcaddr ""all""
                    set dstaddr ""all""
                    set action accept
                    set schedule ""always""
                    set service ""ALL""
                next  
                "
            $i++
        }
    }
}

Write-host "End"