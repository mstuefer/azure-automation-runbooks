<#
.SYNOPSIS
Updates all statistics on some given Tables with Fullscan

.DESCRIPTION
This Runbook helps to rebuld all statistics on some given tables with the use of fullscan

.PARAMETER Server
Server Name

.PARAMETER DatabaseName
Database name

.PARAMETER Tables
Array with all names of the tables

.PARAMETER UserName
Name of the user

.PARAMETER Password
Password of the given user

.EXAMPLE
Update-AllStatisticsOnSeveralTablesWithFullscan -Server 's' -DatabaseName 'd' -Tables '["t1","t2"]' -UserName 'u' -Password -'pwd'

.NOTES
Author: Manuel Stuefer
Last Updated: 12th of January 2015
#>

workflow Update-AllStatisticsOnSeveralTablesWithFullscan {
    param(
        [parameter(Mandatory=$true)]  [String]$Server,
        [parameter(Mandatory=$true)]  [String]$DatabaseName,
        [parameter(Mandatory=$true)]  [String[]]$Tables,
        [parameter(Mandatory=$true)]  [String]$UserName,
        [parameter(Mandatory=$true)]  [String]$Password
    )

    ForEach -Parallel ($Table in $Tables) {
        InlineScript {
            $Query = "UPDATE STATISTICS $using:Table WITH FULLSCAN"
            Write-Output $Query
            $Connection = New-Object System.Data.SqlClient.SqlConnection("Server=tcp:$using:Server;Database=$using:DatabaseName;User ID=$using:UserName;Password=$using:Password;Trusted_Connection=False;Encrypt=True;")
            $Connection.Open()
            $Command = New-Object System.Data.SqlClient.SqlCommand($Query, $Connection)
            $Command.CommandTimeout = "120"
            [Void]$Command.ExecuteNonQueryAsync()
            $Connection.Close()
        }
    }

}