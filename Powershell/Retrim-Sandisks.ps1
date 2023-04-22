#
# Retrim all SAN disks
#

$cultureENGB = New-Object System.Globalization.CultureInfo("en-GB")

$ServerDisks = @()

$Computers = Get-ADComputer -Filter * -Properties operatingSystem,Enabled,description | 
Select-Object Name, operatingSystem, Enabled, description

$Computers = $computers | Where-Object { !(($_.description -like "*failover*") -or ($_.description -like "*cisco*")) -and ($_.operatingsystem -like "*server*") -and ($_.enabled -eq $true)} | Sort-Object -Descending -Property Name #| Select-Object -First 50

# $computers | Out-GridView

$i=0
$iMax = $Computers.Count

$ServerDisks = Import-Clixml ReTrim-SANDisks.xml

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

#$ServerDisks | Export-Clixml ReTrim-SANDisks.xml -Force



# Datacore Disks
$DCDisks = $ServerDisks | where-object {($_.DriveModel -like "*Datacore*")}

#$DCDisks = $DCDisks | Select-Object -First 1

ForEach ($disk in $DCDisks){

    $Server = $disk.ServerName
    $Driveletter = $disk.Drive.Replace(":","")

    Write-Host "ReTrimming $Driveletter on $server"

    # Run retrim remotely

    $scriptblock = { param ($Driveletter) Optimize-Volume -DriveLetter $Driveletter -Verbose -ReTrim }

    $params = @{ 'ComputerName'=$Server;
                'ScriptBlock'=$scriptblock;
                'ArgumentList'=$Driveletter }

    $output = Invoke-Command @params 
    
    Write-Host $output

    Start-Sleep -Seconds 10*60
}


# Output =============

<#
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
#>