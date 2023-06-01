# Settings
# Installing NuGet Package for Module Installation
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Installing Module for Checking Windows Update
Install-Module PSWindowsUpdate -Force

# Start

# Delete Temporary Files for All Users
Write-Host "Removing Temporary Files"
Get-ChildItem -Path "$env:windir\Temp\" *.* -Recurse | Remove-Item -Force -Recurse
Get-ChildItem -Path $env:TEMP *.* -Recurse | Remove-Item -Force -Recurse

# Flush Cache
Write-Host "Flushing IP Cache"
ipconfig /flushdns

# Empty Recycle Bin
Write-Host "Empty Recycle Bin"
Clear-RecycleBin -Force -ErrorAction Ignore

# Windows Update
Write-Host "Checking for Windows Update"

# Check for Windows updates (excluding drivers)
Get-WindowsUpdate -NotCategory "Drivers"

# Cleanup Print Queue & Delete Old Print Jobs
Write-Host "Cleaning up Print Queue"
Get-Printer | ForEach-Object {
    Get-PrintJob -PrinterName $_.Name | Remove-PrintJob
}
Get-WmiObject -Query "SELECT * FROM Win32_PrintJob" | ForEach-Object {
    $_.Delete()
}

# Resync Time
Write-Host "Resyncing Time"
w32tm /resync /nowait /rediscover

# Clear Temporary Internet Files Only
Write-Host "Clearing Temporary Internet Files"
Clear-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Force -ErrorAction Ignore

# Running Disk Cleanup
Write-Host "Starting Disk Cleanup"
cleanmgr.exe /d C: /VERYLOWDISK

# Prompt user to reboot
$rebootChoice = Read-Host -Prompt "Cleanup completed. Do you want to reboot now? (Y/N)"
if ($rebootChoice.ToUpper() -eq "Y") {
    Restart-Computer -Force
} elseif ($rebootChoice.ToUpper() -eq "Yes") {
    Restart-Computer -Force
} elseif ($rebootChoice.ToUpper() -eq "yes") {
    Restart-Computer -Force
} else {
    Write-Host "You can manually reboot your computer later at your convenience."
    Pause
    Exit
}

# End