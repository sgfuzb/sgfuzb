$PCs = Get-ADGroupMember LocalAdminLockdownExclusions | Select-Object name 

foreach ($PC in $PCs) {  

    $Groupname = $PC.name + "-Admins"

    New-ADGroup  -GroupScope Global -Path "OU=LocalAdminGroups,OU=SecurityGroups,DC=moorfields,DC=nhs,DC=uk" -Name $Groupname
    Add-ADGroupMember -identity $Groupname -Members "EBME-Admins"

}
