# Function to check if the current user has administrative privileges
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    return $isAdmin
}

# Environment variables for Print Spooler paths
$PrintSpooler_PATH1 = "$env:SystemRoot\System32\spool\PRINTERS\*.*"
$PrintSpooler_PATH2 = "$env:SystemRoot\System32\spool\PRINTERS"

# Main script execution
if (-not (Test-Admin)) {
    Write-Host "This script requires Administrative privileges."
    Pause
    return
}

try {
    # Stopping the Print Spooler service
    Write-Host "Stopping Print Spooler Service..."
    Stop-Service -Name "Spooler" -Force -ErrorAction Stop

    # Removing printer spool files
    Write-Host "Removing Spool System Files..."
    if (Test-Path $PrintSpooler_PATH2) {
        Remove-Item -Path $PrintSpooler_PATH1 -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "Path does not exist: $PrintSpooler_PATH2"
    }

    # Starting the Print Spooler service
    Write-Host "Starting Print Spooler Service..."
    Start-Service -Name "Spooler"

} catch {
    Write-Host "An error has occurred while managing the Print Spooler."
    Write-Host "Please restart the workstation and try again."
    Pause
}