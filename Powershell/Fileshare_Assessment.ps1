<# 
    .SYNOPSIS
        Fileshare and HomeDrive assessment

    .VERSION
    1.2

    .SYNTAX
        .\FileShare_Assessment.ps1 -Directory ""

    .PARAMETERS    
        Directory           : (not mandatory) Path location to where Output and/or Logs folder are to be saved. If not specified: takes the current working location
        Filesharepath       : fileshare path
    
    .OTHER REQUIREMENTS
        Run on admin instance of powershell using domain admin account

    .OUTPUT
        File_Share_Assessment_SubDir_Output.csv

    .SAMPLE
        .\FileShare_YAS_assessment.ps1 -Directory C:\Script\testyas2 -Filesharepath "\\TestServer\Test Share 1""
#>

[CmdletBinding()]
    Param(
        [string] $Server = "applications2",
        [switch] $IncludeVerification
    )

#F U N C T I O N S
####################################
Function showRunTime{
    $stopwatch.stop()
    $seconds = [math]::Round($($stopwatch.Elapsed.TotalSeconds),2)
    $ts = [timespan]::fromseconds($seconds)
    write-host ""
    write-host "Script Total Runtime:  $($ts.hours) Hour(s) - $($ts.minutes) Minute(s) - $($ts.seconds) Second(s)"
}
Function Write-ProgressHelper{
    param(
        [string]$Title,
        [int]$StepNumber,
        [int]$TotalSteps,
        [string]$Message
    )

    Write-Progress -Activity $Title -Status $Message 
    #-PercentComplete (($StepNumber / $TotalSteps) * 100)
}
Function log([string]$logstring){
   
   Add-content $Logfilepath -value "$(Get-date -Format 'yyyy-MM-dd-hhmmss') - $($logstring)"
}
Function Assert-ModuleExists([string]$ModuleName) {
    $module = Get-Module $ModuleName -ListAvailable -ErrorAction SilentlyContinue
    if (!$module) {
        Write-Host "$ModuleName not found. Installing module $ModuleName ..."
        Install-Module -Name $ModuleName -Force -Scope CurrentUser
        Write-Host "Module installed"
    }
}
Function VerifyUser([string]$user){
Try{
    $userdetail = Get-ADUser $user -Properties SamaccountName,mail | select samaccountname,mail,Enabled

    $userDetails = New-Object Psobject
    $userDetails | Add-Member -MemberType NoteProperty 'Mail' -Value $userdetail.mail
    $userDetails | Add-Member -MemberType NoteProperty 'Enabled' -Value $userdetail.Enabled
    $userDetails | Add-Member -MemberType NoteProperty 'Comment' -Value "Account Exist"
}
Catch{
    $userDetails = New-Object Psobject
    $userDetails | Add-Member -MemberType NoteProperty 'Mail' -Value $null
    $userDetails | Add-Member -MemberType NoteProperty 'Enabled' -Value $null
    $userDetails | Add-Member -MemberType NoteProperty 'Comment' -Value $_
}

Return $userDetails
}
#C O N S T A N T S
####################################
$CurrentLocation = (Get-Location).Path
$outputfolder = "$CurrentLocation"
$logfolder = "$CurrentLocation"
$Logfilepath = "$($CurrentLocation)\FileShareAssessment_$(Get-date -format 'yyyy-MM-dd-hhmmss').log"
$Reportfilepath = "$($CurrentLocation)\FileShareAssessment_$(Get-date -format 'yyyy-MM-dd-hhmmss').csv"
$Reportfilepath_user = "$($CurrentLocation)\FileShareAssessment_$(Get-date -format 'yyyy-MM-dd-hhmmss').csv"
$version = "1.2"

#M A I N
####################################

#Set Error Action Preferrence to STOP
$oldPref = $Global:ErrorActionPreference
$Global:ErrorActionPreference = 'SilentlyContinue'

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

