# ENV
    # Create New Function 'Test-Admin'
        function Test-Admin {
            $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
            return $isAdmin
        }
    # Print Spooler PATH
        $PrintSpooler_PATH1 = "$env:SystemRoot\System32\spool\PRINTERS\*.*"
        $PrintSpooler_PATH2 = "$env:SystemRoot\System32\spool\PRINTERS"

# ------------------------------------------------------------------------------------------

# Check if the script is running as an administrator
if (-not (Test-Admin)) {
    Write-Host "This Code requires Administrative Privileges."
    Pause
    return
}

# Start

try {

    Write-Host "Stopping Print Spooler Service"
    if (Get-Service -Name Spooler) { Stop-Service -Name Spooler -Force }

    Write-Host "Removing Spool System Files"
    if (Test-Path $PrintSpooler_PATH2) { Remove-Item -Path $PrintSpooler_PATH1 -ErrorAction SilentlyContinue } 
    else { 
        Write-Output "$PrintSpooler_PATH" 
        Write-Output "Above PATH does not EXIST." 
    }

    Write-Host "Starting Print Spooler Service"
    Start-Service -Name Spooler
    
    Return

}

# End

# Error Prompt
catch {

    Write-Output "Error has occured while Fixing Print Spooler"
    Write-Output "Please 'RE-START' the workstation."
    pause
    Return

}