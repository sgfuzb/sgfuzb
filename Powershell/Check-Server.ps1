$server = "MEHVMC10"
$count=0
$anim=@("|","/","-","\","|") # Animation sequence characters

Write-Host "Checking $Server...  " -ForegroundColor Yellow

while ($true){
    
    try {
        $isup = Test-Connection -BufferSize 32 -Count 1 -ComputerName $server -Quiet -ErrorAction SilentlyContinue
    } catch {
    }
    
    $char = $anim[$count % 5]

    if($isup) {write-host "`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b$char Server is: Up  " -NoNewline -ForegroundColor Green}
    if(!$isup) {write-host "`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b`b$char Server is: Down" -NoNewline -ForegroundColor Red}
    
    #Write-Host "`b$char" -NoNewline -ForegroundColor Yellow     
    Start-Sleep 1
    $count++ 
}
#Write-Host "$Server is up!"  -ForegroundColor Yellow
