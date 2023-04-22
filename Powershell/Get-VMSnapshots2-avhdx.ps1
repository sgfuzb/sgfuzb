

function isFileLocked([string]$Path) {

    $oFile = New-Object System.IO.FileInfo $Path
    ### Make sure the path is good
    if ((Test-Path -Path $Path) -eq $false)
    {
        Write-Host "Bad Path"
        return $false
    }
    
    #Try opening file
    
    $oStream = $oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None) | Out-Null
    
    if ($oStream)
    {
        #Write-Host "Got valid stream so file must not be locked"
        $oStream.Close()
        return $false

    } else {
        # Write-Host "InValid stream so file is locked"
        return $true
    }
}

$Results =@()

$computer = "MEHVMC11"
$path = "\\" + $computer + "\C$\ClusterStorage\"

$VMFiles = Get-ChildItem -Path $path -Recurse -Filter "*.avhdx"

Foreach ($file in $VMFiles){

    If (($file.Length / 1gb) -gt 0.01) {

        # Check if file in use
        $InUse = isFileLocked($file.FullName)

        $Results += [PSCustomObject]@{
            Fullname = $file.FullName
            Creationtime = $file.CreationTime
            SizeGB = ($file.Length / 1gb)
            InUse = $InUse
        }      
    }
}

$Results = $Results | Sort-Object -Descending -Property SizeGB

Write-Host "See Gridview..."
$Results | Out-GridView


# Recovery Snapshots

$VMHosts = "MEHVMC11", "MEHVMC12", "MEHVMC13", "MEHVMC14", "MEHVMC15", "MEHVMC16", "MEHVMC17", "MEHVMC18"

# "MEHVMS1","MEHVMS2", "MEHVMS3", "MEHVMS4", 
# "MEHVM-01", "MEHVM-02", "MEHVM-03", "MEHVM-04", "MEHVM-05", "MEHVM-06", "MEHVM-07", "MEHVM-08", "MEHVM-09", "MEHVM-10", "MEHVM-11", "MEHVM-12", "MEHVM-13", "MEHVM-14", "MEHVM-15","MEHVM-16", "MEHVM15", "MEHVM16", "MEHVM17", "MEHVM18", 
# "MEHVM-CR", "MEHVM-CRO", "MEHVM-EAL", "MEHVM-ME", "MEHVM-NWP", "MEHVM-PB", "MEHVM-STA", "MEHVM-STG"

$Snapshots=@() 
$Snapshots = Get-VMSnapshot -ComputerName $VMHosts -VMName *
$SnapshotCutoff = (Get-Date).AddDays(-1) #(Get-Date).AddHours(-24)
# ($_.SnapshotType -eq "Recovery") -and Recovery, Standard

# Filter to oldest Snapshot (no parent snapshot)
$FilteredShapshots = $Snapshots | Where-Object { ($null -eq $_.ParentSnapshotName) -and ($_.CreationTime -lt $SnapshotCutoff) }

$FilteredShapshots `
| Select-Object ComputerName, VMName, Name, SnapshotType, CreationTime `
| Out-GridView

Foreach ($snapshot in $FilteredShapshots ) {

    Write-Host $snapshot.ComputerName, $snapshot.VMName, $snapshot.Name
    
    Write-Host "Press SPACE to remove, any other key to skip..."
    $key = [Console]::ReadKey()

    if ($key.key -eq "spacebar") {
        $snapshot | Remove-VMSnapshot
    }

    Write-Host " "

    #Start-Sleep 240
}

