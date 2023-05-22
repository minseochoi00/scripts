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