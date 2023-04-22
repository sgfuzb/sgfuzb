#
# Get folder size and file counts for imaging stores
#

$cultureENGB = New-Object System.Globalization.CultureInfo("en-GB")

$TestTable = @()

<#
$TestTable += 
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Eyesuite";Server="MEHEYESUITE";DriveName="MEHEYESUITE";Path="E:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Zeiss";Server="MEHFORUM";DriveName="MEHFORUM-D (DICO4)";Path="D:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Zeiss";Server="MEHFORUM";DriveName="MEHFORUM-Dico5";Path="P:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Zeiss";Server="MEHFORUM";DriveName="MEHFORUM-F";Path="F:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Zeiss";Server="MEHFORUM";DriveName="MEHFORUM-R (cache)";Path="R:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Zeiss";Server="MEHFORUM-DEV";DriveName="MEHFORUM-DEV";Path="F:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Zeiss";Server="MEHFORUM-GW";DriveName="MEHFORUM-GW";Path="E:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Zeiss";Server="MEHFORUM-RW";DriveName="MEHFORUM-RW";Path="E:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX";DriveName="Heyex_archive";Path="E:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX";DriveName="MEHHEYEX";Path="L:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX";DriveName="MEHHEYEX-datadisk-2";Path="R:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX2";DriveName="MEHHEYEX2";Path="C:\Heyex2Images\ImagePool1";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX2";DriveName="Hayex-migration";Path="U:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX2";DriveName="MEHHeyex2-ImagePool2";Path="C:\Heyex2Images\ImagePool2";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX2";DriveName="MEHHeyex2-ImagePool3";Path="C:\Heyex2Images\ImagePool3";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX2";DriveName="MEHHeyex2-ImagePool4";Path="C:\Heyex2Images\ImagePool4";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX2";DriveName="MEHHeyex2-ImagePool5";Path="C:\Heyex2Images\ImagePool5";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX2";DriveName="MEHHeyex2-ImagePool6";Path="C:\Heyex2Images\ImagePool6";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX2";DriveName="MEHHeyex2-ImagePool7";Path="C:\Heyex2Images\ImagePool7";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX2";DriveName="MEHHeyex2-ImagePool8";Path="C:\Heyex2Images\ImagePool8";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX2";DriveName="MEHHeyex2-ImagePool9";Path="C:\Heyex2Images\ImagePool9";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX2";DriveName="MEHHeyex2-ImagePool10";Path="C:\Heyex2Images\ImagePool10";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX2";DriveName="MEHHeyex2-ImagePool11";Path="C:\Heyex2Images\ImagePool11";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX2";DriveName="MEHHeyex2-ImagePool12";Path="C:\Heyex2Images\ImagePool12";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX2-HUB";DriveName="MEHHEYEX2-Hub-disk1";Path="H:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX2-HUB";DriveName="MEHHEYEX2-Hub-disk2";Path="I:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Heidelberg";Server="MEHHEYEX2-HUB";DriveName="MEHHEYEX2-HUB-disk3";Path="J:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="Sir Ludwig Guttman";Modality="Heidelberg";Server="MEHIC6";DriveName="Heyex";Path="E:\Heyex";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="Sir Ludwig Guttman";Modality="Topcon";Server="MEHIC6";DriveName="Topcon3doct-old?";Path="E:\Topcon";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="Croydon";Modality="Topcon";Server="MEHIC9";DriveName="Topcon";Path="E:\Topcon";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="Croydon";Modality="Optos";Server="MEHOPTOS-CRO";DriveName="Optos";Path="E:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="Croydon";Modality="Kowa";Server="MEHIC9";DriveName="Kowa";Path="E:\Kowa";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="Croydon";Modality="Optos";Server="MEHOPTOS-CRO";DriveName="Optos_data";Path="Y:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="Ealing";Modality="Topcon";Server="MEHICEAL";DriveName="Imaging";Path="E:\Imaging";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="Ealing";Modality="Heidelberg";Server="MEHICEAL";DriveName="Heyex";Path="E:\Heyex";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="Ealing";Modality="Pentacam";Server="MEHICEAL";DriveName="Pentacam-Ealing";Path="E:\Pentacam-Ealing";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="Mile End";Modality="Topcon";Server="MEHICME";DriveName="Topcon";Path="E:\Topcon";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="Northwick Park";Modality="Topcon";Server="MEHICNWP";DriveName="Imaging";Path="E:\Imaging";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="Northwick Park";Modality="Heidelberg";Server="MEHICNWP";DriveName="Heyex-HRT2-NWP";Path="E:\Heyex-HRT2-NWP";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="Northwick Park";Modality="Heidelberg";Server="MEHICNWP";DriveName="Heyex";Path="E:\Heyex";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="Northwick Park";Modality="Pentacam";Server="MEHICNWP";DriveName="Pentacam";Path="E:\Pentacam";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="Potter Bar";Modality="Heidelberg";Server="MEHICPB";DriveName="Heyex";Path="E:\Heyex";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="St Georges";Modality="Topcon";Server="MEHICSG";DriveName="OCT 2000 50K";Path="R:\OCT 2000 50K";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="St Georges";Modality="Topcon";Server="MEHICSG";DriveName="OCT 2000 50K2";Path="Q:\OCT 2000 50K";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="St Georges";Modality="Heidelberg";Server="MEHICSG";DriveName="Heyex";Path="Q:\Heyex";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="St Anns";Modality="Topcon";Server="MEHICSTA";DriveName="OCT";Path="E:\OCT";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="St Anns";Modality="Optovue";Server="MEHICSTA";DriveName="Optovue";Path="E:\Optovue";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="St Anns";Modality="Pentacam";Server="MEHICSTA";DriveName="Pentacam";Path="E:\Pentacam_StAnns";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="St Anns";Modality="Heidelberg";Server="MEHICSTA";DriveName="Heyex";Path="E:\Heyex";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET";DriveName="MEHIMAGENET-AOC";Path="N:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET";DriveName="MEHIMAGENET-IMAGENET";Path="F:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET";DriveName="MEHIMAGENET-LASERSUITE";Path="K:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHImagenet6-Archive-01";Path="R:\Archive1";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHImagenet6-Archive-02";Path="G:\Archive2";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHImagenet6-Archive-03";Path="F:\Archive3";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHImagenet6-Archive-04";Path="U:\Archive4";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHImagenet6-Archive-05";Path="P:\Archive5";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHImagenet6-Archive-06";Path="V:\Archive6";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHImagenet6-Archive-07";Path="K:\Archive7";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHImagenet6-Archive-08";Path="L:\Archive8";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHImagenet6-Archive-09";Path="M:\Archive9";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHImagenet6-Archive-10";Path="X:\Archive10";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHImagenet6-Archive-11";Path="H:\Archive11";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHImagenet6-Archive-12";Path="I:\Archive12";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHImagenet6-Archive-13";Path="N:\Archive13";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHImagenet6-Archive-14";Path="C:\ArchiveImages\Archive14";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHIMAGENET6-E";Path="E:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHImagenet6-MEH3DOCT";Path="J:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET6";DriveName="MEHImagenet6-Q-TempCache";Path="Q:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET-RD";DriveName="MEHIMAGENET-RD";Path="F:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Kowa";Server="MEHKOWA";DriveName="mehkowa";Path="D:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Optos";Server="MEHOPTOS";DriveName="MEHOPTOS";Path="P:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Optos";Server="MEHOPTOS-CALI";DriveName="MEHOPTOS-CALI";Path="I:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Optos";Server="MEHOPTOS-CALI";DriveName="MEHOPTOS-CALI-2";Path="J:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Optos";Server="MEHOPTOS-DESP";DriveName="MEHOPTOS-DESP";Path="E:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Optovue";Server="MEHOPTOVUE";DriveName="MEHOPTOVUE";Path="E:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Optovue";Server="MEHOPTOVUE";DriveName="MEHOptovue_archive";Path="F:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="SectraPACs";Server="MEHPACSIMS01";DriveName="MEHPACSIMS01-S";Path="R:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="SectraPACs";Server="MEHPACSIMS01";DriveName="MEHPACSIMS01-U";Path="U:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="SectraPACs";Server="MEHPACSIMS01";DriveName="MEHPACSIMS02-S";Path="S:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="SectraPACs";Server="MEHPACSIMS01";DriveName="MEHPACSIMS02-V";Path="V:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Pentacam";Server="MEHPENTACAM";DriveName="MEHPENTACAM";Path="F:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Pentacam";Server="MEHPENTACAM";DriveName="Pentacam-Archive";Path="E:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Pentacam";Server="MEHPENTACAM";DriveName="Pentacam-Research";Path="K:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="TomeyCascia";Server="MEHTOMEYCASCIA";DriveName="MEHTOMEYCASCIA";Path="F:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Vectra";Server="MEHVECTRA";DriveName="mehvectra";Path="E:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Windip";Server="MEHWINDIP";DriveName="MEHWINDIP";Path="E:";Allocated=0;Files=0}

