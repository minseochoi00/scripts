# Get the network adapter(s) that is currently connected and has an IPv4 address assigned
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -notmatch "Hyper-V" }

# Initialize variables to store IP address information and gateway
$ipAddresses = @()
$adapterNames = @()
$subnetMasks = @()
$gateways = @{}

# Loop through the adapters and retrieve information
foreach ($adapter in $adapters) {
    $adapterIpAddresses = $adapter | Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq "Dhcp" -or $_.PrefixOrigin -eq "Manual" } | Select-Object IPAddress, PrefixLength
    $adapterSubnetMasks = $adapterIpAddresses | Select-Object -ExpandProperty PrefixLength
    $adapterNames += $adapterIpAddresses | ForEach-Object { $adapter.InterfaceAlias }
    $ipAddresses += $adapterIpAddresses | Select-Object -ExpandProperty IPAddress
    $subnetMasks += $adapterSubnetMasks

    # Get the default gateway, if possible
    foreach ($config in Get-NetIPConfiguration -InterfaceIndex $adapter.InterfaceIndex) {
        if ($config.IPv4DefaultGateway) {
            if (!$gateways.ContainsKey($adapter.InterfaceAlias)) {
                $gateways[$adapter.InterfaceAlias] = @()
            }
            $gateways[$adapter.InterfaceAlias] += $config.IPv4DefaultGateway.NextHop
        }
    }
}

# Display computer and network information
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
Write-Host "Operating Installed Date: $OSInstallDate"
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


# ---------------------------------------------------------------------------------------------------------------------------- #

<#

# Set the output file path to the Windows generic temporary folder
$OutputFilePath = "$env:TEMP\Info.txt"
$FileName = "Info.txt"

# Run a script block that generates the computer and network information and saves it to the output file
& {

Write-Host "Computer Name: $ComputerName"
Write-Host "Operating System: $OSName"
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
        Write-Output "    Description: $($device.Description)"
        Write-Output ""
    }
} else {
    Write-Output "No graphics devices found."
}

$ipInfo

} | Out-File -FilePath $OutputFilePath -Encoding UTF8

# Get the user's desktop path and create a file path for the output file on the desktop
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$DesktopFilePath = Join-Path -Path $DesktopPath -ChildPath $FileName


# Copy the output file to the user's desktop, overwriting it if it already exists
Copy-Item -Path $OutputFilePath -Destination $DesktopFilePath -Force > $null

#>