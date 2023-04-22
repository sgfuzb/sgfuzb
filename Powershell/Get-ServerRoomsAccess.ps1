
$cultureENGB = New-Object System.Globalization.CultureInfo("en-GB")
$Message = ""

$SQLSource = [PSCustomObject]@{
    ServerName = "MEHHONEYWELL"
    DatabaseName = "WIN-PAK PRO"
    Query = "SELECT   distinct     Card.CardNumber, Card.ActivationDate, Card.ExpirationDate, CardHolder.FirstName, CardHolder.LastName, Card.Deleted, Card.CardStatus, Card.CardHolderID,  
    CardAccessLevels.AccessLevelID, AccessLevelPlus.Name, AccessLevelPlus.Description
FROM            Card INNER JOIN
    CardHolder ON Card.CardHolderID = CardHolder.RecordID INNER JOIN
    CardAccessLevels ON Card.RecordID = CardAccessLevels.CardID INNER JOIN
    AccessLevelPlus ON CardAccessLevels.AccessLevelID = AccessLevelPlus.RecordID
WHERE        (Card.Deleted = 0) and CardaccessLevels.AccessLevelID = 205
order by LastName"

}

Function Write-SGLog
{
    Param
    (
        [string] $SGlogMessage
    )

    Write-Host (get-date) $SGlogMessage
    #$Message += $SGlogMessage + "<br>"
}


$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = "Server="+$SQLSource.ServerName+";Database="+$SQLSource.DatabaseName+";Integrated Security=True;"
$connection.Open()
$command = $connection.CreateCommand()
$command.CommandText = $SQLSource.Query

$result = $command.ExecuteReader()

$SPtable = new-object "System.Data.DataTable"
$SPtable.Load($result)

$SPtable = $SPtable | Sort-Object -Property LastName

$connection.Close()

Write-SGLog "Members of of IT Group Secure in Winpak"
$Message += "Members of of IT Group Secure in Winpak" + "<br>"

if ($sptable.Rows.Count -gt 0){

    foreach ($SProw in $SPtable) {

        Write-SGLog ($SProw.Firstname + " " + $SProw.LastName + " - " + $SProw.CardNumber.Trim())
        $Message += ($SProw.Firstname + " " + $SProw.LastName + " - " + $SProw.CardNumber.Trim()) + "<br>"
    }
}

$Message

$HTML=@"
<style>
TABLE{border-width: 1px;border-style: solid;border-color: black;}
TH{border-width: 1px;padding: 5px;border-style: solid;border-color: black;text-align: center;}
TD{border-width: 1px;padding: 5px;border-style: solid;border-color: black;text-align: left;}
</style>
"@

$rptDate = Get-Date

#Settings for Email Message
$messageParameters = @{ 
    Subject = "[Server Room Access Report on " + $rptDate.ToString($cultureENGB) + "]"
    Body = $HTML + $Message
    From = "it.alerts@moorfields.nhs.uk" 
    To = "moorfields.italerts@nhs.net"
    SmtpServer = "smtp.moorfields.nhs.uk"
    #SmtpServer = "127.0.0.1"
    #Attachments = ".\Get-DPM-BackedUp.csv"
    
} 
#Send Report Email Message
Send-MailMessage @messageParameters -BodyAsHtml
