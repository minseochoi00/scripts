#### Settings

# Stop File Explorer
    taskkill /f /im explorer.exe

# Set Execution Policy
    Set-ExecutionPolicy ByPass -Force

# Set PSGallery as Trusted
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# Installing NuGet Package
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue

# Installing Windows Update Module
    Install-Module PSWindowsUpdate -Force -ErrorAction SilentlyContinue

# Importing Windows Update Module
    Import-Module PSWindowsUpdate -Force -ErrorAction SilentlyContinue

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

# Windows Update File PATH
    $WindowsUpdateFolder = "$($env:windir)\SoftwareDistribution\Download"

# Caffeine64 Check Process and Set PATH
    $CheckCaffeine = Get-Process -Name caffeine64 -ErrorAction SilentlyContinue
    $CaffeinePATH = C:\ProgramData\chocolatey\lib\caffeine

# Install Caffeine for prevent laptops / desktops going to sleep
    Invoke-RestMethod minseochoi.tech/script/install-choco | Invoke-Expression
    Write-Host "Installing Caffeine"
    choco install Caffeine --confirm --limit-output --no-progress
    
    Write-Host "Starting Caffeine"
    Start-Process -FilePath '$CaffeinePATH\caffeine64.exe'
    if ($CheckCaffeine) {
        Write-Host 'Process 'Caffeine64' has STARTED.'
    } else {
        Write-Host 'Process 'Caffeine64' is currently NOT RUNNING.'
    }

#### Start

# Check for One-Drive Installation
    $oneDrivePackage = Get-AppxPackage *OneDrive*
    if ($oneDrivePackage) {
        Write-Output "OneDrive is Installed, Recommend Running Uninstaller"
        Write-Output "----------------------------------------------------"
        Write-Output "irm minseochoi.tech/script/remove-onedrive.ps1"
        Write-Output "----------------------------------------------------"
        if ($oneDrivePackage.InstallLocation) {
            $oneDrivePATH = $oneDrivePackage.InstallLocation
            Write-Output "OneDrive Installation PATH: $oneDrivePATH"
        }
        Pause
    } else {
        Write-Output "OneDrive is NOT Installed."
    }

# Delete Temporary Files for All Users
    Write-Host "Removing Temporary Files"
    Get-ChildItem -Path "$env:windir\Temp\" *.* -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Get-ChildItem -Path $env:TEMP *.* -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

# Delete Windows update files
    Write-Host "Deleting Windows update files..."
    Remove-Item $WindowsUpdateFolder\* -Recurse -Force -ErrorAction SilentlyContinue

# Delete old Windows installation files
    Write-Host "Deleting old Windows installation files..."
    DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase /Quiet

# Flush Cache
    Write-Host "Flushing IP Cache"
    Start-Process -FilePath ipconfig -ArgumentList '/flushdns' -WindowStyle Hidden

# Empty Recycle Bin
    Write-Host "Empty Recycle Bin"
    Clear-RecycleBin -DriveLetter C -Force -ErrorAction Ignore

# Cleanup Print Queue & Delete Old Print Jobs & Restarting Print Spooler
    try {
        Write-Host "Fixing Print Spooler"
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
        Start-Process -FilePath w32tm -ArgumentList '/config /manualpeerlist:time.google.com /syncfromflags:MANUAL /reliable:yes /update' -WindowStyle Hidden
        Restart-Service W32Time
        Start-Process -FilePath w32tm -ArgumentList '/config /update' -WindowStyle Hidden
    }
    catch {
        Write-Output "An error occured while Fixing on Workstation's NTP Server: $($_.Exception.Message)"
    }

# Resync Time
    try {
    Write-Host "Resyncing Time"
    Start-Process -FilePath w32tm -ArgumentList '/resync /nowait /rediscover' -WindowStyle Hidden
    # w32tm /resync /nowait /rediscover
    }
    catch {
        Write-Output "An error occured while Resyncing on Workstation's NTP Server: $($_.Exception.Message)"
    }

# Running Disk Cleanup
    Write-Host "Starting Disk Cleanup"
    # -ea silentlycontinue will supress error messages
    ForEach ($Location in $Locations) {
        Set-ItemProperty -Path $($Base+$Location) -Name $SageSet -Type DWORD -Value 2 -ea silentlycontinue | Out-Null
    }

    # Do the clean-up. Have to convert the SageSet number
    $Args = "/sagerun:$([string]([int]$SageSet.Substring($SageSet.Length-4)))"
    Start-Process -Wait "$env:SystemRoot\System32\cleanmgr.exe" -ArgumentList $Args

    # Remove the Stateflags
    ForEach($Location in $Locations) {
    Remove-ItemProperty -Path $($Base+$Location) -Name $SageSet -Force -ea silentlycontinue | Out-Null
    }

# Running Disk Defragmentation
    Write-Host "Performing a disk defragmentation..."
    Start-Process -FilePath "defrag.exe" -ArgumentList "-c" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue

# Check and repair system files
    Write-Host "Checking and repairing system files..."
    Start-Process -FilePath sfc -ArgumentList '/scannow' -WindowStyle Hidden
    # sfc /scannow

# Un-installation of Caffeine
    Write-Host "Uninstalling Caffeine"
    if ($CheckCaffeine) {
        Stop-Process -Name caffeine64
        choco uninstall caffeine --confirm --limit-output --no-progress
    } else {
        Write-Host 'Process 'Caffeine64' is currently NOT running.'
    }

# Installation and Uninstallation of Chocolatey Cleaner
    Write-Host "Installing Choco Cleaner"
    choco install choco-cleaner --confirm --limit-output --no-progress
    choco-cleaner 
    choco uninstall choco-cleaner --confirm --limit-output --no-progress

# Windows Update
    Write-Host "Checking for Windows Update"
    # Check for Windows updates (excluding drivers)
    Get-WindowsUpdate -Download -Hide -IgnoreReboot -NotCategory "Drivers" -ErrorAction SilentlyContinue
   
# Starting File Explorer
    start-process explorer

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
