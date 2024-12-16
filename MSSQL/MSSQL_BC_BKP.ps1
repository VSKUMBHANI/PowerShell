<# Tested with MSSQL 2022 Express.
# This PowerShell script will perform a full backup of all defined MSSQL databases to a BAK file.
# Use Task Scheduler to have this script run daily. The account you run this under will require the proper permission to perform backups in SQL server.
# Ref: https://github.com/sbirdsill/PowerShell-Backup-MSSQL-Databases/blob/master/Backup-MSSQL-Databases.ps1
# Retention policy: 
# Backups are performed daily, monthly and yearly and are kept in their respective folders under $TopLevelBackupPath. 
# Daily backups will be kept for 30 days. Monthly backups will be kept for 1 year. Yearly backups will be kept for 10 years.
#
# IMPORTANT: Parts that will need be modified for your environment are double commented (##). The rest can safely be left alone.

# For onetime backup run below command.
# Backup-SqlDatabase -ServerInstance "server\instance" -Database "DBNAME" -BackupFile "C:\SQLBackups\dbfile_$(Get-Date -UFormat %Y%m%d%H%M).bak"
#>

## Set SQL Server instance.
$sqlserver = "SERVER\INSTANCE"

## Set the database name(s)
$Databases = @("DBNAME1", "DBNAME2", "DBNAME3")

## Set backup path
$TopLevelBackupPath = "C:\SQLBackups"

# Define date parameters.
$timestamp = Get-Date -Format yyyy-MM-dd

# Get the current date
$Date = Get-Date

# Create backup folders and Readme file if they don't already exist
If (-not (Test-Path "$TopLevelBackupPath\Daily"))
{
	New-Item -Path $TopLevelBackupPath -Name "Daily" -ItemType "directory"
}
If (-not (Test-Path "$TopLevelBackupPath\Monthly"))
{
	New-Item -Path $TopLevelBackupPath -Name "Monthly" -ItemType "directory"
}
If (-not (Test-Path "$TopLevelBackupPath\Yearly"))
{
	New-Item -Path $TopLevelBackupPath -Name "Yearly" -ItemType "directory"
}
If (-not (Test-Path "$TopLevelBackupPath\Readme.txt"))
{
	New-Item -Path $TopLevelBackupPath -Name "Readme.txt" -ItemType "file" -Value "SQL backups will be kept in this folder. They are performed with Backup-MSSQL-Databases.ps1"
}

# Function to start the backup and cleanup process. 
Function Start-Backup
{
	
	# For the log: set n to 0 and get the runas user
	$n = 0
	$Username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
	
	# Start the log
	Start-Transcript -Path $BackupPath\MSSQL_Backup_Log_$timestamp.log -Append
	
	Write-Host "Backup-MSSQL-Databases.ps1, logged on to SQL Server [$sqlserver] as [$Username]."
	
	# Create backup folder.
	$n++
	Write-Host "[$n] Creating backup folder..."
	New-Item -Path "$BackupPath" -Name "$timestamp" -ItemType "directory" -Verbose
	Write-Host ""
	
	Foreach ($Database in $Databases)
	{
		
		# Start backing up SQL databases.
		$n++
		Write-Host "[$n] Backing up $Database..."
		SQLCMD.EXE -E -S $sqlserver -Q "BACKUP DATABASE $Database TO DISK='$BackupPath\$timestamp\$Database`_$timestamp.bak' WITH FORMAT"
		Write-Host ""
		
		# Verify backed up SQL databases.
		$n++
		Write-Host "[$n] Verifying $Database backup..."
		SQLCMD.EXE -E -S $sqlserver -Q "RESTORE VERIFYONLY FROM DISK = '$BackupPath\$timestamp\$Database`_$timestamp.bak'"
		Write-Host ""
	}
	
	# Delete files/folders older than specified time.
	$n++
	Write-Host "[$n] Removing old files/folders..."
	Get-ChildItem -Path $BackupPath -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force -Verbose
	Write-Host ""
	
	# Delete empty directories.
	$n++
	Get-ChildItem -Path $BackupPath -Recurse -Force | Where-Object { $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse -Verbose
	Write-Host "[$n] Backup complete."
	Write-Host ""
}

# Perform daily backup and delete files/folders older than 30 days (1 month).
Function Daily
{
	$BackupPath = "$TopLevelBackupPath\Daily"
	$limit = (Get-Date).AddDays(-30)
	Start-Backup
}

# Perform monthly backup and delete files/folders older than 365 days (1 year).
Function Monthly
{
	$Monthly = Get-Date -Day 01
	$limit = (Get-Date).AddDays(-365)
	if (($Date.Day -eq $Monthly.Day))
	{
		$BackupPath = "$TopLevelBackupPath\Monthly"
		Start-Backup
	}
}

# Perform yearly backup and delete files/folders older than 3650 days (10 years).
Function Yearly
{
	$Yearly = Get-Date -Day 01 -Month 01
	$limit = (Get-Date).AddDays(-3650)
	if (($Date.Day -eq $Yearly.Day) -and ($Date.Month -eq $Yearly.Month))
	{
		$BackupPath = "$TopLevelBackupPath\Yearly"
		Start-Backup
	}
}

Daily
#Monthly
#Yearly

# End logging and exit
Write-Host "Exiting..."
Stop-Transcript
exit
