#
# Brocade port error report by getting REST API objects
# Steven Gill 17/12/22
#

# seccertmgmt show -all
# if no https cert then generate one;
# seccertmgmt generate -cert https
# see https://www.ibm.com/docs/en/storage-insights?topic=fabrics-configuring-brocade-switches-monitoring

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
$switches = "MO-RDLG-SN6600B-01"

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
    "Authorization"="Custom_Basic $($authorizationInfo)"
    "Accept" = "application/text/html"
    "Content-Type" = "application/text/html"
}

Foreach ($switch in $switches){

    $baseuri = "https://$($switch)/"

    # Switch login
    #$response = Invoke-WebRequest -Uri "$baseuri/login" -Method POST -Headers $Authheaders
    $response = Invoke-WebRequest -Uri "$baseuri/Authenticate.html?page=/switchExplorer.html" -Method GET -Headers $Authheaders

    

    if ($response.StatusCode -eq 200) {
        Write-Host "Auth OK to $switch"

        $authkey = $response.Headers.Authorization
        $headers = @{
            "Authorization"="$authkey"
            "Accept" = "application/yang-data+json"
            "Content-Type" = "application/yang-data+json"
        }

        # get logs
        $response = Invoke-WebRequest -Uri "https://MO-RDLG-SN6600B-01/events.html?format=1" -Method GET -Headers $headers


        <#	Result	Protocol	Host	URL	Body	Caching	Content-Type	Process	Comments	Custom	
        620	200	HTTPS	192.168.28.131	/events.html?format=1	307,815	no-store	text/html; charset=utf-8	jp2launcher:12764			
        624	200	HTTPS	192.168.28.131	/WTLastEvent.html?adID=0	732	no-store	text/html; charset=utf-8	jp2launcher:12764			
        625	200	HTTPS	192.168.28.131	/session.html?action=query	3,292	no-store	text/html; charset=utf-8	jp2launcher:12764			
        627	200	HTTPS	192.168.28.131	/DynamicData.html	346	no-store	text/html; charset=utf-8	jp2launcher:12764			
        628	200	HTTPS	192.168.28.131	/session.html?action=query	3,292	no-store	text/html; charset=utf-8	jp2launcher:12764			
        632	200	HTTPS	192.168.28.131	/session.html?action=VFList	1,231	no-store	text/html; charset=utf-8	jp2launcher:12764			
        #>

        
        <#	Result	Protocol	Host	URL	Body	Caching	Content-Type	Process	Comments	Custom	
        889	200	HTTPS	192.168.28.131	/Logout.html	328	no-store	text/html; charset=utf-8	jp2launcher:12764			
        #>

        # REST logout
        #$response = Invoke-RestMethod -Uri "$baseuri/logout" -Method POST -Headers $headers
        # success = 204 no content
        # 403 - too many sessions

    } else {
        Write-Host "Auth Failed to $switch"
    }
}

#$results | Out-GridView
$results | Export-Csv ".\Get-BrocadeInfoREST.csv"

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

$message = "Ports with errors; <br>" + ($resultswitherr | ConvertTo-html)

#Settings for Email Message
$messageParameters = @{ 
    Subject = "[Brocade Switch port errors on " + $rptDate.ToString($cultureENGB) + "]"
    Body = ("$message")
    From = "FCSwitch.Alerts@moorfields.nhs.uk"
    To = "moorfields.italerts@nhs.net"
    SmtpServer = "smtp.moorfields.nhs.uk"
    Attachments = ".\Get-BrocadeInfoREST.csv"
    
} 
#Send Report Email Message
#Send-MailMessage @messageParameters -BodyAsHtml


<#
# Other APIs

# Switch Info
$response = Invoke-RestMethod -Uri "$baseuri/running/switch/fibrechannel-switch" -Method GET -Headers $headers
$FCSWInfo = $response.Response.'fibrechannel-switch'

# List all REST modules and versions 
$response = Invoke-RestMethod -Uri "$baseuri/brocade-module-version" -Method GET -Headers $headers
    
# Name Server
$response = Invoke-RestMethod -Uri "$baseuri/running/brocade-name-server/fibrechannel-name-server" -Method GET -Headers $headers 
$response.Response.'fibrechannel-name-server' | Out-GridView

# Time Server
$response = Invoke-RestMethod -Uri "$baseuri/running/brocade-time/clock-server" -Method GET -Headers $headers

#>