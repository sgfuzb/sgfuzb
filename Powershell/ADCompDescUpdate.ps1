import-module ActiveDirectory

$WhatIfPreference = 0 # Debug = 1

$Message = $null

$Message = "===================================================<br>" 
$Message += "Computer Description Updates<br>" 
$Message += "===================================================<br>" 

# For Each Enabled Computer in AD

$enabledcomputers = Get-ADComputer -Filter * -Properties PasswordLastSet,Enabled,description | 
Where-Object { ($_.enabled -eq $true) -and !(($_.description -like "*failover*") -or ($_.description -like "*cisco*"))} | 
Select-Object name,  
@{n="OU";e={$_.distinguishedname.split(",")[1]}} |
Sort-Object Name | Select-Object -First 100

$Message += "Updating "+ $enabledcomputers.Count +" Computer Descriptions <br>" 
$Message += "===================================================<br>" 

foreach ($Computer in $enabledcomputers){

    # Get SP AssetDB details

    #$Computername = "M016815"
    $Computername = $computer.Name

    $dataSource = "SP\SP"
    $database = "WSS_Content"
    $query = "SELECT  tp_ColumnSet,
    [tp_ColumnSet].value(N'/nvarchar1[1]', 'nvarchar(30)') as [AssetNo],
    [tp_ColumnSet].value(N'/nvarchar5[1]', 'nvarchar(30)') as [CallRef],
    [tp_ColumnSet].value(N'/nvarchar6[1]', 'nvarchar(30)') as [User],
    [tp_ColumnSet].value(N'/nvarchar7[1]', 'nvarchar(30)') as [Department],
    [tp_ColumnSet].value(N'/nvarchar8[1]', 'nvarchar(30)') as [Floor],
    [tp_ColumnSet].value(N'/nvarchar9[1]', 'nvarchar(30)') as [SerialNo],
    [tp_ColumnSet].value(N'/nvarchar10[1]', 'nvarchar(30)') as [Manu],
    [tp_ColumnSet].value(N'/nvarchar11[1]', 'nvarchar(30)') as [Product],
    [tp_ColumnSet].value(N'/nvarchar12[1]', 'nvarchar(30)') as [Model],
    [tp_ColumnSet].value(N'/nvarchar13[1]', 'nvarchar(30)') as [Computername],
    [tp_ColumnSet].value(N'/ntext3[1]', 'nvarchar(255)') as [Description]

    FROM [WSS_Content].[dbo].[UserData]
    where tp_ListId = '852909F6-0AD6-4756-8EED-F8D9BE911E31' and [tp_ColumnSet].value(N'/nvarchar13[1]', 'nvarchar(30)') = '" + $computername + "' and [tp_ColumnSet].value(N'/nvarchar11[1]', 'nvarchar(30)') = 'Computer'"

    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = "Server=$dataSource;Database=$database;Integrated Security=True;"
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $query

    $result = $command.ExecuteReader()

    $SPtable = new-object "System.Data.DataTable"
    $SPtable.Load($result)

    $connection.Close()

    if ($sptable.Rows.Count -gt 0){

        #remove html tags      
        $Description = 
        $SPtable.rows[0].CallRef + " - "+
        $SPtable.rows[0].Department + " - "+
        $SPtable.rows[0].Description -replace '<[^>]+>','' -replace'&[^;]+;',' '   # Remove HTML stuff

        # Limit to 1023 chars just in case
        $Description = $Description.subString(0, [System.Math]::Min(1023, $Description.Length))

        # Set AD Description

        Set-ADComputer $Computername -Description $Description

        # Set PC description

        try {
            if (!$WhatIfPreference) {
                if(Test-Connection -Quiet -Count 1 -ComputerName $Computername){
                    $PCWMI = Get-WMIObject Win32_OperatingSystem -ComputerName $Computername
                    $PCWMI.Description = $Description
                    $PCWMI.Put()
                }
            }
        }
        catch {
            # Unable to set on device
        }
    
        $Message += "Updated "+ $Computername + " with: " + $Description + "<br>"
        
    } else {
        # Not in SP AssetDB
        #$Message += "Updated "+ $Computername + " with: NO ASSET DB RECORD" + "<br>"
    }
}

# ===================================================
# Report and email
# ===================================================

$Message += "===================================================<br>"
$Message += "DONE!<br>"

$Message

#Settings for Email Message
$rptDate = Get-date
if ($whatifpreference -eq 1) {$subjectprefix = "###TEST### " } else {$subjectprefix = "" } 

$messageParameters = @{ 
    Subject = "["+$subjectprefix+"Computer Description Updates on " + $rptDate.ToString($cultureENGB) + "]"
    Body = $Message
    From = "it.alerts@moorfields.nhs.uk" 
    #To = "moorfields.italerts@nhs.net"
    To = "sg@nhs.net"
    SmtpServer = "smtp.moorfields.nhs.uk"
    #SmtpServer = "127.0.0.1"
} 
#Send Report Email Message
Send-MailMessage @messageParameters -BodyAsHtml
