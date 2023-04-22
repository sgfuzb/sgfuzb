#############################################################
# Brocade port error report by getting REST API objects
# Steven Gill 17/12/22
#############################################################

# seccertmgmt show -all
# if no https cert then generate one;
# seccertmgmt generate -cert https
# see https://www.ibm.com/docs/en/storage-insights?topic=fabrics-configuring-brocade-switches-monitoring

# Set Working Directory
if ($env:computername -eq "INTRANET3"){ Set-Location "C:\PowerShell" }
if ($env:computername -eq "M016815"){ Set-Location "M:\PowerShell" }

Start-Transcript -Path "Get-BrocadeInfoREST.log" -Force

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

$switches = @()
$results = @()

$switches = 
"MO-ESG-SN6600B-01",
"MO-ESG-SN6600B-02",
"MO-ESG-SN6600B-03",
"MO-RDLG-SN6600B-01",
"MO-RDLG-SN6600B-02",
"MO-RDLG-SN6600B-03"

# use to test one
#$switches = "MO-RDLG-SN6600B-01"

<#
# Use to generate string
$username = "admin"
$upassword = "xxx"
$auth = $username + ':' + $upassword
$Encoded = [System.Text.Encoding]::UTF8.GetBytes($auth)
$authorizationInfo = [System.Convert]::ToBase64String($Encoded)
#>

$authorizationInfo = "YWRtaW46ZnIzM3MxZDM="

$Authheaders = @{
    "Authorization"="Basic $($authorizationInfo)"
    "Accept" = "application/yang-data+json"
    "Content-Type" = "application/yang-data+json"
}

Foreach ($switch in $switches){

    $baseuri = "https://$($switch)/rest"

    # Switch login
    $response = Invoke-WebRequest -Uri "$baseuri/login" -Method POST -Headers $Authheaders 
    
    if ($response.StatusCode -eq 200) {
        Write-Host "Auth OK to $switch"

        $authkey = $response.Headers.Authorization   
        $headers = @{
            "Authorization"="$authkey"
            "Accept" = "application/yang-data+json"
            "Content-Type" = "application/yang-data+json"
        }

        # Port info/settings
        $response = Invoke-RestMethod -Uri "$baseuri/running/brocade-interface/fibrechannel" -Method GET -Headers $headers
        $FCPortInfo = $response.Response.fibrechannel
        $FCPortInfo = $FCPortInfo | Where-Object {$_.'physical-state' -eq "online"}

        # Port error stats
        $response = Invoke-RestMethod -Uri "$baseuri/running/brocade-interface/fibrechannel-statistics" -Method GET -Headers $headers 
        $FCPortStats = $response.Response.'fibrechannel-statistics'

        # Alias / Zones
        $response = Invoke-RestMethod -Uri "$baseuri/running/zoning/defined-configuration" -Method GET -Headers $headers
        $FCAliases = $response.Response.'defined-configuration'.alias
        #$FCzones = $response.Response.'defined-configuration'.zone

        #$response = Invoke-RestMethod -Uri "$baseuri/operations/show-status" -Method GET -Headers $headers
        

        foreach ($FCPort in $FCPortInfo){

            $neighborwwn = $FCPort.neighbor[0].wwn[0].ToString()

            $results += [PSCustomObject]@{
                SwitchName = $switch
                Port = $FCPort.name
                'physical-state' = $FCPort.'physical-state'
                Speed = $FCPort.Speed
                NeighbourWWN = $neighborwwn
                AliasName = ($fcAliases | Where-Object {$_.'member-entry'[0].'alias-entry-name' -eq $neighborwwn}).'alias-name'
                'link-failures' = ($FCPortStats | Where-Object {$_.name -eq $FCPort.name}).'link-failures'
                'crc-errors' = ($FCPortStats | Where-Object {$_.name -eq $FCPort.name}).'crc-errors'
                'class-3-discards' = ($FCPortStats | Where-Object {$_.name -eq $FCPort.name}).'class-3-discards'
                'class3-out-discards' = ($FCPortStats | Where-Object {$_.name -eq $FCPort.name}).'class3-out-discards'
                'class3-in-discards' = ($FCPortStats | Where-Object {$_.name -eq $FCPort.name}).'class3-in-discards'
                'in-link-resets' = ($FCPortStats | Where-Object {$_.name -eq $FCPort.name}).'in-link-resets'
                'out-link-resets' = ($FCPortStats | Where-Object {$_.name -eq $FCPort.name}).'out-link-resets'
            }
        }
            
        # REST logout
        $response = Invoke-RestMethod -Uri "$baseuri/logout" -Method POST -Headers $headers
        # success = 204 no content
        # 403 - too many sessions

    } else {
        Write-Host "Auth Failed to $switch"
    }
}

##$results | Out-GridView
$results | Export-Csv "Get-BrocadeInfoREST.csv" -Force

break

# if no file create dummy

#if ($(Get-FileHash "Get-BrocadeInfoREST-last.csv").hash -ne $(Get-FileHash "Get-BrocadeInfoREST.csv").hash) {

    $rptDate = Get-Date
    $cultureENGB = New-Object System.Globalization.CultureInfo("en-GB")

    $resultswitherr = $results | Where-Object {
        ($_.'class-3-discards' -gt 0) -or 
        ($_.'link-failures' -gt 0) -or
        ($_.'crc-errors'  -gt 0) -or
        ($_.'class-3-discards' -gt 0) -or
        ($_.'class3-out-discards' -gt 0) -or
        ($_.'class3-in-discards' -gt 0) -or
        ($_.'in-link-resets' -gt 0) -or
        ($_.'out-link-resets' -gt 0)
    } | Sort-Object -Property 'class-3-discards' -Descending

    $message = "Ports with errors; <br>" + ($resultswitherr | ConvertTo-html) + "<br> use the Get-BrocadeInfoSSH.ps1 script to clear port errors or log on to the switch directly <br>"

    #Settings for Email Message
    $messageParameters = @{ 
        Subject = "[Brocade Switch port errors on " + $rptDate.ToString($cultureENGB) + "]"
        Body = ("$message")
        From = "FCSwitch.Alerts@moorfields.nhs.uk"
        To = "moorfields.italerts@nhs.net"
        SmtpServer = "smtp.moorfields.nhs.uk"
        Attachments = "Get-BrocadeInfoREST.csv"
        
    } 
    #Send Report Email Message
    Send-MailMessage @messageParameters -BodyAsHtml

    #Remove-Item "Get-BrocadeInfoREST-last.csv"
    #Rename-Item "Get-BrocadeInfoREST.csv" "Get-BrocadeInfoREST-last.csv"

#} else {
#    Write-Host "No change"
#}


<#
# Other APIs

# Switch Info
$response = Invoke-RestMethod -Uri "$baseuri/running/switch/fibrechannel-switch" -Method GET -Headers $headers
$FCSWInfo = $response.Response.'fibrechannel-switch'

# List all REST modules and versions 
$response = Invoke-RestMethod -Uri "http://$($HostName)/rest/brocade-module-version" -Method GET -Headers $headers
    
# Name Server
$response = Invoke-RestMethod -Uri "http://$($HostName)/rest/running/brocade-name-server/fibrechannel-name-server" -Method GET -Headers $headers 
$response.Response.'fibrechannel-name-server' | Out-GridView

# Time Server
$response = Invoke-RestMethod -Uri "http://$($HostName)/rest/running/brocade-time/clock-server" -Method GET -Headers $headers

#>