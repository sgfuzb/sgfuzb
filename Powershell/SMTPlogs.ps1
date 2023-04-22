
$path = "\\mehexhc1\d$\Program Files\Microsoft\Exchange Server\TransportRoles\Logs\ProtocolLog\SmtpReceive\RECV20190221-2.LOG"

# Create new DataTable to hold log entries
$tblLog = New-Object System.Data.DataTable "Log"
$arrUsers = New-Object System.Collections.ArrayList($null)
$bFirstRun = $TRUE;

foreach ($file in Get-ChildItem $path)
{
	# Get the contents of the file, excluding the first three lines.
	$fileContents = Get-Content $file.FullName | where {$_ -notLike "#[D,S-V]*" }

	# Create DataTable columns. No handling for different columns in
	# each log file.
	if( $bFirstRun )
	{
		$columns = (($fileContents[0].TrimEnd()) -replace "#Fields: ", "" -replace "-","" -replace "\(","" -replace "\)","").Split(" ")
		$colCount = $columns.Length

		# Create a DataColumn from the column string and add to our DataTable.
		foreach ($column in $columns)
		{
			$colNew = New-Object System.Data.DataColumn $column, ([string])
			$tblLog.Columns.Add( $colNew )
		}
		$bFirstRun = $FALSE;
		Write-Host "Columns complete"
	}


	# Get the row contents from the file, filtering what I want to retrieve.
	$rows = $fileContents | where {$_ -like "*MEHRPS01*"}

	# Loop through rows in the log file.
	foreach ($row in $rows)
	{
		if(!$row)
		{
			continue
		}

		$rowContents = $row.Split(" ")
		$newRow = $tblLog.newrow()
		for($i=0;$i -lt $colCount; $i++)
		{
			$columnName = $columns[$i]
			$newRow.$columnName = $rowContents[$i]
		}
		$tblLog.Rows.Add( $newRow )
	}
	Write-Host $file.Name "Done"
}
$tblLog | foreach {  if(! $arrUsers.Contains( $_.csusername ) ) { $arrUsers.Add( $_.csusername ) } }
$arrUsers
