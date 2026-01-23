# Define the network drive letter, test folder, and Slack webhook URL
$driveLetter = "Z:"
$testFolder = "$driveLetter\TestDriveCheck"
$slackWebhookURL = [YOUR WEBHOOK HERE]

try {
    # Try to create the test folder
    if (!(Test-Path $testFolder)) {
        New-Item -ItemType Directory -Path $testFolder -Force | Out-Null
    }

    # Remove the test folder
    Remove-Item -Path $testFolder -Force

} catch {
    # If there's an error, send an alert to Slack
    $errorMessage = $_.Exception.Message
    
    # Send alert to Slack
    $payload = @{
        text = "Alert: Network drive $driveLetter is unavailable or read-only on $(hostname) (10.7.224.13) - $errorMessage"
    }
    Invoke-RestMethod -Uri $slackWebhookURL -Method Post -Body (ConvertTo-Json $payload)
}
