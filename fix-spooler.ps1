# ENV
    # Create New Function 'Test-Admin'
    function Test-Admin {
        $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
        return $isAdmin
    }

    $PrintSpooler_PATH = "$env:SystemRoot\System32\spool\PRINTERS\*.*"

# ------------------------------------------------------------------------------------------
# Check if the script is running as an administrator
if (-not (Test-Admin)) {
    Write-Host "This script needs to be run as an administrator."
    Write-Host "Please relaunch the script with administrative privileges."
    Pause
    return
    Exit
}

# Start
try {

    Write-Host "Stopping Print Spooler Service"
    Stop-Service -Name Spooler -Force

    Write-Host "Removing Spool System Files"
    if (Test-Path $PrintSpooler_PATH) { Remove-Item -Path $PrintSpooler_PATH -ErrorAction Ignore } else { Write-Output "PATH does not EXIST." }

    Write-Host "Starting Print Spooler Service"
    Start-Service -Name Spooler

    Pause
    Return

}
# End

# Error Prompt
catch {

    Write-Host "Error has occured while Fixing Print Spooler"
    Pause
    Return

}