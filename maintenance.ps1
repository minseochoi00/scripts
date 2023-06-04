# Settings

# Installing NuGet Package for Module Installation
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue

# Installing Module for Checking Windows Update
    Install-Module PSWindowsUpdate -Force -ErrorAction SilentlyContinue

# Required Parameter for Disk Clean-up
    $SageSet = "StateFlags0099"
    $Base = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\"
    $Locations= @(
        "Active Setup Temp Folders"
        "BranchCache"
        "Downloaded Program Files"
        "GameNewsFiles"
        "GameStatisticsFiles"
        "GameUpdateFiles"
        "Internet Cache Files"
        "Memory Dump Files"
        "Offline Pages Files"
        "Old ChkDsk Files"
        "D3D Shader Cache"
        "Delivery Optimization Files"
        "Diagnostic Data Viewer database files"
        #"Previous Installations"
        #"Recycle Bin"
        "Service Pack Cleanup"
        "Setup Log Files"
        "System error memory dump files"
        "System error minidump files"
        "Temporary Files"
        "Temporary Setup Files"
        "Temporary Sync Files"
        "Thumbnail Cache"
        "Update Cleanup"
        "Upgrade Discarded Files"
        "User file versions"
        "Windows Defender"
        "Windows Error Reporting Archive Files"
        "Windows Error Reporting Queue Files"
        "Windows Error Reporting System Archive Files"
        "Windows Error Reporting System Queue Files"
        "Windows ESD installation files"
        "Windows Upgrade Log Files"
    )

# Start

# Delete Temporary Files for All Users
    Write-Host "Removing Temporary Files"
    Get-ChildItem -Path "$env:windir\Temp\" *.* -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Get-ChildItem -Path $env:TEMP *.* -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue


# Flush Cache
    Write-Host "Flushing IP Cache"
    ipconfig /flushdns

# Empty Recycle Bin
    Write-Host "Empty Recycle Bin"
    Clear-RecycleBin -Force -ErrorAction Ignore

# Windows Update
    Write-Host "Checking for Windows Update"
    # Check for Windows updates (excluding drivers)
    Get-WindowsUpdate -NotCategory "Drivers" -ErrorAction SilentlyContinue

# Cleanup Print Queue & Delete Old Print Jobs & Restarting Print Spooler
    try {
        Stop-Service -Name Spooler -Force
        Remove-Item -Path "$env:SystemRoot\System32\spool\PRINTERS\*.*" -ErrorAction Ignore
        Start-Service -Name Spooler
    }
    catch {
        Write-Host "Error has occured while Fixing Print Spooler"
    }

# Fix NTP Server
Write-Host "Fixing Workstation NTP Server"
    try {
        Start-Service 'W32Time'
        w32tm /config /manualpeerlist:time.google.com /syncfromflags:MANUAL /reliable:yes /update
        Restart-Service W32Time
        w32tm /config /update
    }
    catch {
        Write-Output "An error occured while Fixing on Workstation's NTP Server: $($_.Exception.Message)"
    }

# Resync Time
    try {
    Write-Host "Resyncing Time"
    w32tm /resync /nowait /rediscover
    }
    catch {
        Write-Output "An error occured while Resyncing on Workstation's NTP Server: $($_.Exception.Message)"
    }

# Clear Temporary Internet Files Only
    Write-Host "Clearing Temporary Internet Files"
    Clear-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Force -ErrorAction Ignore

# Running Disk Cleanup
    Write-Host "Starting Disk Cleanup"
    # -ea silentlycontinue will supress error messages
    ForEach($Location in $Locations) {
        Set-ItemProperty -Path $($Base+$Location) -Name $SageSet -Type DWORD -Value 2 -ea silentlycontinue | Out-Null
    }

    # Do the clean-up. Have to convert the SageSet number
    $Args = "/sagerun:$([string]([int]$SageSet.Substring($SageSet.Length-4)))"
    Start-Process -Wait "$env:SystemRoot\System32\cleanmgr.exe" -ArgumentList $Args

    # Remove the Stateflags
    ForEach($Location in $Locations) {
    Remove-ItemProperty -Path $($Base+$Location) -Name $SageSet -Force -ea silentlycontinue | Out-Null
    }

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