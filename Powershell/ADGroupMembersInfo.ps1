$GroupName = "SD_CitoUsers"

$GroupMembers = @()

$GroupMembers = Get-ADGroup  -Filter * | 
Where-Object { $_.Name -like $GroupName} | 
ForEach-Object { Get-ADGroupMember -Identity $_ }

$GroupMemberDeets = $GroupMembers | Select-Object Name, 
      @{n='GivenName';e={if ($_.ObjectClass -eq 'user') {
        Get-ADUser $_ -Property GivenName | Select-Object -Expand GivenName
      } else {
        'NA'
      }}},
      @{n='Surname';e={if ($_.ObjectClass -eq 'user') {
        Get-ADUser $_ -Property Surname | Select-Object -Expand Surname
      } else {
        'NA'
      }}},
      @{n='DisplayName';e={if ($_.ObjectClass -eq 'user') {
        Get-ADUser $_ -Property displayName | Select-Object -Expand DisplayName
      } else {
        'NA'
      }}},
      @{n='Description';e={if ($_.ObjectClass -eq 'user') {
          Get-ADUser $_ -Property description | Select-Object -Expand Description
        } else {
          'NA'
        }}},
      @{n='Enabled';e={if ($_.ObjectClass -eq 'user') {
        Get-ADUser $_ -Property Enabled | Select-Object -Expand Enabled
      } else {
        'NA'
      }}},
      @{n='Mail';e={if ($_.ObjectClass -eq 'user') {
        Get-ADUser $_ -Property mail | Select-Object -Expand mail
      } else {
        'NA'
      }}} | Sort-Object Name
  
$GroupMemberDeets | Out-GridView

$GroupMemberDeets | Export-Csv 'ADGroupMembersInfo.csv' -NoTypeInformation
