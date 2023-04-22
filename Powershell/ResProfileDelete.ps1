$daysold = 365
$cutoffdate = (Get-Date).AddDays(-$daysold)
$numtodelete = 0

$whatifpreference = $true #debug
 
$folders = Get-ChildItem -Directory E:\RES  
#| where {$_.name -match "ada"}

$folderlist = @()

# $folderlist.Add([pscustomobject]@{"FolderPath"="";"Numfiles"="";"LastWriteTime"=""})

$message = ""

$Message += "===================================================<br>"
$Message += "RES Profile folders on RES-CB01<br>"
$Message += "With files not written to for " + $daysold + " Days (Before: "+$cutoffdate.ToString($cultureENGB)+ ")<br>"
$Message += "===================================================<br>"


Foreach ($folder in $folders){

    try {
        $Files = Get-Childitem -Path $folder.FullName -File -force -Recurse | Sort-Object -Descending LastWriteTime
        $Numfiles = $files.count
        
        if ($numfiles -ne 0){
            #write-host $folder.Fullname : Numfiles: $numfiles : last Write: $files[0].LastWriteTime
            $FolderSize = ($files | Measure-Object -property Length -Sum).Sum
            $folderlist.Add([pscustomobject]@{"FolderPath"=$folder.Fullname;"Numfiles"=$numfiles;"FolderSize"=$FolderSize;"LastWriteTime"=$files[0].LastWriteTime}) | Out-Null            
        } else {
            #write-host $folder.Fullname : Zero Files
            $folderlist.Add([pscustomobject]@{"FolderPath"=$folder.Fullname;"Numfiles"=0;"FolderSize"=0;"LastWriteTime"=""}) | Out-Null
        }
    } catch {
        write-host $folder.Fullname : "Error Enumerating Files"
    }
}

# Select folders not written to since before cutoff
$todelete = $folderlist | where {$_.LastWriteTime -lt $cutoffdate}

$Message += "Identified " + $todelete.count + " Profiles to delete<br>"
$Message += "Size in GB:" + (($todelete | Measure-Object -Property FolderSize -Sum).Sum / 1gb).ToString() + "<br>"
#Write-Host "Identified:" $todelete.count 
#Write-Host "GB:" (($todelete | Measure-Object -Property FolderSize -Sum).Sum / 1gb)

$Message += "===================================================<br>"

$Message += "FolderPath,numfiles,FolderSize,LastWriteTime <br>"

Foreach ($folder in $todelete ){

    $Message += $folder.FolderPath + "," + $numfiles + "," + $folder.FolderSize + "," + $folder.LastWriteTime + "<br>"
    Remove-Item $folder.FolderPath -Force -Recurse
}

# ===================================================
# Report and email
# ===================================================

$Message += "===================================================<br>"
$Message += "DONE!<br>"


#Settings for Email Message
$rptDate=(Get-date)
if ($whatifpreference -eq 1) {
    $subjectprefix = "###TEST### " 
    $Message
} else {$subjectprefix = "" } 

$messageParameters = @{ 
    Subject = "[" + $subjectprefix + "RES Old Profile Delete " + $rptDate.ToString($cultureENGB) + "]"
    Body = $Message
    From = "it.alerts@moorfields.nhs.uk" 
    #To = "moorfields.italerts@nhs.net"
    To = "sg@nhs.net"
    SmtpServer = "smtp.moorfields.nhs.uk"
    #SmtpServer = "127.0.0.1"
} 
#Send Report Email Message
Send-MailMessage @messageParameters -BodyAsHtml