# Update TNSNames.ora files for new oracle location

# load list
$filelist = @()
$filelist = Import-Csv .\update-tnsnames.csv

# For testing
#$filelist = $filelist | Select-Object -First 2

$SearchPaths = "c:\oracle", "c:\app", "d:\oracle", "d:\app", "e:\oracle", "e:\app"
$BackupPath = "M:\Powershell\TNSBK\"


$Changes = @{From = "192.168.18.67";To = "ORALIVE19.moorfields.nhs.uk"},
@{From = "192.168.19.46";To = "ORADEV19.moorfields.nhs.uk"},
@{From = "ORALIVE)";To = "ORALIVE19.moorfields.nhs.uk)"},
@{From = "ORADEV)";To = "ORADEV19.moorfields.nhs.uk)"},
@{From = "RADLIVE";To = "LIVE"},
@{From = "RADTRAIN";To = "TRAIN"},
@{From = "RADTEST";To = "TEST"}

function GetStringBetweenTwoStrings($firstString, $secondString, $String){
    $pattern = "$firstString(.*?)$secondString"
    $result = [regex]::Match($string,$pattern).Groups[1].Value
    return $result
}

foreach ($file in $filelist){

    $servername = $file.server

    if(Test-Connection -ComputerName $servername -Count 1 -Quiet) {

        $path = "\\" + $servername + "\" + $file.Path.Replace(":","$")

        $homename = GetStringBetweenTwoStrings -string $path -firstString "0\\" -secondString "\\network"

        # Check each pair

        foreach($change in $Changes) {

            $from = $change.From
            $to = $change.To

            $filecontent = Get-Content -path $path -Raw  
            $isoldpresent = ($filecontent | Select-String -pattern ([Regex]::Escape($From)))
            $isnewpresent = ($filecontent | Select-String -pattern ([Regex]::Escape($To)))
            #Where-Object { $_.Contains($from)}
            #Select-String -pattern $From

            if($isoldpresent){

                # backup files
                $datestring = (get-date).ToString('yyyyMMddHHmm')
                Copy-Item -path $path -Destination ($BackupPath+$servername+"-"+$homename+"-"+$datestring+"-tnsnames.ora") -Force -ErrorAction SilentlyContinue
                Copy-Item -path $path.Replace("tnsnames.ora","sqlnet.ora") -Destination ($BackupPath+$servername+"-"+$homename+"-"+$datestring+"-sqlnet.ora") -Force -ErrorAction SilentlyContinue

                # replace "from" with "to" in each
                (($filecontent) -replace [Regex]::Escape($From),$to) | Set-Content -Path $path

                Write-Host "Changed $from to $to, $path"
            }        
            if($isnewpresent){
                Write-Host "Already updated $to, $path"
            }

            if((!$isnewpresent)-and(!$isoldpresent)){
                Write-Host "No reference to $From, $path"
            }

        }
    } else {
        Write-Host "Offline: $servername"
    }
}

