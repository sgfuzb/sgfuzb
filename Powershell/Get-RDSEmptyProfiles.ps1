$MaxRDSServer = 72
$Computernames = @()
$Allprofiles = @()

For ($i = 1; $i -le $MaxRDSServer; $i++) {
    If ($i -lt 10) { $servername = "MEHRDS-0" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }
    $ComputerNames += $servername
}

#$computernames = "MEHRDSTEST-02"

ForEach ($computer in $computernames){ 

    $path = "\\" + $computer + "\C$\Users\"

    $users = Get-ChildItem -Path $path

    Foreach ($user in $users){

        $Userdesktop = $user.FullName + "\Desktop"
        $UserInetcache = $user.FullName + "\AppData\Local\Microsoft\Windows\INetCache"
        $UserCredentials = $user.FullName + "\AppData\Local\Microsoft\Credentials"
        $username = $user.Name
        $UserCreationTime = $user.CreationTime
        
        if(Test-Path -Path $Userdesktop){

        } else {

            if(-not($username -like "*admin*")) {

                $isinetcache = Test-Path -Path $UserInetcache

                try {
                    $iscred = Test-Path -Path $UserCredentials -ErrorAction Stop
                }
                catch [UnauthorizedAccessException] {
                    #Write-Host $_.Exception
                    $iscred = $true
                }
                
                Write-Host "Empty profile, $computer, $username, $isinetcache, $iscred, $UserCreationTime"
                $Allprofiles += [PSCustomObject]@{
                    Server = $computer
                    Profile = $username
                    Inetcache = $isinetcache
                    Cred = $iscred
                    Created = $UserCreationTime
                }
            }
        }       
    }
}

if($Allprofiles.Count -gt 0) {
    Write-Host "See Gridview..."
    $Allprofiles | Out-GridView
} else {
    Write-Host "No Empty Profiles found"
}

# run delprof on stuck inetcache

<#
$StuckInetCacheServers = $Allprofiles | Where-Object {($_.Inetcache -eq $true) -and ($_.Cred -eq $false)} | Select-Object server -Unique

ForEach ($stuckserver in $StuckInetCacheServers){

    $server = $stuckserver.server

    $scriptblock = {c:\source\delprof2.exe /u}
    $Results = Invoke-Command -computername $server -scriptblock $scriptblock

    $Results
}
#>
