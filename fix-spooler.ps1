# Function to check if the script is running with administrative privileges
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    return $isAdmin
}

# Check if the script is running as an administrator
if (-not (Test-Admin)) {
    Write-Host "This script needs to be run as an administrator."
    Write-Host "Please relaunch the script with administrative privileges."
    Pause
    Exit
}

try {

    Write-Host "Stopping Print Spooler Service"
    Stop-Service -Name Spooler -Force

    Write-Host "Removing Spool System Files"
    Remove-Item -Path "$env:SystemRoot\System32\spool\PRINTERS\*.*"

    Write-Host "Starting Print Spooler Service"
    Start-Service -Name Spooler

    Pause
    Return

}

catch {

    Write-Host "Error has occured while Fixing Print Spooler"
    Pause
    Return
}