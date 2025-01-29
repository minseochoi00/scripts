# Function to check and request admin privileges
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# Relaunch as administrator if needed
if (-not (Test-Admin)) {
    Write-Host "This script requires administrative privileges. Restarting as Administrator..."
    Start-Process -FilePath "powershell" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Define Print Spooler paths
$PrintSpooler_PATH1 = "$env:SystemRoot\System32\spool\PRINTERS\*.*"
$PrintSpooler_PATH2 = "$env:SystemRoot\System32\spool\PRINTERS"

try {
    Write-Verbose "Stopping Print Spooler Service..."
    Stop-Service -Name "Spooler" -Force -Confirm:$false -ErrorAction Stop

    # Verify if spool directory exists and has files before attempting deletion
    if (Test-Path $PrintSpooler_PATH2) {
        if (Get-ChildItem -Path $PrintSpooler_PATH1 -ErrorAction SilentlyContinue) {
            Write-Verbose "Removing Print Spooler files..."
            Remove-Item -Path $PrintSpooler_PATH1 -Force -Confirm:$false -ErrorAction Stop
        } else {
            Write-Verbose "No files found in Print Spooler directory."
        }
    } else {
        Write-Host "Print Spooler directory does not exist: $PrintSpooler_PATH2"
    }

    Write-Verbose "Starting Print Spooler Service..."
    Start-Service -Name "Spooler" -Confirm:$false -ErrorAction Stop
    Write-Host "Print Spooler has been restarted successfully."

} catch {
    Write-Host "An error occurred: $_"
    Write-Host "Consider restarting your workstation and trying again."
}
