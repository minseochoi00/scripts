#### Settings

# env
    # Choco
    $cinstall = choco install
    $cuninstall = choco uninstall
# Winget
    $winstall = winget install
    $wuninstall = winget uninstall
# Print Spooler
    $PrintSpooler_PATH = "$env:SystemRoot\System32\spool\PRINTERS\*.*"
# Windows Update
    $WindowsUpdateFolder = "$($env:windir)\SoftwareDistribution\Download"
# One-Drive
    $Process_oneDrive = Get-Process -Name OneDrive -ErrorAction SilentlyContinue
# Caffeine
    $CheckCaffeine = Get-Process -Name caffeine64 -ErrorAction SilentlyContinue
    $CaffeinePATH = "$env:ChocolateyInstall\lib\caffeine"
# ExecutionPolicy
    $Get_EXE_Policy = Get-ExecutionPolicy
    $BP = 'Bypass'
    $RS = 'RemoteSigned'
# Generic
    $Stop = 'Pause'

# Stop File Explorer
Write-Host "Stopping Windows Explorer..."
Start-Process -FilePath taskkill -ArgumentList '/f /im explorer.exe' -WindowStyle Hidden

# Set Execution Policy
    if (-not $Get_EXE_Policy -eq $BP) {
        Set-ExecutionPolicy $BP -Force
    }

# Set PSGallery as Trusted
    Start-Process powershell.exe -ArgumentList "Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted" -Verb RunAs -ErrorAction Ignore

# Installing NuGet Package
    Start-Process powershell.exe -ArgumentList "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force" -Verb RunAs -ErrorAction Ignore

# Installing Windows Update Module
    Start-Process powershell.exe -ArgumentList "Install-Module PSWindowsUpdate -Force" -Verb RunAs -ErrorAction Ignore
    
# Importing Windows Update Module
    Start-Process powershell.exe -ArgumentList "Import-Module PSWindowsUpdate -Force" -Verb RunAs -ErrorAction Ignore
    
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

# Install Caffeine and Chocolatey for prevent workstations going to sleep
    Start-Process powershell.exe -ArgumentList "irm minseochoi.tech/script/install-choco | Invoke-Expression" -Verb RunAs -ErrorAction SilentlyContinue
    Write-Host "Installing Caffeine"
    Start-Process powershell.exe -ArgumentList "$cinstall 'Caffeine' --confirm --limit-output --no-progress" -Verb RunAs -ErrorAction SilentlyContinue
    Write-Host "Starting Caffeine"
    Start-Process -FilePath $CaffeinePATH\caffeine64.exe
    Wait-Process -Name caffeine64 -Timeout 15
    $CheckCaffeine
    if ($CheckCaffeine) {
        Write-Host 'Process 'Caffeine64' has STARTED.'
    } else {
        Write-Host 'Process 'Caffeine64' is currently NOT RUNNING.'
    }

#### Start

# Check for One-Drive Installation
    if ($Process_oneDrive) {
        Write-Output "OneDrive is currently installed, Running Uninstaller"
        Start-Process powershell.exe -ArgumentList "irm minseochoi.tech/script/remove-onedrive | | Invoke-Expression" -Verb RunAs -ErrorAction SilentlyContinue
    } else {
        Write-Output "OneDrive is NOT Installed on this workstation."
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
    try {

        DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase /Quiet

    }
    
    catch {

        Write-Host "Error has occured while deleting old Windows installation files."

    }
    
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
        Remove-Item -Path $PrintSpooler_PATH -ErrorAction Ignore
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
        Write-Output "An error occured while fixing on Workstation's NTP Server: $($_.Exception.Message)"
    }

# Resync Time
    try {
    Write-Host "Resyncing Time"
    Start-Process -FilePath w32tm -ArgumentList '/resync /nowait /rediscover' -WindowStyle Hidden
    # w32tm /resync /nowait /rediscover
    }
    catch {
        Write-Output "An error occured while resyncing on Workstation's NTP Server: $($_.Exception.Message)"
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
    $CheckCaffeine
    Write-Host "Uninstalling Caffeine"
    if ($CheckCaffeine) {
        Stop-Process -Name 'caffeine64' -ErrorAction Ignore
        Start-Process powershell.exe -ArgumentList "$cuninstall 'caffeine' --confirm --limit-output --no-progress" -Verb RunAs -ErrorAction Ignore
    } else {
        Write-Host 'Process 'Caffeine64' is currently NOT running.'
    }

# Installation and Uninstallation of Chocolatey Cleaner
    Write-Host "Installing Choco Cleaner"
    choco install choco-cleaner --confirm --limit-output --no-progress -ErrorAction Ignore
    choco-cleaner
    Start-Process powershell.exe -ArgumentList "$cuninstall 'choco-cleaner' --confirm --limit-output --no-progress" -Verb RunAs -ErrorAction Ignore

# Windows Update
    Write-Host "Checking for Windows Update"
    # Check for Windows updates (excluding drivers)
    Get-WindowsUpdate -Download -Hide -IgnoreReboot -NotCategory "Drivers" -ErrorAction SilentlyContinue
   
# Starting File Explorer
    Write-Host "Starting Windows Explorer..."
    Start-Process -FilePath 'Explorer' -WindowStyle Hidden

# Re-setting ExecutionPolicy to RemoteSigned
    if (-not $Get_EXE_Policy -eq $RS) {
        Set-ExecutionPolicy $RS -Force
    }

# Prompt user to reboot
    Read-Host -Prompt "Cleanup completed. Do you want to reboot now? (Y/N)"
    if ($rebootChoice.ToUpper() -eq "Y") {
        Restart-Computer -Force
    } elseif ($rebootChoice.ToUpper() -eq "Yes") {
        Restart-Computer -Force
    } elseif ($rebootChoice.ToUpper() -eq "yes") {
        Restart-Computer -Force
    } else {
        Write-Host "You can manually reboot your computer later at your convenience."
    }

# Exit
    $Stop
    Exit

# End
