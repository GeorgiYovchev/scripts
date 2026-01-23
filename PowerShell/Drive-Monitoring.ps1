# Define the network drive letter and Slack webhook URLs
$driveLetter = "Z:"
$slackWebhookURL1 = [WEBHOOK 1]
$slackWebhookURL2 = [WEBHOOK 2]

# Check if the drive exists
if (!(Test-Path $driveLetter)) {
    # Send an alert to Slack
    $payload = @{
        text = "Alert: Network drive $driveLetter is unavailable on $(hostname) (10.7.224.13)"
    }
    $jsonPayload = $payload | ConvertTo-Json
    Invoke-RestMethod -Uri $slackWebhookURL1 -Method Post -Body $jsonPayload
    Invoke-RestMethod -Uri $slackWebhookURL2 -Method Post -Body $jsonPayload
	echo "$(Get-Date) $payload" >> log
}
else {
echo "$(Get-Date) 'All Fine'" >> log
}
