
$Computer = "MEHHEYEX2"
$DCMFiles = "c:\Heyex2Images\imagepool10"
$OrigFilesDirs = "\\mehheyex\heyex\patients\", "\\mehheyex\heyex-new\patients\"
$MigLogPath = "\\mehheyex2\c$\Heyex\logfiles\HEMigrationService.verbose.log"
$MigErrPath = "\\mehheyex2\c$\Heyex\logfiles\MigE2E.error.log"

# Enumerate errors

$MigErrors = @()
$MissingExams = @()

$FileContent = Get-Content -path $MigErrPath #-Raw

ForEach ($line in $FileContent){

    $Splitline = $line -split 'Error'
    $Heyex2No = ($splitline[0] -split '\t')[0]
    $ExamNo = $splitline[1].Trim() -replace '\D+',''
    $ErrorTxt = $splitline[1].Trim() -replace '\d+',''

    # Add to error array
    if (($null -ne $MigErrors.text) -and ($MigErrors.Text.Contains($ErrorTxt))) {
        #Addone
        Foreach ($Find in $MigErrors){
            if ($Find.Text -eq $ErrorTxt){ $Find.count++}
        }
    } else {
        #create new one
        $MigErrors += [PSCustomObject]@{
            Text = $ErrorTxt
            Count = 1
        }
    }

    # Add to Missing Exams
    $MissingExams += [PSCustomObject]@{
        Heyex2No = $Heyex2No
        ExamNo = $ExamNo
        PatInHeyex1 = $false
        ExamInHeyex1 = $false
        OrigMessage = $splitline[1].Trim()
    }
}

# Check original Heyex
ForEach($exam in $MissingExams){

    $OrigPatno = $exam.Heyex2no.ToString().PadLeft(8,'0') + ".pat"
    $origExamNo = $exam.ExamNo.PadLeft(8,'0')
        
    if($exam.PatientNo -eq 71224){
        #Write-Host "Found" #unhash to breakpoint
    }

    # Check if patient exists

    Foreach ($OrigFilesDir in $OrigFilesDirs) {
        $OrigFilePath = ($OrigFilesDir + $OrigPatno + "\")

        if (Test-Path -Path $OrigFilePath) {
            $exam.PatInHeyex1 = $true
            if($origExamNo -ne "00000000") {
                # Check for exams

                $OrigPatExamlist = Get-ChildItem -Path $OrigFilePath | Where-Object {$_.Name -like "*"+$origExamNo+"*"}

                if($OrigPatExamlist.Count -gt 0){
                    $exam.ExamInHeyex1 = $true
                }
            }
        } else {
            $exam.PatInHeyex1 = $false
        }  
    }
}


$MigErrors | Out-GridView
$MissingExams | Out-GridView

$MigErrors | Export-Csv -NoTypeInformation Get-Heyex2StatsMigErrors.csv
$MissingExams | Export-Csv -NoTypeInformation Get-Heyex2StatsMissingExams.csv


Break

# Number of DCM files in archivestore


Write-Host (get-date).ToString($cultureENGB) ", " $computer ", " $DCMFiles ", " -NoNewline

$scriptblock = { param ($parampath) Get-ChildItem -Path $parampath -Recurse -Force -ErrorAction SilentlyContinue | 
Measure-Object -Property Length -Sum | 
Select-Object Sum, Count }

$params = @{ 'ComputerName'=$computer;
            'ScriptBlock'=$scriptblock;
            'ArgumentList'=$DCMFiles }

$foldersize = Invoke-Command @params

$Test.Timestamp = (Get-Date)
$Test.Allocated = ("{0:N4}" -f($foldersize.Sum/1TB)) # num dps as string
$Test.Files = $foldersize.Count

Write-Host Allocated: $Test.Allocated, Files: $Test.Files