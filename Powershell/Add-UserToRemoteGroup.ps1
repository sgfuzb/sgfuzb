function Add-UsertoRemoteGroup {
    [cmdletbinding()]
   param(
   [string[]]$UserName,
   [string]$ComputerName,
   [string]$GroupName
   )
      ForEach ($User in $UserName){
         Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            NET LOCALGROUP $Using:GroupName /ADD $Using:User
         }
      }
   }

$Computers = "MEHVM-01",
"MEHVM-02",
"MEHVM-03",
"MEHVM-04",
"MEHVM-05",
"MEHVM-06",
"MEHVM-07",
"MEHVM-08",
"MEHVM-09",
"MEHVM-10",
"MEHVM-11",
"MEHVM-12",
"MEHVM-13",
"MEHVM-14",
"MEHVM-15",
"MEHCB-01",
"MEHCB-02",
"MEHGW-01",
"MEHGW-02",
"MEHRDS-01",
"MEHRDS-02",
"MEHRDS-03",
"MEHRDS-04",
"MEHRDS-05",
"MEHRDS-06",
"MEHRDS-07",
"MEHRDS-08",
"MEHRDS-09",
"MEHRDS-10",
"MEHRDS-11",
"MEHRDS-12",
"MEHRDS-13",
"MEHRDS-14",
"MEHRDS-15",
"MEHRDS-16",
"MEHRDS-17",
"MEHRDS-18",
"MEHRDS-19",
"MEHRDS-20",
"MEHRDS-21",
"MEHRDS-22",
"MEHRDS-23",
"MEHRDS-24",
"MEHRDS-25",
"MEHRDS-26",
"MEHRDS-27",
"MEHRDS-28",
"MEHRDS-29",
"MEHRDS-30",
"MEHRDS-31",
"MEHRDS-32",
"MEHRDS-33",
"MEHRDS-34",
"MEHRDS-35",
"MEHRDS-36",
"MEHRDS-37",
"MEHRDS-38",
"MEHRDS-39",
"MEHRDS-40",
"MEHRDS-41",
"MEHRDS-42",
"MEHRDS-43",
"MEHRDS-44",
"MEHRDS-45",
"MEHRDS-46",
"MEHRDS-47",
"MEHRDS-48",
"MEHRDS-49",
"MEHRDS-50",
"MEHRDS-51",
"MEHRDS-52",
"MEHRDS-53",
"MEHRDS-54",
"MEHRDS-55",
"MEHRDS-56",
"MEHRDS-57",
"MEHRDS-58",
"MEHRDS-59",
"MEHRDS-60",
"MEHRDS-61",
"MEHRDS-62",
"MEHRDS-63",
"MEHRDS-64",
"MEHRDS-65",
"MEHRDS-66",
"MEHRDS-67",
"MEHRDS-68",
"MEHRDS-69",
"MEHRDS-70",
"MEHRDS-71",
"MEHRDS-72",
"MEHUAT-01",
"MEHUAT-02",
"MEHWEB-01",
"MEHWEB-02",
"MEHRDS-GOLD2"

#$computers = "MEHWEB-01"

$Username = "RDS-Admins"
$GroupName = "Administrators"
#$Username = "RDS-Auditors"
#$GroupName = "Remote Desktop Users"

foreach ($Computer in $computers){

   Write-Host -NoNewline "Adding $Username to $Groupname on $computer : " 
   Add-UsertoRemoteGroup -ComputerName $computer -UserName $username -GroupName $GroupName

}
