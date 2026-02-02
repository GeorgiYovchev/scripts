# === Time Drift Check Between Servers ===
# Hardcoded credentials for quick testing

$remoteServer = "[REMOTE SERVER IP]"
$username = "[ADMIN USER]"
$password = ConvertTo-SecureString "[ADMIN PASS]" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($username, $password)

try {
    Write-Host "Checking time synchronization between servers..." -ForegroundColor Cyan
    Write-Host "Local:  $env:COMPUTERNAME" -ForegroundColor Gray
    Write-Host "Remote: $remoteServer" -ForegroundColor Gray
    Write-Host ""
    
    # Get local time
    $localUtc = (Get-Date).ToUniversalTime()
    
    # Get remote time
    $remoteUtc = Invoke-Command `
      -ComputerName $remoteServer `
      -Credential $cred `
      -ScriptBlock { (Get-Date).ToUniversalTime() } `
      -ErrorAction Stop
    
    # Calculate difference
    $offsetSeconds = ($remoteUtc - $localUtc).TotalSeconds
    $offsetMinutes = [math]::Round($offsetSeconds / 60, 2)
    
    # Display results
    $result = [PSCustomObject]@{
        LocalServer  = $env:COMPUTERNAME
        RemoteServer = $remoteServer
        LocalUTC     = $localUtc.ToString("yyyy-MM-dd HH:mm:ss.fff")
        RemoteUTC    = $remoteUtc.ToString("yyyy-MM-dd HH:mm:ss.fff")
        OffsetSec    = [math]::Round($offsetSeconds, 3)
        OffsetMin    = $offsetMinutes
        Status       = if ([math]::Abs($offsetSeconds) -lt 5) { "OK" } 
                       elseif ([math]::Abs($offsetSeconds) -lt 30) { "Warning" } 
                       else { "Critical" }
    }
    
    $result | Format-List
    
    # Warning thresholds
    if ([math]::Abs($offsetSeconds) -gt 30) {
        Write-Host "WARNING: Time difference exceeds 30 seconds!" -ForegroundColor Red
        Write-Host "Action required: Sync NTP servers" -ForegroundColor Red
    } elseif ([math]::Abs($offsetSeconds) -gt 5) {
        Write-Host "Notice: Time difference exceeds 5 seconds" -ForegroundColor Yellow
        Write-Host "Consider checking NTP configuration" -ForegroundColor Yellow
    } else {
        Write-Host "Time synchronization is good (< 5 sec)" -ForegroundColor Green
    }
    
} catch {
    Write-Host "`nError connecting to remote server:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "`nTroubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Check if WinRM is enabled on $remoteServer" -ForegroundColor Gray
    Write-Host "2. Verify firewall allows port 5985 (HTTP) or 5986 (HTTPS)" -ForegroundColor Gray
    Write-Host "3. Test connection: Test-WSMan -ComputerName $remoteServer" -ForegroundColor Gray
    Write-Host "4. Verify credentials are correct" -ForegroundColor Gray
}