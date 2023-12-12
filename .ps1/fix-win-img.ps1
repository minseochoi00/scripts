# PowerShell Script for Windows Maintenance and Image Restore

# Ensure the script is running with administrative privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
  Write-Warning "Please run this script as an Administrator!"
  Break
}

# Section 1: Windows System Image Restore (Modify as needed)
# Note: This is just a placeholder. Actual commands depend on your backup method.
Function Fix-SystemImage {
  dism /online /english /cleanup-image /restorehealth
  dism /cleanup-mountpoints
}

# Section 2: Disk Cleanup
Function Start-DiskCleanup {
    cleanmgr /sagerun:1
}

# Section 3: Windows Update
Function Install-WindowsUpdates {
    # Requires PSWindowsUpdate module
   try {
      Import-Module PSWindowsUpdate
   } catch {
      Install-Module -Name PSWindowsUpdate -Force
   }
   Get-WindowsUpdate | Out-Null
   Install-WindowsUpdate -AcceptAll -AutoReboot
}

# Section 4: Temporary Files Cleanup
Function Cleanup-TempFiles {
   Remove-Item -Path "C:\Windows\Temp" -Recurse -Force
   Remove-Item -Path "$env:TEMP" -Recurse -Force
}

# Section 5: Disk Defragmentation (for HDD)
Function Start-Defragmentation {
   # Check if the drive is an HDD before defragmentation
   $driveInfo = Get-Volume -DriveLetter C
   if ($driveInfo.DriveType -eq "Fixed") {
      Optimize-Volume -DriveLetter C -Defrag -Verbose
   } else {
      Write-Host "Defragmentation not needed for SSD drive C:"
   }
}

# Section 6: System Health Check
Function Check-SystemHealth {
   sfc /scannow
   Get-WinEvent -LogName System | Where-Object {$_.EventID -eq 1001} | Select-Object -ExpandProperty Message | ForEach-Object {Write-Host $_}
}

Function Check-Disk {
   Get-Disk | Check-Disk -Repair
}

Function Restart-Service {
  Restart-Service -Name wuauserv, bits, cryptsvc
}

# Executing the functions
Fix-SystemImage
Start-DiskCleanup
Install-WindowsUpdates
Cleanup-TempFiles
Start-Defragmentation
Check-SystemHealth
Check-Disk
Restart-Service

Write-Host "Maintenance tasks completed."