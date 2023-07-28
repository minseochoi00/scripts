#### Settings

# env
    # Choco
    $Test_Choco = Get-Command -Name choco -ErrorAction Ignore
        # Check for Chocolatey and Winget Installation
            if (-not($Test_Choco)) { irm minseochoi.tech/script/install-choco | iex }
    # Print Spooler
        $PrintSpooler_PATH = "$env:SystemRoot\System32\spool\PRINTERS\*.*"
    # Windows Update
        $WindowsUpdateFolder = "$($env:windir)\SoftwareDistribution\Download"
    # OneDrive
        $Process_oneDrive = Get-Process -Name OneDrive -ErrorAction SilentlyContinue
    # NTP Server Tweaks
        $serviceName = "W32Time"
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        
# ------------------------------------------------------------------------------------------------------------------------

# Start

# Stop File Explorer
    Write-Host "Stopping Windows Explorer..."
    if (Get-Process -Name Explorer -ErrorAction SilentlyContinue) { taskkill /f /im explorer.exe }

# Set Execution Policy
    if (-not (Get-ExecutionPolicy) -eq "Bypass") { Set-ExecutionPolicy Bypass -Force }

# Set PSGallery as Trusted
    Start-Process powershell.exe -ArgumentList "Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted" -Verb RunAs -ErrorAction Ignore

# Installing NuGet Package
    Start-Process powershell.exe -ArgumentList "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Confirm $false" -Verb RunAs -ErrorAction Ignore

# Installing Windows Update Module
    Start-Process powershell.exe -ArgumentList "Install-Module PSWindowsUpdate -Confirm $false"  -Verb RunAs -ErrorAction Ignore
    
# Importing Windows Update Module
    Start-Process powershell.exe -ArgumentList "Import-Module PSWindowsUpdate -Confirm $false"  -Verb RunAs -ErrorAction Ignore
    
# Required Parameter for Disk Clean-up
    $SageSet = "StateFlags0099"
    $Base = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\"
    $Locations= @(
        "Active Setup Temp Folders",
        "BranchCache",
        "Downloaded Program Files",
        "GameNewsFiles",
        "GameStatisticsFiles",
        "GameUpdateFiles",
        "Internet Cache Files",
        "Memory Dump Files",
        "Offline Pages Files",
        "Old ChkDsk Files",
        "D3D Shader Cache",
        "Delivery Optimization Files",
        "Diagnostic Data Viewer database files",
        #"Previous Installations",
        #"Recycle Bin",
        "Service Pack Cleanup",
        "Setup Log Files",
        "System error memory dump files",
        "System error minidump files",
        "Temporary Files",
        "Temporary Setup Files",
        "Temporary Sync Files",
        "Thumbnail Cache",
        "Update Cleanup",
        "Upgrade Discarded Files",
        "User file versions",
        "Windows Defender",
        "Windows Error Reporting Archive Files",
        "Windows Error Reporting Queue Files",
        "Windows Error Reporting System Archive Files",
        "Windows Error Reporting System Queue Files",
        "Windows ESD installation files",
        "Windows Upgrade Log Files"
    )

#### Start

# Check for One-Drive Installation
    if ($Process_oneDrive) {
        Write-Output "OneDrive is currently "RUNNING", "STARTING Uninstaller""
        Start-Process powershell.exe -ArgumentList "irm minseochoi.tech/script/remove-onedrive | iex" -Verb RunAs -ErrorAction SilentlyContinue
    } else {
        Write-Output "OneDrive is currently "NOT RUNNING" on this workstation."
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
    try { DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase /Quiet }
    catch { Write-Host "Error has occured while deleting old Windows installation files." }
    
# Flush Cache
    Write-Host "Flushing IP Cache"
    Start-Process -FilePath ipconfig -ArgumentList "/flushdns" -WindowStyle Hidden

# Empty Recycle Bin
    Write-Host "Empty Recycle Bin"
    Clear-RecycleBin -DriveLetter C -Force -ErrorAction Ignore

# Cleanup Print Queue & Delete Old Print Jobs & Restarting Print Spooler
        Write-Host "Fixing Print Spooler"
        Stop-Service -Name Spooler -Force
        Remove-Item -Path $PrintSpooler_PATH -ErrorAction Ignore
        Start-Service -Name Spooler

# Fix NTP Server
    Write-Host "Fixing Workstation's NTP Server"
    if ($null -eq $service) { Start-Service -Name $serviceName }
    Start-Process -FilePath w32tm -ArgumentList "/config /manualpeerlist:time.google.com /syncfromflags:MANUAL /reliable:yes /update" -WindowStyle Hidden
    Restart-Service -Name $serviceName
    Start-Process -FilePath w32tm -ArgumentList "/config /update" -WindowStyle Hidden
    Start-Process -FilePath w32tm -ArgumentList "/resync /nowait /rediscover" -WindowStyle Hidden


# Resync Time
    Write-Host "Resyncing Time"
    Start-Process -FilePath w32tm -ArgumentList "/resync /nowait /rediscover" -WindowStyle Hidden

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

# Check and repair system files
    Write-Host "Checking and repairing system files..."
    Start-Process -FilePath sfc -ArgumentList "/scannow" -WindowStyle Hidden

# Windows Update
    Write-Host "Checking for Windows Update"
    # Check for Windows updates (excluding drivers)
    Get-WindowsUpdate -Download -Hide -IgnoreReboot -NotCategory "Drivers" -ErrorAction SilentlyContinue
   
# Starting File Explorer
    Write-Host "Starting Windows Explorer..."
    if (-not(Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process Explorer.exe }

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

# Prompt user to reboot
    do {
        $Restart_Choice = Read-Host -Prompt "$computerName / $userName is recommended to restart. Would you like to perform a restart? "
        if ($Restart_Choice.ToUpper() -eq "YES" -or $Restart_Choice.ToUpper() -eq "Y" -or $Restart_Choice.ToUpper() -eq "y" -or $Restart_Choice.ToUpper() -eq "yes") { $Restart = $true } 
        elseif ($Restart_Choice.ToUpper() -eq "NO" -or $Restart_Choice.ToUpper() -eq "N" -or $Restart_Choice.ToUpper() -eq "no" -or $Restart_Choice.ToUpper() -eq "n") { $Restart = $false } 
        else {
            Write-Host "You must select either Yes (Y) or No (N)." 
        }
    } while (-not ($Restart -eq $true -or $Restart -eq $false))

# Performing from User Prompt
    if ($restart) { Restart-Computer -Force }
    if (-not($restart)) { Write-Host "Please reboot/shutdown your computer for these cleanup to affect ASAP." }

# Exit
    $Stop
    Exit

# End
