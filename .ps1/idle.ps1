# Function to get idle time in seconds
function Get-IdleTime {
    [System.Windows.Forms.Application]::IdleTime / 1000
}

# Define the idle threshold in seconds (5 seconds in this case)
$idleThreshold = 5

# Script to run when idle
$scriptToRun = {
    Write-Host "PowerShell is idle for $idleThreshold seconds. Running your script..."
    # Add your script code here that you want to run when idle
}

# Loop to monitor idle time and run the script when idle
while ($true) {
    $idleTime = Get-IdleTime

    if ($idleTime -ge $idleThreshold) {
        # Execute the script when idle
        Invoke-Command -ScriptBlock $scriptToRun
    }

    # Check idle time every second
    Start-Sleep -Seconds 1
}
