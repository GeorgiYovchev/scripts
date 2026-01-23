# Backup folder path
$backupFolder = "F:\Backup"

# Get the latest .bak file by LastWriteTime
$latestBackup = Get-ChildItem -Path $backupFolder -Filter *.bak | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

# Check if a backup file was found
if (-not $latestBackup) {
    $today = Get-Date -Format "yyyy-MM-dd"
    $message = "No .bak files found in the directory '$backupFolder' for $today."

    Write-Host $message -ForegroundColor Red

    # Log to Windows Event Viewer
    Write-EventLog -LogName Application `
                   -Source "MSSQLBackupScript" `
                   -EventID 1001 `
                   -EntryType Error `
                   -Message $message

    exit 1
}

# Full path to the latest backup file
$backupFilePath = $latestBackup.FullName

# Upload to IONOS using rclone
try {
    rclone copy "$backupFilePath" "ionos:oddstech-backup/prod-mssql" `
        --s3-disable-checksum `
        --s3-chunk-size 5M `
        --s3-upload-concurrency 1 `

    # log success
    $message = "Backup uploaded successfully: $($latestBackup.Name)"
    Write-Host $message -ForegroundColor Green

    Write-EventLog -LogName Application `
                   -Source "MSSQLBackupScript" `
                   -EventID 1000 `
                   -EntryType Information `
                   -Message $message
}
catch {
    $errorMsg = "rclone upload failed: $($_.Exception.Message)"
    Write-Host $errorMsg -ForegroundColor Red

    Write-EventLog -LogName Application `
                   -Source "MSSQLBackupScript" `
                   -EventID 1002 `
                   -EntryType Error `
                   -Message $errorMsg

    exit 1
}
