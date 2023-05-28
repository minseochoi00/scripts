# Delete Temporary Files for All Users
Remove-Item -Path "$env:windir\Temp\*" -Recurse -Force

# Run Windows Cleanup
$cleanupOptions = New-Object -ComObject Shell.Application
$cleanupOptions.CleanupTemporaryFiles()

# Flush Cache
ipconfig /flushdns

# Empty Recycle Bin
Clear-RecycleBin -Force

# Windows Update
$windowsUpdateSession = New-Object -ComObject Microsoft.Update.Session
$windowsUpdateSearcher = $windowsUpdateSession.CreateUpdateSearcher()
$windowsUpdateInstaller = New-Object -ComObject Microsoft.Update.Installer
$updates = $windowsUpdateSearcher.Search("IsInstalled=0")
$updates | ForEach-Object {
    $windowsUpdateInstaller.Install($_.IsUpdate)
}

# Cleanup Print Queue
Get-Printer | ForEach-Object {
    Get-PrintJob -PrinterName $_.Name | Remove-PrintJob
}

# Resync Time
w32tm /resync /nowait /rediscover

# Clear Temporary Internet Files Only
Clear-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Force -Recurse

# Delete Old Print Jobs
Get-WmiObject -Query "SELECT * FROM Win32_PrintJob" | ForEach-Object {
    $_.Delete()
}

# Clean up C Drive
$cleanupOptions = New-Object -ComObject Shell.Application
$cleanupOptions.Namespace(0x11).ParseName("C:").InvokeVerb("EmptyRecycleBin")

# Run full disk cleanup unattended
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