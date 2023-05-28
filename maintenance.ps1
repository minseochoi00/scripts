
# Check for and install Windows updates
Write-Host "Checking for Windows updates..."
$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
$Updates = $UpdateSearcher.Search("IsInstalled=0")
if ($Updates.Updates.Count -gt 0) {
    Write-Host "Found $($Updates.Updates.Count) update(s). Installing updates..."
    $Installer = $UpdateSession.CreateUpdateInstaller()
    $Installer.Updates = $Updates.Updates
    $Installer.Install()
    $Results = $Installer.GetInstallResult()
    if ($Results.ResultCode -eq 2) {
        Write-Host "Updates installed successfully."
    } else {
        Write-Host "Failed to install updates. Result code: $($Results.ResultCode)"
    }
} else {
    Write-Host "No updates found."
}

# Clean up temporary files
Write-Host "Cleaning up temporary files..."
Remove-Item -Path "$env:TEMP\*" -Force -Recurse
Remove-Item -Path "$env:SystemRoot\Temp\*" -Force -Recurse

# Clear event logs
Write-Host "Clearing event logs..."
Get-WinEvent -ListLog * | ForEach-Object {
    $logName = $_.LogName
    if ($logName -ne "Security") {
        Write-Host "Clearing $logName..."
        Clear-EventLog -LogName $logName
    }
}

# Optimize the hard drive (defragmentation)
Write-Host "Optimizing hard drive..."
Optimize-Volume -DriveLetter "C" -Defrag -Verbose

# Restart the computer (optional)
$RestartNeeded = $Updates.Updates | Where-Object { $_.IsInstalled -eq $false }
if ($RestartNeeded) {
    Write-Host "A restart is required to complete the installation of updates. Restarting..."
    Restart-Computer -Force
}
