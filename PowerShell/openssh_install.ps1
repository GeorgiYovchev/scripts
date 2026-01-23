# Define logging function
Function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "$Timestamp [$Level] $Message"
}

# Check OpenSSH Capabilities
Write-Log "Checking OpenSSH installation status..."
$openSSHClient = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'
$openSSHServer = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

# Install OpenSSH Client if not installed
if ($openSSHClient.State -ne 'Installed') {
    Write-Log "Installing OpenSSH Client..."
    Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
} else {
    Write-Log "OpenSSH Client is already installed."
}

# Install OpenSSH Server if not installed
if ($openSSHServer.State -ne 'Installed') {
    Write-Log "Installing OpenSSH Server..."
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
} else {
    Write-Log "OpenSSH Server is already installed."
}

# Start the sshd service
Write-Log "Starting sshd service..."
$sshdService = Get-Service -Name sshd -ErrorAction SilentlyContinue
if ($sshdService -and $sshdService.Status -ne 'Running') {
    Start-Service sshd
    Write-Log "sshd service started successfully."
} elseif ($sshdService -and $sshdService.Status -eq 'Running') {
    Write-Log "sshd service is already running."
} else {
    Write-Log "sshd service not found. Ensure OpenSSH Server is installed correctly." "ERROR"
}

# Set sshd to start automatically
Write-Log "Configuring sshd service to start automatically..."
Set-Service -Name sshd -StartupType 'Automatic'

# Verify Firewall Rule
Write-Log "Checking OpenSSH firewall rule..."
$firewallRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue

if (!$firewallRule) {
    Write-Log "Firewall rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    Write-Log "Firewall rule created successfully."
} else {
    Write-Log "Firewall rule 'OpenSSH-Server-In-TCP' already exists."
}

# Display completion message

Write-Log "OpenSSH installation and configuration completed successfully."
