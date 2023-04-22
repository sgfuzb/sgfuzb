#Import modules
Import-Module failoverclusters

$SQLClustername = "SQL2-PROD"

$csvFilePath = "m:\powershell\sqlqueryresults.csv"

#num connections
$query = "
SELECT @@ServerName AS server
 ,NAME AS dbname
 ,COUNT(STATUS) AS number_of_connections
 ,GETDATE() AS timestamp
FROM sys.databases sd
LEFT JOIN sysprocesses sp ON sd.database_id = sp.dbid
WHERE database_id NOT BETWEEN 1 AND 4
GROUP BY NAME
" 

<#
$query = "
SELECT @@ServerName AS server, login_name [Login] , MAX(login_time) AS [Last Login Time]
FROM sys.dm_exec_sessions
GROUP BY login_name;
"
#>

$arrINST = Get-Clusterresource -Cluster $SQLClustername `
| Where-Object {$_.resourcetype -like 'sql server'} `
| Get-Clusterparameter "instancename" `
| Sort-Object objectname `
| Select-Object -expandproperty value

$arrVSN = Get-Clusterresource -Cluster $SQLClustername `
| Where-Object {$_.resourcetype -like 'sql server'} `
| Get-Clusterparameter "virtualservername" `
| Sort-Object objectname `
| Select-Object -expandproperty value

foreach ($i in 0..($arrINST.count-1)) {$instanceNameList += $arrVSN[$i] + "\" + $arrINST[$i]}

#$instanceNameList = get-content "m:\powershell\sqlqueryinstances.txt"
$result=@()
$SPtable = new-object "System.Data.DataTable"

foreach($instanceName in $instanceNameList)
{
        write-host "Executing query against server: " $instanceName
        $dataSource = $instanceName
        $database = "master"
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = "Server=$dataSource;Database=$database;Integrated Security=True;"
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        $result = $command.ExecuteReader()
        $SPtable.Load($result)
        $connection.Close()
}
 
write-host "Saving Query Results in CSV format..."
$SPtable | export-csv  $csvFilePath   -NoTypeInformation

# Convert CSV file to Excel
# Reference : <a href="http://gallery.technet.microsoft.com/scriptcenter/da4c725e-3487-42ff-862f-c022cf09c8fa">http://gallery.technet.microsoft.com/scriptcenter/da4c725e-3487-42ff-862f-c022cf09c8fa</a>

<#
write-host "Converting CSV output to Excel..."
 
$excel = New-Object -ComObject excel.application
$excel.visible = $False
$excel.displayalerts=$False
$workbook = $excel.Workbooks.Open($csvFilePath)
$workSheet = $workbook.worksheets.Item(1)
$resize = $workSheet.UsedRange
$resize.EntireColumn.AutoFit() | Out-Null
$xlExcel8 = 56
$workbook.SaveAs($excelFilePath,$xlExcel8)
$workbook.Close()
$excel.quit()
$excel = $null
 
write-host "Results are saved in Excel file: " $excelFilePath
#>