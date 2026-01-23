# Define how old files must be to be deleted (in days)
$daysOld = 15

# Set the cutoff date
$cutoffDate = (Get-Date).AddDays(-$daysOld)

# Define the target folder
$targetFolder = "C:\ProgramData\UltraPlay"

# Get all files older than the cutoff date, recursively
$oldFiles = Get-ChildItem -Path $targetFolder -Recurse -File | Where-Object {
    $_.LastWriteTime -lt $cutoffDate
}

# Delete the old files
foreach ($file in $oldFiles) {
    try {
        Write-Output "Deleting: $($file.FullName)"
        Remove-Item -Path $file.FullName -Force
    } catch {
        Write-Warning "Failed to delete $($file.FullName): $_"
    }
}
