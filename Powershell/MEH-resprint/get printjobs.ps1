
$events = Get-WinEvent -FilterHashTable @{LogName="Microsoft-Windows-PrintService/Operational"; ID=307; StartTime=(Get-Date).AddDays(-1)}

$events | where-object {$_.properties[4].value -like "RE*"} | Format-Table -Property TimeCreated,
                        @{label='UserName';expression={$_.properties[2].value}},
                        @{label='ComputerName';expression={$_.properties[3].value}},
                        @{label='PrinterName';expression={$_.properties[4].value}},
                        @{label='PrintSize';expression={$_.properties[6].value}},
                        @{label='Pages';expression={$_.properties[7].value}} 

$events | where-object {$_.properties[4].value -like "RE*"} | Export-Csv -Path "c:\Printing Audit - $($(Get-Date).ToString('yyyy-MM-dd')).csv" -NoTypeInformation


