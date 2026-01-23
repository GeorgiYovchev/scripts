param (
    [string]$Message,
    [string]$Server = $ENV:COMPUTERNAME,  # Automatically uses the current hostname if not specified
    [string]$JobName
)

# Construct the detailed message for Slack with bold formatting for the values of Server and Job
$DetailedMessage = "$Message`nServer: *$Server*`nJob: *$JobName*"

# Your Slack webhook URLs
$webhookUrl1 = "WEBHOOK 1"
$webhookUrl2 = "WEBHOOK 2"

# Prepare the JSON payload for Slack
$payload = @{
    text = $DetailedMessage
} | ConvertTo-Json

# Send the message to Slack via both webhooks
Invoke-RestMethod -Uri $webhookUrl1 -Method Post -ContentType "application/json" -Body $payload
Invoke-RestMethod -Uri $webhookUrl2 -Method Post -ContentType "application/json" -Body $payload
