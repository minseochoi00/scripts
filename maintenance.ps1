# Delete Temporary Files for All Users
Write-Host "Removing Temporary Files"
Remove-Item -Path "$env:windir\Temp\*" -Recurse -Force -ErrorAction Ignore

# Run Windows Cleanup
Write-Host "Running Windows Clean-Up"
$cleanupOptions = New-Object -ComObject Shell.Application
$cleanupOptions.CleanupTemporaryFiles()

# Flush Cache
Write-Host "Flushing IP Cache"
ipconfig /flushdns

# Empty Recycle Bin
Write-Host "Empty Recycle Bin"
Clear-RecycleBin -Force -ErrorAction Ignore

# Windows Update
Write-Host "Checking for Windows Update"
$windowsUpdateSession = New-Object -ComObject Microsoft.Update.Session
$windowsUpdateSearcher = $windowsUpdateSession.CreateUpdateSearcher()
$windowsUpdateInstaller = New-Object -ComObject Microsoft.Update.Installer
$updates = $windowsUpdateSearcher.Search("IsInstalled=0")
$updates | ForEach-Object {
    $windowsUpdateInstaller.Install($_.IsUpdate)
}

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
Clear-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Force -Recurse

# Clean up C Drive
Write-Host "Cleaning Up C Drive"
$cleanupOptions = New-Object -ComObject Shell.Application
$cleanupOptions.Namespace(0x11).ParseName("C:").InvokeVerb("EmptyRecycleBin")

# Run full disk cleanup unattended
Write-Host "Running Full Disk Cleanup - Unattended"
$cleanupOptions.Namespace(0x11).ParseName("C:").InvokeVerb("FullDiskCleanUp")

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
}