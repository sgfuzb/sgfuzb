Import-module ActiveDirectory

$logfile = "m:\powershell\addtoadgroup_" + (get-date -format yyyyMMddmmss) + ".log"
$ADGroupName = "PAS_Users_group"
#$ErrorActionPreference = "continue"

ForEach ($username in (Get-Content "m:\powershell\addtoadgroup2.txt")) {
    
    try { 
        $dpn = Get-ADUser -identity $username
    } catch { 
        $dpn = ""
    }

    if ($dpn) {
        Add-ADGroupMember -Identity $ADGroupName -Members $username -ErrorAction Stop
        Write-Output "$username, added to $ADGroupName"
        Add-Content -path $logfile -value "$username, added to $ADGroupName"
    }
    else {
        write-warning "$username, Not found"
        Add-Content -path $logfile -value "$username, Not found"
    }
}
