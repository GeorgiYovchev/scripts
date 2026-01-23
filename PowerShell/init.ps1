# Initial OS Configurations

NET USER Ansible [ANSIBLE USER PASSWORD] /ADD
NET LOCALGROUP "Administrators" "Ansible" /ADD
Set-LocalUser -Name "Ansible" -PasswordNeverExpires $true
Start-Service WinRM
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true
netsh advfirewall firewall add rule name="WinRM" dir=in action=allow protocol=TCP localport=5985
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

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
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Profile Any -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    Write-Log "Firewall rule created successfully."
} else {
    Write-Log "Firewall rule 'OpenSSH-Server-In-TCP' already exists."
}

Write-Log "OpenSSH installation and configuration completed successfully."

Write-Log "Adding persistent route for 10.1.8.0/24"
route -p add 10.1.8.0 mask 255.255.255.0 10.7.232.2
route -p add 10.254.254.0 mask 255.255.255.0 10.7.232.2
Write-Log "Persistent route added."