#>

$TestTable += 
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Topcon";Server="MEHIMAGENET";DriveName="MEHIMAGENET-IMAGENET";Path="F:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Optos";Server="MEHOPTOS";DriveName="MEHOPTOS";Path="P:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="Optos";Server="MEHOPTOS-CALI";DriveName="MEHOPTOS-CALI";Path="I:";Allocated=0;Files=0},
[PSCustomObject]@{Timestamp=(Get-Date);Site="City Road";Modality="TomeyCascia";Server="MEHTOMEYCASCIA";DriveName="MEHTOMEYCASCIA";Path="F:";Allocated=0;Files=0}

ForEach ($Test in $TestTable) {

    $computer = $test.Server
    $path = $test.Path

    if ($path -ne "") {

        if(Test-Connection -ComputerName $computer -Count 3 -ErrorAction SilentlyContinue){

            Write-Host (get-date).ToString($cultureENGB) ", " $computer ", " $path ", " -NoNewline

            $scriptblock = { param ($parampath) Get-ChildItem -Path $parampath -Recurse -Force -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum | 
            Select-Object Sum, Count }

            $params = @{ 'ComputerName'=$computer;
                        'ScriptBlock'=$scriptblock;
                        'ArgumentList'=$path }

            $foldersize = Invoke-Command @params

            $Test.Timestamp = (Get-Date)
            $Test.Allocated = ("{0:N4}" -f($foldersize.Sum/1TB)) # num dps as string
            $Test.Files = $foldersize.Count

            Write-Host Allocated: $Test.Allocated, Files: $Test.Files

        } else {
            Write-Host (get-date).ToString($cultureENGB) ", " $computer ", " $path ", Offline"
        }
    }
}

$TestTable | Out-GridView

$TestTable | Export-Csv ".\Get-ImagingStoreSizes.csv" -NoTypeInformation
