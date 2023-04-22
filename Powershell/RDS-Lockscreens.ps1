# create lockscreens

Add-Type -AssemblyName System.Drawing

$filename = "m:\foo.png"
$bmp = new-object System.Drawing.Bitmap 1024,768
$font = new-object System.Drawing.Font Consolas,24 
$brushBg = [System.Drawing.Brushes]::Black 
$brushFg = [System.Drawing.Brushes]::White 
$graphics = [System.Drawing.Graphics]::FromImage($bmp) 
$graphics.FillRectangle($brushBg,0,0,$bmp.Width,$bmp.Height) 
$graphics.DrawString('MEHRDS-01',$font,$brushFg,10,10) 
$graphics.Dispose() 
$bmp.Save($filename) 

Invoke-Item $filename

# Upload and set reg keys

$Wallpaper = "HC2_Logo_Blue_Background-open.jpg"
$Lockscreen = "HC Lock.jpg"
#copy the OEM bitmap
If (-not (Test-Path "c:\background")) {New-item "c:\background" -type directory}

# make required registry changes
$strPath3 = "HKLM: \SOFTWARE\Policies\Microsoft\Windows\Personalization"
$strPath4 = "HKCU: \SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
New-Item -Path HKLM: \Software\Policies\Microsoft\Windows -Name Personalization -Force
#Set-ItemProperty -Path $strPath3 -Name LockScreenImage -value "C:\background\$lockscreen"

New-Item -Path HKCU: \Software\Microsoft\Windows\CurrentVersion\Policies -Name System -Force
#Set-ItemProperty -Path $strPath4 -Name Wallpaper -value "C:\background\$wallpaper"
#Set-ItemProperty -Path $strPath4 -Name WallpaperStyle -value "2"

