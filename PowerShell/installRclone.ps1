# Set target install path
$installPath = "C:\Tools\rclone"
$zipPath = "$env:TEMP\rclone.zip"
$url = "https://downloads.rclone.org/rclone-current-windows-amd64.zip"

# Create install directory if it doesn't exist
if (-not (Test-Path $installPath)) {
    New-Item -ItemType Directory -Path $installPath | Out-Null
}

# Download the zip file
Invoke-WebRequest -Uri $url -OutFile $zipPath

# Extract the rclone.exe
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $installPath)

# Find rclone.exe in the extracted folder
$rcloneExe = Get-ChildItem -Path $installPath -Recurse -Filter rclone.exe | Select-Object -First 1

# Move rclone.exe to main install path (if not already there)
if ($rcloneExe.FullName -ne "$installPath\rclone.exe") {
    Move-Item -Path $rcloneExe.FullName -Destination "$installPath\rclone.exe" -Force
}

# Optional: Add to system PATH
$existingPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if ($existingPath -notlike "*$installPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$existingPath;$installPath", [EnvironmentVariableTarget]::Machine)
    Write-Host "Added $installPath to system PATH. You may need to restart your shell."
}

# Clean up
Remove-Item $zipPath -Force

# Confirm
Write-Host "rclone installed successfully at $installPath"
& "$installPath\rclone.exe" version
