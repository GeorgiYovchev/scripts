# Define the base folder path
$baseFolder = "C:\FileStorage\DataExtract\172"
# Define the time threshold of 1 hour and 15 minutes
$timeThreshold = (New-TimeSpan -Hours 1 -Minutes 15)

# Function to send notification to Slack
function Send-SlackNotification {
    param (
        [string]$message
    )
    # Define your Slack webhook URLs here for alerts
    $slackWebhookUrls = @(
        "WEBHOOK 1",
        "WEBHOOK 2"
    )

    $payload = @{
        "text" = $message
    } | ConvertTo-Json

    # Send the notification to each Slack webhook URL
    foreach ($url in $slackWebhookUrls) {
        Invoke-RestMethod -Uri $url -Method Post -ContentType 'application/json' -Body $payload
    }
}

# Main function to check if the last added file is older than the threshold
function Check-LastAddedFileOlderThanThreshold {
    # Get today's date in the format YYYY-MM-DD
    $currentDateFolder = Join-Path -Path $baseFolder -ChildPath (Get-Date).ToString("yyyy-MM-dd")
    
    # Check if the current date folder exists
    if (Test-Path -Path $currentDateFolder) {
        # Get all files in the folder and sort by LastWriteTime in descending order (newest first)
        $latestFile = Get-ChildItem -Path $currentDateFolder -File | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

        if ($latestFile) {
            # Calculate the age of the latest file
            $currentTime = Get-Date
            $fileAge = $currentTime - $latestFile.LastWriteTime
            if ($fileAge -gt $timeThreshold) {
                # Send a Slack notification if the last added file is older than the threshold
                $message = "ALERT: The most recent file '$($latestFile.Name)' in folder '$currentDateFolder' is older than 1 hour and 15 minutes."
                Send-SlackNotification -message $message
                Write-Output $message # Optional: output to console or logs for Task Scheduler
            } else {
                Write-Output "The most recent file '$($latestFile.Name)' is within the acceptable age limit."
            }
        } else {
            Write-Output "No files found in the current date folder: $currentDateFolder"
        }
    } else {
        Write-Output "No folder found for the current date: $currentDateFolder"
    }
}

# Run the check function
Check-LastAddedFileOlderThanThreshold
