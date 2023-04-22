Write-Warning "Type 'WIM' if it is a WIM image you want to add the update to.
			  If it is a VHD or a VHDX image file just type VHD
			  
			  If you don´t type in anything in this and the following options
			  then the script will use default settings and make the folders
			  at C:\WorkDir"
$VHDWIM = Read-Host -Prompt "Type your input here - WIM or VHD"
Write-Host "You have chosen $VHDWIM " -ForegroundColor White -BackgroundColor Red

CLS

Write-Warning "Type the UNC-path or the Local path to where the update files are stored.
			   Type the UNC to the WSUS path if you want update all the WSUS downloaded updates.
			   Here is som eksampels 'C:\WSUS' or '\\WSUS-Server\WSUS-Share\'"
$WSUS = Read-Host -Prompt "Type the path here"
Write-Host "You have entered the follow path $WSUS " -ForegroundColor White -BackgroundColor Red

CLS

Write-Warning "Type the Drive letter you want to use.
			  This option is for higher performence if the drive letter there is used is D: og E:
			  for WorkDir."
$Drev = Read-Host -Prompt "Enter the Drive Letter - C:, D: or E:"
Write-Host "You have enter the $Drev drive to be used" -ForegroundColor White -BackgroundColor Red

CLS

Write-Warning "Enter the path to the WIM or VHDx files,
			   this can UNC-path or Local path to the files."
$Images = Read-Host -Prompt "Enter the path here"
Write-Host "The $VHDWIM files is located at this path $Images and will be patched with the updates located in $WSUS " -ForegroundColor White -BackgroundColor Red

CLS  

If ($VHDWIM -eq "WIM"){
    $TestSti = Test-Path $Drev\WorkDir
        If ($TestSti -eq $false){
            Mkdir "$Drev\WorkDir\Mount\"
            }
    $MountPath = "$Drev\WorkDir\Mount"
    $WIMER = "$Images"

    $WIMS = Get-ChildItem -Recurse -Path "$WIMER" | Where {($_.Extension -eq ".wim")}
        
        ForEach ($WIM in $WIMS.FullName){
        DISM /Mount-Image /ImageFile:"$WIM" /index:1 /MountDir:"$MountPath"
            $Updates = Get-ChildItem -Path "$WSUS" -Recurse | Where {($_.Extension -eq ".msu") -or ($_.Extension -eq ".cab")}
                ForEach ($Update in $Updates.FullName){
                    DISM /Image:"$MountPath" /Add-Package /Packagepath:"$Update"
                    Write-Host "The following update $Update is being applyed to the WIM-file" -ForegroundColor DarkYellow -BackgroundColor DarkGreen
                    }
            
            }
        DISM /Unmount-Image /MountDir:"$MountPath" /commit
        
}ElseIf ($VHDWIM -eq "VHD"){
     $TestSti = Test-Path $Drev\WorkDir
        If ($TestSti -eq $false){
            Mkdir "$Drev\WorkDir\Mount\"
            }
    $MountPath = "$Drev\WorkDir\Mount"
    $WIMER = "$Images"

    $WIMS = Get-ChildItem -Recurse -Path "$WIMER" | Where {($_.Extension -eq ".vhd") -or ($_.Extension -eq ".vhdx")}
        
        ForEach ($WIM in $WIMS.FullName){
        DISM /Mount-Image /ImageFile:"$WIM" /index:1 /MountDir:"$MountPath"
            $Updates = Get-ChildItem -Path "$WSUS" -Recurse | Where {($_.Extension -eq ".msu") -or ($_.Extension -eq ".cab")}
                ForEach ($Update in $Updates.FullName){
                    DISM /Image:"$MountPath" /Add-Package /Packagepath:"$Update"
                    Write-Host "The following update $Update is being applyed to the VHDx-file" -ForegroundColor DarkYellow -BackgroundColor DarkGreen
                    }
            
            }
        DISM /Unmount-Image /MountDir:"$MountPath" /commit
       
}Else{
     $TestSti = Test-Path "C:\WorkDir"
        If ($TestSti -eq $false){
            Mkdir "C:\WorkDir\Mount\"
            }
    
    $MountPath = "C:\WorkDir\Mount"
    $WIMER = "C:\WorkDir\Images"

    $WIMS = Get-ChildItem -Recurse -Path "$WIMER" | Where {($_.Extension -eq ".vhd") -or ($_.Extension -eq ".vhdx") -or ($_.Extension -eq ".wim")}
        
        ForEach ($WIM in $WIMS.FullName){
        DISM /Mount-Image /ImageFile:"$WIM" /index:1 /MountDir:"$MountPath"
            $Updates = Get-ChildItem -Path "$WSUS" -Recurse | Where {($_.Extension -eq ".msu") -or ($_.Extension -eq ".cab")}
                ForEach ($Update in $Updates.FullName){
                    DISM /Image:"$MountPath" /Add-Package /Packagepath:"$Update"
                    Write-Host The following updates are being applyed to the WIM or VHDx files "$Update" -ForegroundColor DarkYellow -BackgroundColor DarkGreen
                    }
            
            }
        DISM /Unmount-Image /MountDir:"$MountPath" /commit
        
}
 



