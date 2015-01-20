<#
.SYNOPSIS
Rebuilds fragmented indexes

.DESCRIPTION
This Runbook helps to rebuild (online) all indexes on Azure SQL on which a given Fragmentation is reached

.PARAMETER Server
Server Name

.PARAMETER DatabaseName
Database Name

.PARAMETER UserName
Name of the user

.PARAMETER Password
Password of the given user

.PARAMETER AcceptedAverageFragmentation
We will only rebuild all indexes with a fragmentation higher than this value

.PARAMETER MaxQueryTime
The maximal time (in seconds) we accept per each query

.EXAMPLE
Rebuild-FragmentedIndexes -Server 's' -DatabaseName 'd' -UserName 'u' -Password 'pwd' -AcceptedAverageFragmentation 10 -MaxQueryTime 1500

.NOTES
Author: Manuel Stuefer
Last Updated: 2nd of December 2014
#>

workflow Rebuild-FragmentedIndexes {
    param(
        [parameter(Mandatory=$true)]  [String]$Server="server.database.windows.net",
        [parameter(Mandatory=$true)]  [String]$DatabaseName="databasename",
        [parameter(Mandatory=$true)]  [String]$UserName="username",
        [parameter(Mandatory=$true)]  [String]$Password,
        [parameter(Mandatory=$true)]  [int]$AcceptedAverageFragmentation=10,
        [parameter(Mandatory=$true)]  [int]$MaxQueryTime=1500
    )

    $FragmentedIndexes = InlineScript {
        $Query = "SELECT TABLE_SCHEMA AS SchemaName, OBJECT_NAME(F.OBJECT_ID) as TableName, I.NAME AS IndexName, F.AVG_FRAGMENTATION_IN_PERCENT AS AverageFragmentationInPercent FROM SYS.DM_DB_INDEX_PHYSICAL_STATS(DB_ID(),NULL,NULL,NULL,NULL) F JOIN SYS.INDEXES I ON(F.OBJECT_ID=I.OBJECT_ID) AND I.INDEX_ID=F.INDEX_ID JOIN INFORMATION_SCHEMA.TABLES S ON (S.TABLE_NAME=OBJECT_NAME(F.OBJECT_ID)) WHERE F.DATABASE_ID = DB_ID() AND F.AVG_FRAGMENTATION_IN_PERCENT > $using:AcceptedAverageFragmentation AND OBJECTPROPERTY(I.OBJECT_ID, 'ISSYSTEMTABLE') = 0 ORDER BY SchemaName, TableName, IndexName;"
        $Connection = New-Object System.Data.SqlClient.SqlConnection("Server=tcp:$using:Server;Database=$using:DatabaseName;User ID=$using:UserName;Password=$using:Password;Trusted_Connection=False;Encrypt=True;")
        $Connection.Open()
        $Command = New-Object System.Data.SqlClient.SqlCommand($Query, $Connection)
        $Command.CommandTimeout = "$using:MaxQueryTime"
        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter($Command)
        $DataSet = New-Object System.Data.DataSet
        [void]$SqlAdapter.fill($DataSet)
        $DataSet.Tables[0].Rows
        $Connection.Close()
    }

    Write-Output $FragmentedIndexes.Count
    foreach($FragmentedIndex in $FragmentedIndexes) {
        InlineScript {
            $Row = $using:FragmentedIndex
            $Query = "ALTER INDEX "+$Row.IndexName+" ON "+$Row.SchemaName+"."+$Row.TableName+" REBUILD WITH (ONLINE=ON (WAIT_AT_LOW_PRIORITY (MAX_DURATION=$using:MaxQueryTime SECONDS, ABORT_AFTER_WAIT=SELF)))"
            Write-Output $Query
            $Connection = New-Object System.Data.SqlClient.SqlConnection("Server=tcp:$using:Server;Database=$using:DatabaseName;User ID=$using:UserName;Password=$using:Password;Trusted_Connection=False;Encrypt=True;")
            $Connection.Open()
            $Command = New-Object System.Data.SqlClient.SqlCommand($Query, $Connection)
            $Command.CommandTimeout = $using:MaxQueryTime
            [void]$Command.ExecuteNonQuery()
            $Connection.Close()
        }
        Checkpoint-Workflow
    }
}