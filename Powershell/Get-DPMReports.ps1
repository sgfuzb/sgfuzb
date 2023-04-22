# Get DPM reports


$cultureENGB = New-Object System.Globalization.CultureInfo("en-GB")

$SQLSources = @()

$SQLSources += [PSCustomObject]@{
    ServerName = "MEHDPM-01"
    DatabaseName = "DPMDB_MEHDPM_01"
    Query = "SELECT [DatasourceName], [ServerName], max([CreationTime]) as MaxCreationTime
    FROM [DPMDB_MEHDPM_01].[dbo].[vw_DPM_RecoveryPointDisk]
    where (DatasourceName like '%:%') or (DatasourceName like '%Online\%') or (DatasourceName like '%th-vm%')
    group by ServerName,DatasourceName"
}

$SQLSources += [PSCustomObject]@{
    ServerName = "MEHDPM-02"
    DatabaseName = "DPMDB_MEHDPM_02"
    Query = "SELECT [DatasourceName], [ServerName], max([CreationTime]) as MaxCreationTime
    FROM [DPMDB_MEHDPM_02].[dbo].[vw_DPM_RecoveryPointDisk]
    where (DatasourceName like '%:%') or (DatasourceName like '%Online\%') or (DatasourceName like '%th-vm%')
    group by ServerName,DatasourceName"
}

$SQLSources += [PSCustomObject]@{
    ServerName = "MEHDPM-03"
    DatabaseName = "DPMDB_MEHDPM_03"
    Query = "SELECT [DatasourceName], [ServerName], max([CreationTime]) as MaxCreationTime
    FROM [DPMDB_MEHDPM_03].[dbo].[vw_DPM_RecoveryPointDisk]
    where (DatasourceName like '%:%') or (DatasourceName like '%Online\%') or (DatasourceName like '%th-vm%')
    group by ServerName,DatasourceName"
}

$BackedUpDisks = @()

foreach ($SQLSource in $SQLSources){

    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = "Server="+$SQLSource.ServerName+";Database="+$SQLSource.DatabaseName+";Integrated Security=True;"
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $SQLSource.Query

    $result = $command.ExecuteReader()

    $SPtable = new-object "System.Data.DataTable"
    $SPtable.Load($result)

    $connection.Close()

    if ($sptable.Rows.Count -gt 0){

        foreach ($SProw in $SPtable) {

            $BackedUpDisks += [PSCustomObject]@{
                BackupServer = $SQLSource.ServerName
                ServerName = $SProw.ServerName.split('.m')[0]
                Drive = $SProw.DatasourceName
                LastBackupTime = $SProw.MaxCreationTime
            }
        }
    }
}

$ServerDisks = @()

$Computers = Get-ADComputer -Filter * -Properties operatingSystem,Enabled,description | 
Select-Object Name, operatingSystem, Enabled, description

$Computers = $computers | Where-Object { !(($_.description -like "*failover*") -or ($_.description -like "*cisco*")) -and ($_.operatingsystem -like "*server*") -and ($_.enabled -eq $true)} | Sort-Object -Descending -Property Name #| Select-Object -First 50

# $computers | Out-GridView

$i=0
$iMax = $Computers.Count

$ServerDisks = Import-Clixml Get-DPMServerdisks.xml

<#
ForEach ($Computer in $Computers) {
    if (Test-Connection $Computer.Name -Count 1 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue){
        $i++
        $status = "Checking " + $Computer.Name
        Write-Progress -Activity "Gathering Drives" -status $status -percentComplete ($i / $iMax*100)
      
        $Disks = Get-WmiObject -ComputerName $Computer.Name -Class Win32_logicaldisk -Filter "DriveType = '3'" 
        foreach ($disk in $disks){
            $DiskPartitions = $Disk.GetRelated('Win32_DiskPartition')
            foreach ($Diskpartition in $DiskPartitions){
                $DiskDrives = $DiskPartition.getrelated('Win32_DiskDrive')
                Foreach ($Diskdrive in $Diskdrives) {

                    $ServerDisks += [PSCustomObject]@{
                        ServerName = $Computer.Name
                        Drive =  $disk.DeviceID
                        DriveName = $disk.VolumeName
                        DriveModel = $DiskDrive.Model
                        DriveSize = $disk.Size
                        DriveFree = $disk.Freespace
                        BackupStatus = $false
                        BackupDate = ""
                        BackupServer = ""
                    }
                }
            }
        }
    }
}
#>

#$ServerDisks | Export-Clixml Get-DPMServerdisks.xml -Force

# Find Backed up drive letters

$MaxServerdisks = $ServerDisks.count

