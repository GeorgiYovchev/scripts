# Define the folder path and Slack webhook URLs
$folderPath = "F:\TransactionLogs"
$webhookUrl1 = "[WEBHOOK 1]"
$webhookUrl2 = "[WEBHOOK 2]"

# Get the current time
$currentTime = Get-Date

# Get the most recent file in the folder
$latestFile = Get-ChildItem -Path $folderPath | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Calculate the time difference between now and the latest file's modification time
if ($latestFile) {
    $timeDifference = $currentTime - $latestFile.LastWriteTime
    if ($timeDifference.TotalMinutes -ge 45) {
        # If no new files for 45 minutes, send an alert to Slack
        $message = @{
            text = "ALERT: No new transaction log files detected in the last 45 minutes in $folderPath."
        }
        $jsonMessage = $message | ConvertTo-Json
        Invoke-RestMethod -Uri $webhookUrl1 -Method Post -ContentType 'application/json' -Body $jsonMessage
        Invoke-RestMethod -Uri $webhookUrl2 -Method Post -ContentType 'application/json' -Body $jsonMessage
    }
} else {
    # If no files exist in the folder, send an alert
    $message = @{
        text = "Alert: No transaction log files found in $folderPath."
    }
    $jsonMessage = $message | ConvertTo-Json
    Invoke-RestMethod -Uri $webhookUrl1 -Method Post -ContentType 'application/json' -Body $jsonMessage
    Invoke-RestMethod -Uri $webhookUrl2 -Method Post -ContentType 'application/json' -Body $jsonMessage
}
