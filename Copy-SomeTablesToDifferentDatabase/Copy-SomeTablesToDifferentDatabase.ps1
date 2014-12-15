<#
.SYNOPSIS
Copies (bulk) the content of some tables into the same tables of a different Database

.DESCRIPTION
This runbook provides the possibility to copy the content of some tables in
a source database, into tables with the same name into a destination database

This runbook takes several mandatory arguments, a SourceServer, a SourceDatabase,
the SourceTables, a SourceUsername and SourcePassword to authenticate on the SourceDatabase,
as well as a DestinationServer, a DestinationDatabase, DestinationUsername and
DestinationPassword.

.PARAMETER Server
Name of the server

.PARAMETER SourceDatabase
Name of the source database

.PARAMETER DestinationDatabase
Name of the destination database

.PARAMETER Tables
Array with all names of the tables to copy

.PARAMETER Username
Username to access the server

.PARAMETER Password
Password to access the server

.EXAMPLE
Copy-SomeTablesToDifferentDatabase -Server 's' -SourceDatabase 'mothership' -DestinationDatabase 'cloneship' -Tables '["t1","t2"]' -Username 'usr' -Password 'pwd'

.NOTES
Author: Manuel Stuefer
Last Updated: 17th of November 2014
#>

workflow Copy-SomeTablesToDifferentDatabase {
    param (
        [parameter(Mandatory=$true)]  [String]$Server,
        [parameter(Mandatory=$true)]  [String]$SourceDatabase,
        [parameter(Mandatory=$true)]  [String]$DestinationDatabase,
        [parameter(Mandatory=$true)]  [String[]]$Tables,
        [parameter(Mandatory=$true)]  [String]$Username,
        [parameter(Mandatory=$true)]  [String]$Password
    )

    ForEach -Parallel ($Table in $Tables) {
        Write-Output "Starting with table: $Table"
        InlineScript {
            $SourceConnection = New-Object System.Data.SqlClient.SqlConnection("Server=tcp:$using:Server;Database=$using:SourceDatabase;User ID=$using:Username;Password=$using:Password;Trusted_Connection=False;Encrypt=True;Connection Timeout=30;")
            $DestinationConnectxion = New-Object System.Data.SqlClient.SqlConnection("Server=tcp:$using:Server;Database=$using:DestinationDatabase;User ID=$using:Username;Password=$using:Password;Trusted_Connection=False;Encrypt=True;Connection Timeout=30;")

            try {
                $SourceConnection.Open()
                $Command = New-Object System.Data.SqlClient.SqlCommand("SELECT * FROM $using:Table", $SourceConnection)
                $SourceDataTable = New-Object System.Data.DataTable
                $SourceDataTable.load($Command.ExecuteReader())
                $SourceConnection.Close()

                $DestinationConnection.Open()
                $bulkCopy = New-Object("Data.SqlClient.SqlBulkCopy") $DestinationConnection
                $bulkCopy.DestinationTableName = "$using:Table"
                $bulkCopy.BatchSize = 5000
                $bulkCopy.BulkCopyTimeout = 0
                $bulkCopy.WriteToServer($SourceDataTable)
                $DestinationConnection.Close()
            } catch {
                $ex = $_.Exception
                Write-Output "$ex.Message"
                continue
            }
        }
        Write-Output "Finished elaboration of table: $Table"
    }
}