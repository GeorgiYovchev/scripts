# Define the services to monitor
$services = @("SERVICE 1", "SERVICE 2")

# Define Slack Webhooks
$slackWebhooks = @(
    "WEBHOOK"
)

# Function to send Slack notification
function Send-SlackNotification {
    param (
        [string]$WebhookUrl,
        [string]$Message
    )
    $payload = @{
        text = $Message
    } | ConvertTo-Json -Depth 2
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $payload -ContentType 'application/json'
}

# Check the status of each service
foreach ($service in $services) {
    $serviceStatus = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($null -eq $serviceStatus) {
        # Service not found
        $message = "Service '$service' does not exist on Services Node 1 Server (10.7.224.22) OddsTech PROD."
        foreach ($webhook in $slackWebhooks) {
            Send-SlackNotification -WebhookUrl $webhook -Message $message
        }
    } elseif ($serviceStatus.Status -ne 'Running') {
        # Service is not running
        $message = "Service '$service' is not running on Services Node 1 Server (10.7.224.22) OddsTech PROD. Current status: $($serviceStatus.Status)"
        # Send a notification to each Slack webhook
        foreach ($webhook in $slackWebhooks) {
            Send-SlackNotification -WebhookUrl $webhook -Message $message
        }
    }
}