For ($i = 0; $i -lt $MaxServerdisks; $i++){

    # $server.ServerName
    # $server.Drive
    # $BackedUpDisks.ServerName
    # $BackedUpDisks.Drive

    
    for ($j = 0; $j -lt $BackedUpDisks.Count; $j++) {
       
        # Mark drive as baing backed up
        if (($ServerDisks[$i].ServerName -eq $BackedUpDisks[$j].servername) `
        -and ($ServerDisks[$i].Drive -eq $BackedUpDisks[$j].Drive.split('\')[0]) `
        ) {

            $ServerDisks[$i].BackupStatus = $true
            $ServerDisks[$i].BackupDate = $BackedUpDisks[$j].LastBackupTime
            $ServerDisks[$i].BackupServer = $BackedUpDisks[$j].BackupServer
        }

        # Add entry for VM backup (match C for only one per server!)
        if (($ServerDisks[$i].Drive -eq "C:") `
        -and (($BackedUpDisks[$j].Drive.split('\')[0] -eq "Th-VM") -or ($BackedUpDisks[$j].Drive.split('\')[0] -eq "Online")) `
        -and ($ServerDisks[$i].ServerName -eq $BackedUpDisks[$j].Drive.split('\')[1]) `
        ) {

            $ServerDisks[$i].DriveModel = "VM Backup"
            $ServerDisks[$i].BackupStatus = $true
            $ServerDisks[$i].BackupDate = $BackedUpDisks[$j].LastBackupTime
            $ServerDisks[$i].BackupServer = $BackedUpDisks[$j].BackupServer

            <#
            $ServerDisks += [PSCustomObject]@{
                ServerName = $ServerDisks[$i].ServerName
                Drive =  "VM Backup"
                DriveName = "VM Backup"
                DriveModel = "NA"
                BackupStatus = $true
                BackupDate = $BackedUpDisks[$j].LastBackupTime
                BackupServer = $BackedUpDisks[$j].BackupServer
            }
            #>
        }
    }
}

# Data Drives being backed up
$ServerDisks | where-object {$_.BackupStatus -eq $True} `
| Select-Object ServerName,Drive,DriveName,DriveModel,DriveSize,DriveFree,BackupStatus,BackupDate,BackupServer `
| Export-Csv -NoTypeInformation "Get-DPM-BackedUp.csv"
#| Out-GridView

# Data Drives not backed up
$ServerDisks | where-object {( `
($_.BackupStatus -eq $False) `
-and ($_.DriveModel -ne "Microsoft Virtual Disk") `
-and ($_.DriveModel -ne "Virtual HD ATA Device") `
-and ($_.DriveModel -notlike "DELL PERC*") `
-and ($_.DriveModel -notlike "*LOGICAL VOLUME*") `
)} `
| Export-Csv -NoTypeInformation "Get-DPM-NoDataDriveBackup.csv"
#| Out-GridView

# VM servers not backed up
$ServerDisks | where-object {( `
($_.BackupStatus -eq $False) `
-and ($_.Drive -eq "C:") `
-and ($_.ServerName -notlike "MEHDPM*") `
-and ($_.ServerName -notlike "MEHVM*") `
-and ($_.ServerName -notlike "MEHRDS*") `
-and ($_.DriveModel -notlike "DELL PERC*") `
-and ($_.DriveModel -notlike "*LOGICAL VOLUME*") `
)} `
| Export-Csv -NoTypeInformation "Get-DPM-NoVMBackup.csv"
#| Out-GridView

# Set Drive Volume Labels
#Get-WmiObject -ComputerName "MEHVM7" -Class win32_volume -Filter "DriveLetter = 'E:'" | Set-WmiInstance -Arguments @{DriveLetter="E:"; Label="SAN VM Data-NoDPM"}

# Output =============

$HTML=@"
<style>
TABLE{border-width: 1px;border-style: solid;border-color: black;}
TH{border-width: 1px;padding: 5px;border-style: solid;border-color: black;text-align: center;}
TD{border-width: 1px;padding: 5px;border-style: solid;border-color: black;text-align: left;}
</style>
"@

$rptDate = Get-Date

#Settings for Email Message
$messageParameters = @{ 
    Subject = "[DPM Backup Reports on " + $rptDate.ToString($cultureENGB) + "]"
    Body = "Attached are the reports"
    From = "it.alerts@moorfields.nhs.uk" 
    To = "moorfields.italerts@nhs.net"
    SmtpServer = "smtp.moorfields.nhs.uk"
    #SmtpServer = "127.0.0.1"
    Attachments = ".\Get-DPM-BackedUp.csv", ".\Get-DPM-NoDataDriveBackup.csv", ".\Get-DPM-NoVMBackup.csv"
    
} 
#Send Report Email Message
Send-MailMessage @messageParameters -BodyAsHtml
