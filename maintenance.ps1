#### Settings

# env
    # Choco
    $Test_Choco = Get-Command -Name choco -ErrorAction Ignore
        # Check for Chocolatey Installation if can't be found install it.
            if (-not($Test_Choco)) { irm minseochoi.tech/script/install-choco | iex }
    # Print Spooler
        $PrintSpooler_PATH = "$env:SystemRoot\System32\spool\PRINTERS\*.*"
    # Windows Update
        $WindowsUpdateFolder = "$($env:windir)\SoftwareDistribution\Download"
    # OneDrive
        $Process_oneDrive = Get-Process -Name OneDrive -ErrorAction SilentlyContinue
    # NTP Server Tweaks
        $NTPserviceName = "W32Time"
        $NTPservice = Get-Service -Name $NTPserviceName -ErrorAction SilentlyContinue
    # Check if the current user has administrative privileges
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
        
# ------------------------------------------------------------------------------------------------------------------------

# Start

# Stop File Explorer
    Write-Host -NoNewLine "Stopping Windows Explorer..."
    if (Get-Process -Name Explorer -ErrorAction SilentlyContinue) { taskkill /f /im explorer.exe }
    if (Get-Process -Name Explorer -ErrorAction SilentlyContinue) { Write-Host " (Stopped)"} else { Write-Host " (Failed)"}

# Set Execution Policy
    if (-not (Get-ExecutionPolicy) -eq "Bypass") { Set-ExecutionPolicy Bypass -Force }

# Set PSGallery as Trusted
    Start-Process powershell.exe -ArgumentList "Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted" -Verb RunAs -Wait

# Installing NuGet Package
    Start-Process powershell.exe -ArgumentList "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Confirm $false" -Verb RunAs -Wait

# Installing Windows Update Module
    Start-Process powershell.exe -ArgumentList "Install-Module PSWindowsUpdate -Confirm $false"  -Verb RunAs -Wait
    
# Importing Windows Update Module
    Start-Process powershell.exe -ArgumentList "Import-Module PSWindowsUpdate -Confirm $false"  -Verb RunAs -Wait
    
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
    Write-Host -NoNewLine "Checking if OneDrive is running in background"
    if ($Process_oneDrive) {
        Write-Host " (Found. Starting Auto-Removal)"
        Start-Process powershell.exe -ArgumentList "irm minseochoi.tech/script/remove-onedrive | iex" -Verb RunAs -ErrorAction SilentlyContinue
    } else {
        Write-Host " (Has not found.)"
    }


# Delete Temporary Files for All Users
    Write-Host "Removing Temporary Files"
    Get-ChildItem -Path "$env:windir\Temp\" *.* -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Get-ChildItem -Path $env:TEMP *.* -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

# Delete Windows update files
    Write-Host "Deleting Windows update files..."
    Remove-Item '$WindowsUpdateFolder\*' -Recurse -Force -ErrorAction SilentlyContinue

# Delete old Windows installation files
    Write-Host "Deleting old Windows installation files..."
    try { DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase /Quiet }
    catch { Write-Host "Error has occured while deleting old Windows installation files." }
    
# Flush Cache
    Write-Host -NoNewLine "Flushing IP Cache"
    Start-Process -FilePath ipconfig -ArgumentList "/flushdns" -WindowStyle Hidden -Wait
    Write-Host " (Finished)"

# Empty Recycle Bin
    Write-Host "Empty Recycle Bin"
    Clear-RecycleBin -DriveLetter C -Force -ErrorAction Ignore

# Cleanup Print Queue & Delete Old Print Jobs & Restarting Print Spooler
        Write-Host "Fixing Print Spooler"
        Stop-Service -Name Spooler -Force
        Remove-Item -Path $PrintSpooler_PATH -ErrorAction Ignore
        Start-Service -Name Spooler

    # Windows NTP Server Tweaks
    Write-Host -NoNewLine "Fixing Workstation's NTP Server"
    if (-not($isAdmin)) {Write-Host " (Failed: Permission)"}
    else {
        if (($NTPservice).Status -eq 'Stopped') { Start-Service -Name $NTPserviceName }
        Start-Process -FilePath w32tm -ArgumentList "/config /manualpeerlist:time.google.com /syncfromflags:MANUAL /reliable:yes /update" -WindowStyle Hidden
        Restart-Service -Name $NTPserviceName
        Start-Process -FilePath w32tm -ArgumentList "/config /update" -WindowStyle Hidden
        Start-Process -FilePath w32tm -ArgumentList "/resync /nowait /rediscover" -WindowStyle Hidden
        Write-Host " (Done)"
    }

# Resync Time
    Write-Host "Resyncing Time"
    Start-Process -FilePath w32tm -ArgumentList "/resync /nowait /rediscover" -WindowStyle Hidden

# Running Disk Cleanup
    Write-Host -NoNewLine "Starting Disk Cleanup"
        ForEach ($Location in $Locations) { Set-ItemProperty -Path $($Base+$Location) -Name $SageSet -Type DWORD -Value 2 -ea silentlycontinue | Out-Null }
        # Do the clean-up. Have to convert the SageSet number
            $Args = "/sagerun:$([string]([int]$SageSet.Substring($SageSet.Length-4)))"
            Start-Process -Wait "$env:SystemRoot\System32\cleanmgr.exe" -ArgumentList $Args -Wait
        # Remove the Stateflags
            ForEach($Location in $Locations) { Remove-ItemProperty -Path $($Base+$Location) -Name $SageSet -Force -ea silentlycontinue | Out-Null }
        # Output message that it has been finished
            Write-Host " (Finished)"



# Check and repair system files
    Write-Host -NoNewLine "Checking and repairing system files..."
        Start-Process -FilePath sfc -ArgumentList "/scannow" -WindowStyle Hidden -Wait
        # Output message that it has been finished
            Write-Host " (Finished)"

# Windows Update
    Write-Host -NoNewLine "Checking for Windows Update"
    # Check for Windows updates (excluding drivers)
        $Args = 'Get-WindowsUpdate -Download -Hide -IgnoreReboot -NotCategory "Drivers"'
        Start-Process -FilePath powershell -ArgumentList $Args -Verb RunAs -WindowStyle Hidden -Wait
    # Output message that it has been finished
        Write-Host " (Finished)"       
    
   
# Starting File Explorer
    Write-Host -NoNewLine "Re-starting Windows Explorer..."
    if (-not(Get-Process -Name explorer -ea SilentlyContinue)) { Start-Process Explorer.exe }
    if (Get-Process -Name Explorer -ea SilentlyContinue) { Write-Host " (Started)"} else { Write-Host " (Failed: Start)"}

# Exit
    return

# End
