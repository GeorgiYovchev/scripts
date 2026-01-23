# Define the base folder path
$baseFolder = "C:\FileStorage\DataExtract\172"

# Function to send notification to Slack (if needed for alerts)
function Send-SlackNotification {
    param (
        [string]$message
    )
    # Define your Slack webhook URLs here for alerts
    $slackWebhookUrls = @(
        "[WEBHOOK 1]",
        "[WEBHOOK 2]"
    )

    $payload = @{
        "text" = $message
    } | ConvertTo-Json

    # Send the notification to each Slack webhook URL
    foreach ($url in $slackWebhookUrls) {
        Invoke-RestMethod -Uri $url -Method Post -ContentType 'application/json' -Body $payload
    }
}

# Main function to check if the "yesterday_date_today's_date" folder exists and has files
function Check-YesterdayToTodayFolderExistsAndHasFiles {
    # Get yesterday's date and today's date in the format YYYY-MM-DD
    $yesterdayDate = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
    $todayDate = (Get-Date).ToString("yyyy-MM-dd")
    
    # Construct the folder name in the format "yesterday_date_today's_date"
    $dateRangeFolder = Join-Path -Path $baseFolder -ChildPath "$yesterdayDate`_$todayDate"
    
    # Check if the folder exists
    if (Test-Path -Path $dateRangeFolder) {
        # Check if there are any files in the folder
        $files = Get-ChildItem -Path $dateRangeFolder -File
        if ($files.Count -eq 0) {
            # Send a notification if the folder exists but is empty
            $message = "Alert: The folder '$dateRangeFolder' exists but contains no files."
            Send-SlackNotification -message $message
            Write-Output $message # Optional: output to console or logs for Task Scheduler
        } else {
            Write-Output "The folder '$dateRangeFolder' exists and contains $($files.Count) file(s)."
        }
    } else {
        # Send a notification if the folder does not exist
        $message = "Alert: The expected folder '$dateRangeFolder' does not exist."
        Send-SlackNotification -message $message
        Write-Output $message # Optional: output to console or logs for Task Scheduler
    }
}

# Run the check function
Check-YesterdayToTodayFolderExistsAndHasFiles
