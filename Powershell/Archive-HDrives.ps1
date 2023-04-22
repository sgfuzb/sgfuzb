# ===============================================================
# Move old H drives to Archive drive based on AD account info
# Steven Gill - March 2023
# ===============================================================

$whatifpreference = $false # true for debug

$nomove = $false # true for debug

$srcdir = "\\applications2\J$\Homeshares\"
$destdir = "\\applications2\Archived2022\"

$Outputcsv = ".\Archive-HDrives.csv"

$CutoffYears = 6 # Four Years
$CutoffDate = (get-date).Adddays(-365*$CutoffYears)

# Exceptions where share name <> folder name
$server = "Applications2"
$cim = New-CimSession -ComputerName $server
$shares = Get-SmbShare -CimSession $cim
$Excludes = $shares | Where-Object {($_.Name -notlike "*$*") -and ($_.path -notlike "*"+$_.Name+"*" ) -and ($_.path -like "*j:*" )} | Select-Object Name, Path
#$Excludes | Out-GridView

# Add manual exclusions
$Excludes += [PSCustomObject] @{Name = "VirdeeA"; Path = "J:\homeshares\VirdeeA"}
$Excludes += [PSCustomObject] @{Name = "IT_PMO"; Path = "J:\homeshares\IT_PMO"}

$FolderList = @()

# ===============================================================

Function Write-SGLog
{
    Param
    (
        [string] $SGlogMessage
    )

    Write-Host (get-date) $SGlogMessage
    #$Message += $SGlogMessage + "<br>"

}
Function MoveFolder {

    Param (
        [String]$SrcDir,
        [String]$DstDir
    )

    If (Test-Path -LiteralPath $Srcdir) {
        if ($nomove){
            Move-Item $Srcdir $dstdir -Force -Verbose -WhatIf
        } else {
            Move-Item $Srcdir $dstdir -Force -Verbose
        }
    } else {
        Write-SGLog "Error : Folder doesn't exist: $Srcdir"
    }    
}

# ===============================================================
# Get folders
# ===============================================================

$FoldersOnDisk = Get-ChildItem -Directory $srcdir 


# ===============================================================
# Analyse Folders
# ===============================================================

Foreach ($FolderOnDisk in $FoldersOnDisk){

    # $Message += $folder.FolderPath + "," + $numfiles + "," + $folder.FolderSize + "," + $folder.LastWriteTime + "<br>"
    # Remove-Item $folder.FolderPath -Force -Recurse
    # takeown.exe /a /r /d Y /f $folder.FolderPath

    $Srcdir = $FolderOnDisk.FullName
    $User = $Srcdir.split("\")[($Srcdir.split("\").count)-1]

    $ADuser = Get-ADUser -ErrorAction SilentlyContinue -filter {SamAccountName -eq $user} -Properties LastLogon, LastLogontimestamp, whenCreated, Enabled `
    | Select-Object name, @{Name='LastLogontimestamp';Expression={[DateTime]::FromFileTime($_.LastLogontimestamp)}}, @{Name='LastLogon';Expression={[DateTime]::FromFileTime($_.LastLogon)}}, whenCreated, Enabled

    if ($ADuser){
        if ($ADuser.LastLogon -gt $ADuser.LastLogontimeStamp) {
            $LastLogon = $ADuser.LastLogon
        } else {
            $LastLogon = $ADuser.LastLogontimeStamp
        }
    } else {
        $LastLogon = $null
    }

    $FolderList += [PSCustomObject]@{
        Srcdir = $Srcdir
        User = $User
        Exclude = ($Srcdir.replace("\\applications2\J$","J:") -in $Excludes.Path)
        ADUser = $ADuser.Name
        ADLastLogon = $LastLogon
        ADCreated = $ADuser.WhenCreated
        ADEnabled = $ADuser.Enabled
        Move = $false
        ActionDesc = ""
        }
}

# ===============================================================
# Process Folders
# ===============================================================

Foreach ($Folder in $FolderList){

    $User = $Folder.User

    If ($folder.Exclude -eq $true) {
        $folder.ActionDesc = "$User : OK - Excluded"
    }

    If (
        ($null -ne $folder.ADuser) -and
        ($folder.Exclude -eq $false) -and
        ($Folder.ADEnabled -eq $true) 
        ) {
        $folder.ActionDesc = "$User : OK - Exists, Enabled"
    }

    If (
        ($null -eq $folder.ADuser) -and
        ($folder.Exclude -eq $false)
        ) {
        $folder.ActionDesc = "$User : Moving - Does not exist in AD"
        $folder.Move = $true
    }

    If (
        ($null -ne $folder.ADuser) -and
        ($folder.Exclude -eq $false) -and
        ($Folder.ADEnabled -eq $false) -and 
        ($Folder.ADLastLogon -gt "01/01/1601") -and
        ($Folder.ADLastLogon -lt $CutoffDate) -and 
        ($folder.ADCreated -lt $CutoffDate)
        ) {
        $folder.ActionDesc = "$User : Moving - Exists, disabled, lastlogon and created before cutoff"
        $folder.Move = $true
    }
    
    If (
        ($null -ne $folder.ADuser) -and
        ($folder.Exclude -eq $false) -and
        ($Folder.ADEnabled -eq $false) -and 
        ($Folder.ADLastLogon -eq "01/01/1601") -and 
        ($folder.ADCreated -lt $CutoffDate)
        ) {
        $folder.ActionDesc = "$User : Moving - Exists, Disabled, Never Logged on, created before cutoff"
        $folder.Move = $true
    }
    
    #if ($folder.FolderSize -eq 0){
    #    Remove-Item $folder -Recurse -Force 
    #}
}

#$FolderList | Out-Gridview
$FolderList | Export-Csv -NoTypeInformation $Outputcsv

$FolderListFiltered = $FolderList | Where-Object {$_.Move -eq $true} `
| Select-Object -First 50
#| Where-Object {$_.User.StartsWith("d")}

$FolderListFiltered | Out-Gridview

Write-Host "Press any key to start moves..."
$key = [Console]::ReadKey()

# Move those folders that need to be moved
Foreach ($Folder in $FolderListFiltered){

    if ($folder.Move -eq $true){
        Write-SGLog $folder.ActionDesc
        MoveFolder -SrcDir $Folder.Srcdir -DstDir $destdir
    }
}