If(!(test-path $outputfolder))
{
      New-Item -ItemType Directory -Force -Path $outputfolder
}
If(!(test-path $logfolder))
{
      New-Item -ItemType Directory -Force -Path $logfolder
}

Assert-ModuleExists -ModuleName "ActiveDirectory"

log "Fileshare_Assessment $($version)"

$subreport = @()
$subreport_user = @()

#$shares = net view \\$server /all | select -Skip 7 | ?{$_ -match 'disk*'} | %{$_ -match '^(.+?)\s+Disk*'|out-null;$matches[1]}

$cim = New-CimSession -ComputerName $server
$shares = Get-SmbShare -CimSession $cim
$shares = $shares | Where-Object {$_.Name -notlike "*$*"} | Select-Object name


Foreach ($share in $shares) {


    $Filesharepath = "\\" + $Server + "\" + $share.name

    log "Getting FileShare details $($Filesharepath)"

    $Subroots= Get-ChildItem -LiteralPath "$($Filesharepath)" -directory | Select Fullname,name
    $hdTotal = ($Subroots | Measure-Object).Count
    Foreach($subroot in $Subroots){
    
        log "$($subroot.fullname)"
        Write-ProgressHelper -Title "$($subroot.fullname)" -Message 'Extracting User Homedirectory data' -StepNumber ($hdCounter++) -TotalSteps $hdTotal

        Try{
            log "  Extracting Child Items"
            $childitems = Get-ChildItem -LiteralPath "$($subroot.fullname)" -recurse| Where-Object {$_.PSIsContainer -eq $false} -ErrorAction Ignore
        }
        Catch{
            log "  ERROR$ - $($_)"      
        }
    
        $size = $childitems | Measure-Object -property Length -sum | Select-Object Sum
        If ($size){
            $SizeMB = $size.sum /1MB -as [decimal]
        }
        Else{
            $SizeMB = 0
        }
    
        #Extracting Folder Owners
        Try{
            log = "Extracting Folder Owners"
        
            #checks if $FilesharePath endswith "\" or not
            If($Filesharepath.EndsWith("\") -eq $true){
                $owners = (Get-Acl "$($Filesharepath)$($subroot.Name)").Access | ?{$_.IdentityReference -notlike "BUILTIN\*"} |?{$_.IdentityReference -notlike "NT AUTHORITY\*"} |?{$_.IdentityReference -notlike "*Admins*"} |?{$_.IdentityReference -notlike "*FSFileReadOnly"} |?{$_.IdentityReference -notlike "*# IT Services*"} |?{$_.IdentityReference -notlike "*Everyone"} 
            }
            Else{
                $owners = (Get-Acl "$($Filesharepath)\$($subroot.Name)").Access | ?{$_.IdentityReference -notlike "BUILTIN\*"} |?{$_.IdentityReference -notlike "NT AUTHORITY\*"} |?{$_.IdentityReference -notlike "*Admins*"} |?{$_.IdentityReference -notlike "*FSFileReadOnly"} |?{$_.IdentityReference -notlike "*# IT Services*"} |?{$_.IdentityReference -notlike "*Everyone"} 
            }
        }
        Catch{
            $UserDetails = "Not Found"
            log "  ERROR$ - $($_)" 

            Write-Host $_
            $SubrootDetails = New-Object Psobject
            $SubrootDetails | Add-Member -MemberType NoteProperty 'FolderName' -Value $subroot.name
            $SubrootDetails | Add-Member -MemberType NoteProperty 'Path' -Value "$($subroot.FullName)"
            $SubrootDetails | Add-Member -MemberType NoteProperty 'Description' -Value $subroot.name
            $SubrootDetails | Add-Member -MemberType NoteProperty 'SizeMB' -Value $SizeMB
            $SubrootDetails | Add-Member -MemberType NoteProperty 'ItemCount' -Value ($childitems |measure-object).count
            $SubrootDetails | Add-Member -MemberType NoteProperty 'Owner' -Value $null
            $SubrootDetails | Add-Member -MemberType NoteProperty 'mail' -Value $null
            $SubrootDetails | Add-Member -MemberType NoteProperty 'Enabled' -Value $null
            $SubrootDetails | Add-Member -MemberType NoteProperty 'Permission' -Value $null
            $SubrootDetails | Add-Member -MemberType NoteProperty 'Comments' -Value "ERROR$ - $($_)"

            $subreport += [PSCustomObject]$SubrootDetails
        }

        If(($Owners | Measure-Object).Count -gt 0){
                Foreach($owner in $owners){
                
                    $usersplit = ($owner.IdentityReference).ToString().Split("\")[1]

                    If($IncludeVerification){
                        $userresult = VerifyUser($usersplit)
                    }
                
                    $SubrootDetails = New-Object Psobject
                    $SubrootDetails | Add-Member -MemberType NoteProperty 'FolderName' -Value $subroot.name
                    $SubrootDetails | Add-Member -MemberType NoteProperty 'Path' -Value "$($subroot.FullName)"
                    $SubrootDetails | Add-Member -MemberType NoteProperty 'Description' -Value $subroot.name
                    $SubrootDetails | Add-Member -MemberType NoteProperty 'SizeMB' -Value $SizeMB
                    $SubrootDetails | Add-Member -MemberType NoteProperty 'ItemCount' -Value ($childitems |measure-object).count
                    $SubrootDetails | Add-Member -MemberType NoteProperty 'Owner' -Value $usersplit
                    $SubrootDetails | Add-Member -MemberType NoteProperty 'mail' -Value $userresult.mail
                    $SubrootDetails | Add-Member -MemberType NoteProperty 'Enabled' -Value $userresult.Enabled
                    $SubrootDetails | Add-Member -MemberType NoteProperty 'Permission' -Value $owner.FileSystemRights
                    $SubrootDetails | Add-Member -MemberType NoteProperty 'Comments' -Value ""

                    $subreport += [PSCustomObject]$SubrootDetails

                
                }
            }
        Else{
                $SubrootDetails = New-Object Psobject
                $SubrootDetails | Add-Member -MemberType NoteProperty 'FolderName' -Value $subroot.name
                $SubrootDetails | Add-Member -MemberType NoteProperty 'Path' -Value "$($subroot.FullName)"
                $SubrootDetails | Add-Member -MemberType NoteProperty 'Description' -Value $subroot.name
                $SubrootDetails | Add-Member -MemberType NoteProperty 'SizeMB' -Value $SizeMB
                $SubrootDetails | Add-Member -MemberType NoteProperty 'ItemCount' -Value ($childitems |measure-object).count
                $SubrootDetails | Add-Member -MemberType NoteProperty 'Owner' -Value $null
                $SubrootDetails | Add-Member -MemberType NoteProperty 'mail' -Value $null
                $SubrootDetails | Add-Member -MemberType NoteProperty 'Enabled' -Value $null
                $SubrootDetails | Add-Member -MemberType NoteProperty 'Permission' -Value $null
                $SubrootDetails | Add-Member -MemberType NoteProperty 'Comments' -Value "No Owners"

                $subreport += [PSCustomObject]$SubrootDetails
         }
 
    
    }
}

$subreport_user | select FolderName, Path, Description, SizeMB, ItemCount,Owner,Mail,Enabled,Permission, Comments |Export-Csv $Reportfilepath_user -Encoding Default -NoTypeInformation
$subreport | select FolderName, Path, Description, SizeMB, ItemCount,Owner,Mail,Enabled,Permission, Comments |Export-Csv $Reportfilepath -Encoding Default -NoTypeInformation


write-host "`nOutput CSV files are saved in $outputfolder"

#ReSet Back Error Action Preferrence to STOP
$Global:ErrorActionPreference = $oldPref
