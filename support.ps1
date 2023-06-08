# Retrieve Computer Information
$ComputerName = $env:COMPUTERNAME
$OSName = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
$OSInstallDate = systeminfo | find /i "install date"
$Model = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
$CPU = (Get-CimInstance -ClassName Win32_Processor).Name
$RAM = [math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
$drives = Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object DeviceID, VolumeName, FreeSpace

$driveInfo = @()
foreach ($drive in $drives) {
    $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
    if ($drive.VolumeName) {
        $driveInfo += "$($drive.DeviceID) $($drive.VolumeName) Free Space: $($freeSpaceGB) GB`n"
    } else {
        $driveInfo += "$($drive.DeviceID) Free Space: $($freeSpaceGB) GB`n"
    }
}

# Get all graphics devices on the system
$graphics_devices = Get-CimInstance -Class Win32_VideoController

# ---------------------------------------------------------------------------------------------------------------------------- #

Write-Host "Computer Name: $ComputerName"
Write-Host "Operating System: $OSName"
Write-Host "$OSInstallDate"
Write-Host "System Model: $Model"
Write-Host ""
Write-Host "CPU: $CPU"
Write-Host "RAM: $RAM GB"
Write-Host "Drive Information:`n$($driveInfo -join '')"
# Check if there are any graphics devices available
if ($graphics_devices) {
    # Print the name and description of each graphics device
    Write-Host ""
    Write-Output "Graphics devices:"
    foreach ($device in $graphics_devices) {
        Write-Output "    Name: $($device.Name)"
        Write-Output ""
    }
} else {
    Write-Output "No graphics devices found."
}
pause
return