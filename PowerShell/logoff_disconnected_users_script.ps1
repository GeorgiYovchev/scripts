# This script queries current user sessions, checks for disconnected sessions,
# calculates idle time, and forcefully logs off sessions that have been disconnected for 60 minutes or more.
# Note: Running the "logoff" command requires administrative privileges.

# Function to convert the idle time string (as returned by quser) into total minutes.
function Convert-IdleTimeToMinutes {
    param(
        [string]$idleTimeString
    )

    # If the idle time is "none" or empty, assume 0 minutes.
    if ($idleTimeString -eq "none" -or [string]::IsNullOrWhiteSpace($idleTimeString)) {
        return 0
    }

    $totalMinutes = 0

    # If the idle time string contains a '+', it indicates days + time (e.g., "1+02:30" means 1 day, 2 hours, 30 minutes)
    if ($idleTimeString -match "\+") {
        $parts = $idleTimeString.Split('+')
        $days = [int]$parts[0]
        $timePart = $parts[1]
        $timeParts = $timePart.Split(':')
        $hours = [int]$timeParts[0]
        $minutes = [int]$timeParts[1]
        $totalMinutes = ($days * 24 * 60) + ($hours * 60) + $minutes
    }
    # If it’s in hh:mm format
    elseif ($idleTimeString -match ":") {
        $timeParts = $idleTimeString.Split(':')
        if ($timeParts.Count -eq 2) {
            $hours = [int]$timeParts[0]
            $minutes = [int]$timeParts[1]
            $totalMinutes = ($hours * 60) + $minutes
        }
        else {
            # Fallback: if the format isn’t as expected, assume minutes only.
            $totalMinutes = [int]$timeParts[0]
        }
    }
    else {
        # If the idle time is just a number, assume it represents minutes.
        $totalMinutes = [int]$idleTimeString
    }
    return $totalMinutes
}

# Retrieve session information using the 'quser' command.
# The command output includes a header line followed by one line per session.
$sessionOutput = quser 2>&1

# Split the output into separate lines.
$lines = $sessionOutput -split "`n"

# The first line is the header. Process subsequent lines for session data.
$sessionLines = $lines | Select-Object -Skip 1

foreach ($line in $sessionLines) {
    # Skip blank lines.
    if ([string]::IsNullOrWhiteSpace($line)) { continue }

    # Use regex to capture session details.
    # Expected columns: USERNAME, SESSIONNAME, ID, STATE, IDLE TIME, LOGON TIME
    if ($line -match "^\s*(\S+)\s+(\S+)?\s+(\d+)\s+(\S+)\s+(\S+)\s+(.*)$") {
        $username    = $matches[1]
        $sessionName = $matches[2]
        $sessionId   = $matches[3]
        $state       = $matches[4]
        $idleTime    = $matches[5]
        $logonTime   = $matches[6]

        # Check only sessions that are in a disconnected state ("Disc")
        if ($state -eq "Disc") {
            $idleMinutes = Convert-IdleTimeToMinutes -idleTimeString $idleTime

            # If idle time is 60 minutes or more, log off the session.
            if ($idleMinutes -ge 60) {
                Write-Output "Logging off session ID $sessionId (User: $username) which has been disconnected for $idleMinutes minutes."
                # Forcefully log off the session
                logoff $sessionId
            }
        }
    }
}
