# Define paths and date formats
$logRoot = "C:\inetpub\logs\LogFiles"
$archiveRoot = "C:\ArchivedIISLogs"
$yesterday = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
$yesterdayDate = (Get-Date).AddDays(-1)

# Ensure archive directory exists
if (-not (Test-Path $archiveRoot)) {
    New-Item -Path $archiveRoot -ItemType Directory -Force
}

# Create zip file name
$zipFileName = "$archiveRoot\IISLogs-$yesterday.zip"

# Collect all log files from the previous day
$logFiles = Get-ChildItem -Path $logRoot -Recurse -Include *.log | Where-Object {
    ($_.LastWriteTime.Date -eq $yesterdayDate.Date)
}

if ($logFiles.Count -gt 0) {
    # Create temporary folder to collect files
    $tempDir = Join-Path -Path $env:TEMP -ChildPath "IISLogs_$($yesterdayDate.ToString('yyyyMMdd'))"
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    # Copy the logs
    foreach ($file in $logFiles) {
        $relativePath = $file.DirectoryName.Replace($logRoot, "").TrimStart('\')
        $destDir = Join-Path $tempDir $relativePath
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item $file.FullName -Destination $destDir
    }

    # Compress to zip
    Compress-Archive -Path "$tempDir\*" -DestinationPath $zipFileName -Force

    # Remove temp folder
    Remove-Item -Path $tempDir -Recurse -Force
}

# DELETE original logs older than 7 days
Get-ChildItem -Path $logRoot -Recurse -Include *.log | Where-Object {
    $_.LastWriteTime -lt (Get-Date).AddDays(-7)
} | Remove-Item -Force -ErrorAction SilentlyContinue

# DELETE zip archives older than 7 days
Get-ChildItem -Path $archiveRoot -Filter *.zip | Where-Object {
    $_.LastWriteTime -lt (Get-Date).AddDays(-7)
} | Remove-Item -Force -ErrorAction SilentlyContinue
