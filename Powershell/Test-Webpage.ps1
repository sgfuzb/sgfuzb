
Function Get-UrlStatusCode([string] $Url)
{
    try
    {
        (Invoke-WebRequest -Uri $Url -UseBasicParsing -DisableKeepAlive).StatusCode
    }
    catch [Net.WebException]
    {
        [int]$_.Exception.Response.StatusCode
    }
}

$statusCode = Get-UrlStatusCode 'httpstat.us/500'

While ($true){

    $HTTP_Request = [System.Net.WebRequest]::Create('http://openeyes.moorfields.nhs.uk')
    $HTTP_Response = $HTTP_Request.GetResponse()
    $HTTP_Status = [int]$HTTP_Response.StatusCode

    If ($HTTP_Status -eq 200) {
        Write-Host (get-date) "Site is OK!"
    }
    Else {
        Write-Host (get-date) "The Site may be down, please check!"
    }

    If ($HTTP_Response -eq $null) { } 
    Else { $HTTP_Response.Close() }

    start-sleep 10

}

