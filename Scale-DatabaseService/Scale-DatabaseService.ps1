<#
.SYNOPSIS
Scales a Database to a desired Edition/ServiceObjectiveName

.DESCRIPTION
This runbook provides the possibility to set a Azure Database SQL Service to a
desired Edition/ServiceObjectiveName.

.PARAMETER Server
Name of the Server

.PARAMETER Database
Database Name to scale (has to be the same on each server)

.PARAMETER Edition
Name of the desired edition (Standard, Premium, ..)

.PARAMETER ServiceObjectiveName
Name of the desired serviceobjectivename

.PARAMETER Username

.PARAMETER Password

.EXAMPLE
Scale-DatabaseService -Server 's' -DatabaseName 'd1' -Editon 'Premium' -ServiceObjectiveName 'P1' -Username 'u' -Password 'p'

.NOTES
Author: Manuel Stuefer
Last Updated: 1st of December 2014
#>

workflow Scale-DatabaseService {
    param (
        [parameter(Mandatory=$true)]  [String]$Server="server.database.windows.net",
        [parameter(Mandatory=$true)]  [String]$DatabaseName="databasename",
        [parameter(Mandatory=$true)]  [String]$Edition="Premium",
        [parameter(Mandatory=$true)]  [String]$ServiceObjectiveName="P1",
        [parameter(Mandatory=$true)]  [String]$Username="username",
        [parameter(Mandatory=$true)]  [String]$Password="password"
    )

    Write-Output "Starting to scale service on Server $Server :: $DatabaseName"
    InlineScript {
        $SecStr = New-Object -TypeName System.Security.SecureString
        $pwd = $using:Password
        $pwd.ToCharArray() | ForEach-Object {$SecStr.AppendChar($_)}
        $Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $using:Username, $SecStr

        $Context = New-AzureSqlDatabaseServerContext -FullyQualifiedServerName $using:Server -Credential $Cred
        $Db = Get-AzureSqlDatabase $Context -DatabaseName $using:DatabaseName
        $ServiceObjective = Get-AzureSqlDatabaseServiceObjective $Context -ServiceObjectiveName $using:ServiceObjectiveName
        Set-AzureSqlDatabase $Context -Database $Db -ServiceObjective $ServiceObjective -Edition $using:Edition -Force
    }
    Write-Output "Done with scaling service on Server $Server :: $DatabaseName"
}