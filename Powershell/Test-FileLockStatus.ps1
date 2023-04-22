

 function checkFileStatus($filePath)
 {
     #write-host (get-date) "[ACTION][FILECHECK] Checking if" $filePath "is locked"
     $fileInfo = New-Object System.IO.FileInfo $filePath

     try 
     {
        $fileStream = $fileInfo.Open( [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read )
        #write-host (get-Date) "[ACTION][FILEAVAILABLE]" $filePath
        
        Start-Sleep 2
        Mount-DiskImage $filePath
        Start-Sleep 2
        Dismount-DiskImage $filePath
        Start-Sleep 2

        return $true
     }
     catch
     {
        write-host (get-Date) "[ACTION][FILELOCKED] $filePath is locked"
        return $false
     }
 }


#$basepath = "\\mehsofs\offcon"
$basepath = "m:\offcontemp"

$files = Get-ChildItem -Path $basepath -Filter "*.vhdx" -Recurse

$files = $files | Where-Object  {$_.name -like "*res-test*"}


While ($true) {

    $lockedfiles = @()

    foreach ($file in $files){

        if (-not(checkFileStatus($file.FullName))) {
            $lockedfiles += $file
        }
    }

    $lockedfiles.Length
    #$lockedfiles | Out-GridView
}