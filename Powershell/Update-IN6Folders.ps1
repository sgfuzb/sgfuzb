#############################################################
# Update Imaganet6 Folders
# Steven Gill
# February 2023
#############################################################

<#
If need to install sqlserver module https://learn.microsoft.com/en-us/sql/powershell/download-sql-server-ps-module?view=sql-server-ver16
Install-Module -Name SqlServer
Import-Module SqlServer
#>

$IN6Folders = @()

# ===================================================
# Get IN6 Image Archive folders
# ===================================================

# sqlserver module version
# $query = "SELECT [StorageIndex], [Location] FROM [OCT].[dbo].[StoragePaths] WHERE StorageIndex >= 0 ORDER by StorageIndex"
# $DataTable = Invoke-Sqlcmd -Query $query -ServerInstance "imagenet6\imagenet6" -OutputAs DataTables

$dataSource = "imagenet6\imagenet6"
$database = "MEH"
$query = "SELECT [StorageIndex], [Location] FROM [OCT].[dbo].[StoragePaths] WHERE StorageIndex >= 0 ORDER by StorageIndex"

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = "Server=$dataSource;Database=$database;Integrated Security=True;"
$connection.Open()
$command = $connection.CreateCommand()
$command.CommandText = $query
$result = $command.ExecuteReader()
$DataTable = new-object "System.Data.DataTable"
$DataTable.Load($result)
$connection.Close()

Write-Host "Retrieved" $datatable.Rows.Count "Archive folders locations"
$ArchiveLocations = $DataTable.Location

# ===================================================
# Get IN6 Folders in Archives
# ===================================================

ForEach ($Location in $ArchiveLocations) {

    $Folders = Get-ChildItem -Path $Location | Where-Object { $_.PSIsContainer }

    ForEach ($Folder in $Folders){

        $DiskNumber = [int]( $Folder.Name -replace '\D', '')
        $Path = $Folder.FullName

        $IN6Folders += [PSCustomObject]@{
            DiskNumber = $DiskNumber
            Path = $Path
        }
    }
}

Write-Host $IN6Folders.Count "IN6 Folders Found"

#$IN6Folders | Out-GridView

# ===================================================
# Truncate SQL table
# ===================================================

$dataSource = "imagenet6\imagenet6"
$database = "MEH"
$query = "Truncate Table [MEH].[dbo].[IN6Folders]"

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = "Server=$dataSource;Database=$database;Integrated Security=True;"
$connection.Open()
$command = $connection.CreateCommand()
$command.CommandText = $query
$result = $command.ExecuteReader()
$connection.Close()

# ===================================================
# Update SQL table
# ===================================================

$dataSource = "imagenet6\imagenet6"
$database = "MEH"

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = "Server=$dataSource;Database=$database;Integrated Security=True;"
$connection.Open()
$command = $connection.CreateCommand()

ForEach($IN6Folder in $IN6Folders){
    $DiskNumber = $IN6Folder.DiskNumber
    $Path = $IN6Folder.Path
    $insertquery="
    INSERT INTO IN6Folders
        ([DiskNumber],[Path])
      VALUES
        ('$DiskNumber','$Path')"
    $Command.CommandText = $insertquery
    $result = $Command.ExecuteNonQuery()
}

$connection.Close()

# sqlserver module version
# $IN6Folders | Write-SqlTableData -ServerInstance "imagenet6\imagenet6" -DatabaseName "MEH" -SchemaName "dbo" -TableName "IN6Folders"
