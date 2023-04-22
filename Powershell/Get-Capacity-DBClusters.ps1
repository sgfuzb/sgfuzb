
$output = @()

#$Clusters = Get-Cluster -Domain moorfields.nhs.uk
$Clusters = 
"MEH-SQL-PROD", "MEH-SQL-TESTDEV",
"MEH-SQL2-PROD", "MEH-SQL2-TESTDEV",
"MEH-ORA19-PROD", "MEH-ORA19-TESTDEV"

#"MEH-ORA-PROD", "MEH-ORA-TESTDEV", # old

#$Clusters = "MEH-ORA19-PROD"

Foreach($cluster in $Clusters) {

    # $Clust = Get-Cluster -Name $cluster
    #$Nodes = Get-ClusterNode -Cluster $cluster
    $Resources = Get-ClusterResource -Cluster $cluster

    # CSVs
    #$CSVs = Get-ClusterSharedVolume -Cluster $cluster
    #$CSVsState = Get-ClusterSharedVolumeState -Cluster $cluster
    #$csvs[0].SharedVolumeInfo.partition.Size
    #$csvs[0].SharedVolumeInfo.partition.UsedSpace

    $output += [PSCustomObject]@{
        ClusterName = $cluster
        NumDBs = ($Resources | Where-Object {($_.ResourceType -eq "SQL Server") -or ($_.ResourceType -eq "Oracle Database")}).Count
    }
}

$output | Out-GridView
