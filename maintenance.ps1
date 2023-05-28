# Settings
$osVersion = [System.Environment]::OSVersion.Version
$windows10Version = [System.Version]::Parse("10.0")
$windowsVersion1 = "22621.1778" # Change this to latest build 22H2 of Windows 11
$windowsVersion2 = "22000.2003" # Change this to latest build 21H2 of Windows 11

# Installing NuGet Package for Module Installation
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Installing Module for Checking Windows Update
Install-Module PSWindowsUpdate

# Start

# Delete Temporary Files for All Users
Write-Host "Removing Temporary Files"
Remove-Item -Path "$env:windir\Temp\*" -Recurse -Force -ErrorAction Ignore

# Flush Cache
Write-Host "Flushing IP Cache"
ipconfig /flushdns

# Empty Recycle Bin
Write-Host "Empty Recycle Bin"
Clear-RecycleBin -Force -ErrorAction Ignore

# Windows Update
Write-Host "Checking for Windows Update"

# Check for Windows updates (excluding drivers)
$updates = Get-WindowsUpdate -NotCategory "Drivers"

if ($updates.Count -gt 0) {
    Write-Host "Found $($updates.Count) Windows updates (excluding drivers)."
    Write-Host "Installing updates..."

    # Install updates
    $session = New-Object -ComObject "Microsoft.Update.Session"
    $downloader = $session.CreateUpdateDownloader()
    $downloader.Updates = $updates
    $downloader.Download()

    $installer = $session.CreateUpdateInstaller()
    $installer.Updates = $updates
    $installationResult = $installer.Install()

    # Check installation result
    if ($installationResult.ResultCode -eq 2) {
        Write-Host "Updates installed successfully."
    } else {
        Write-Host "Failed to install updates. Error code: $($installationResult.ResultCode)"
    }
} else {
    Write-Host "No Windows updates (excluding drivers) available."
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
if ($osVersion -lt $windows10Version) {
    Write-Host "This script requires Windows 10 or later."

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
}

# Run disk cleanup on Windows 10
if ($osVersion -lt $windows11Version) {
    Write-Host "Running disk cleanup on Windows 10..."

    $diskCleanupPath = "$env:SystemRoot\System32\cleanmgr.exe"
    $diskCleanupArgs = "/c /sageset:65535 /sagerun:65535"
    Start-Process -FilePath $diskCleanupPath -ArgumentList $diskCleanupArgs -Wait

} else {

# Run disk cleanup on Windows 11

    Write-Host "Running disk cleanup on Windows 11..."

    $diskCleanupPath = "C:\Windows\System32\cleanmgr.exe"
    $diskCleanupArgs = "/lowdisk /verylowdisk"
    Start-Process -FilePath $diskCleanupPath -ArgumentList $diskCleanupArgs -Wait
}

Write-Host "Disk cleanup completed."

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