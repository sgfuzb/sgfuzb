
# To test run 
# psexec -s -i cmd
# C:\Windows\system32\WindowsPowerShell\v1.0\PowerShell_ISE.exe

# ===================================================
# Parameters

$daysold = 365*4
$cutoffdate = (Get-Date).AddDays(-$daysold)

$DLCuttoffDays = 180
$DLCutoffDate = (Get-Date).AddDays(-$DLCuttoffDays)

$sourcedir = "S:\Redirect$"
$destdir = "T:\RedirectArchive\"

$cultureENGB = New-Object system.globalization.cultureinfo(“en-gb”)

$whatifpreference = $false #true for debug

# ===================================================

$folders = Get-ChildItem -Directory $sourcedir
#| Select-Object -First 1000
#| where {$_.name -match "ab"}

$folderlist =  New-Object System.Collections.Generic.List[System.Object] #@()

# $folderlist.Add([pscustomobject]@{"FolderPath"="";"Numfiles"="";"FolderSize"=0;"LastWriteTime"=""})

$message = ""

$Message += "===================================================<br>"
$Message += "Redirect Profile folders on MEHREDIR<br>"
$Message += "With files not written to for " + $daysold + " Days (Before: "+$cutoffdate.ToString($cultureENGB)+ ")<br>"
$Message += "===================================================<br>"

# ===================================================
# Delete old Download Files
# ===================================================

ForEach ($folder in $folders){
    $DownloadFolder = $folder.FullName + "\downloads\"
    $DownloadFiles = Get-ChildItem $DownloadFolder -Recurse | Where-Object CreationTime -lt $DLCutoffDate  # CreationTime picks up folders
    $DownloadFiles | Remove-Item -Force
}

# ===================================================
# Create Folderlist to process
# ===================================================

Foreach ($folder in $folders){

    try {
        $Files = Get-Childitem -Path $folder.FullName -File -force -Recurse -ErrorAction Stop | Sort-Object -Descending LastWriteTime
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
        $Message += $folder.Fullname + "Error Enumerating Files <br>" 
    }
}

# Select folders not written to since before cutoff or no files
$toprocess = $folderlist | Where-Object {($_.LastWriteTime -lt $cutoffdate) -or ($_.Numfiles -eq 0)}

#break

# ===================================================
# Process identified folders
# ===================================================

$Message += "Identified " + $toprocess.count + " profiles to process<br>"
$Message += "Size in GB:" + (($toprocess | Measure-Object -Property FolderSize -Sum).Sum / 1gb).ToString() + "<br>"
#Write-Host "Identified:" $toprocess.count 
#Write-Host "GB:" (($toprocess | Measure-Object -Property FolderSize -Sum).Sum / 1gb)

$Message += "===================================================<br>"

$Message += "FolderPath,numfiles,FolderSize,LastWriteTime <br>"

Foreach ($folder in $toprocess ){

    $Message += $folder.FolderPath + "," + $numfiles + "," + $folder.FolderSize + "," + $folder.LastWriteTime + "<br>"
    #Remove-Item $folder.FolderPath -Force -Recurse
    
    # Delete Downloads in folder before moving
    $DownloadFolder = $folder.FullName + "\downloads\"
    $DownloadFiles = Get-ChildItem $DownloadFolder -Recurse
    $DownloadFiles | Remove-Item -Force
    
    #Take ownership and Move folder
    takeown.exe /a /r /d Y /f $folder.FolderPath
    Move-Item $folder.FolderPath $destdir

    # If the folder is empty then remove (2nd pass)
    if ($folder.FolderSize -eq 0){
        Remove-Item $folder.FolderPath -Recurse -Force 
    }
 }

# ===================================================
# Report and email
# ===================================================

$Message += "===================================================<br>"
$Message += "DONE!<br>"


#Settings for Email Message
$rptDate=(Get-date)
if ($whatifpreference -eq $true) {
    $subjectprefix = "###TEST### " 
    $Message
} else {$subjectprefix = "" } 

$messageParameters = @{ 
    Subject = "[" + $subjectprefix + "REDIR Old Profile Delete " + $rptDate.ToString($cultureENGB) + "]"
    Body = $Message
    From = "it.alerts@moorfields.nhs.uk" 
    To = "moorfields.italerts@nhs.net"
    #To = "sg@nhs.net"
    SmtpServer = "smtp.moorfields.nhs.uk"
    #SmtpServer = "127.0.0.1"
} 
#Send Report Email Message
Send-MailMessage @messageParameters -BodyAsHtml

