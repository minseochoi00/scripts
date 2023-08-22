Clear-Host

#### Settigs

Write-Host "Comment: Aug v2.0"
Write-Host "Setting up the required variables..."

$debug = $false

# env
    # Custom Functions  
    function CustomTweakProcess {
        param (
            [string]$Apps,
            [string]$Arguments
        )
            if (-not($isAdmin)) {
                if ($null -ne $Arguments -and $Arguments -ne "") {
                    try {
                        Start-Process -FilePath "$Apps" -ArgumentList ($Arguments -split " ") -WindowStyle Hidden -Wait
                    } catch {
                        # Write-Host " (Failed: Tweak)"
                        Write-Host "Error Tweaking: $_" 
                    }
                } else {
                    try {
                        Start-Process -FilePath "$Apps" -WindowStyle Hidden -Wait
                    } catch { 
                        # Write-Host " (Failed: Tweak)"
                        Write-Host "Error Tweaking: $_" 
                    }
                }
            }
            if ($isAdmin) {
                if ($null -ne $Arguments -and $Arguments -ne "") {
                    try {
                        Start-Process -FilePath "$Apps" -ArgumentList ($Arguments -split " ") -Verb RunAs -WindowStyle Hidden -Wait
                    } catch {
                        # Write-Host " (Failed: Tweak)"
                        Write-Host "Error Tweaking: $_" 
                    }
                } else {
                    try {
                        Start-Process -FilePath "$Apps" -Verb RunAs -WindowStyle Hidden -Wait
                    } catch { 
                        # Write-Host " (Failed: Tweak)"
                        Write-Host "Error Tweaking: $_" 
                    }
                }
            }
    }

    # Arguments
        # Choco
            $PSGallery_Trusted_Args = 'Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted'
            $NuGet_Args = 'Install-PackageProvider -Name "NuGet" -MinimumVersion 2.8.5.201 -Force'
            $Windows_Update_Module_Args = "Install-Module PSWindowsUpdate"
            $Import_Windows_Update_Module_Args = "Import-Module PSWindowsUpdate"
            $W32TM_ManualPeerList_Arg = "/config /manualpeerlist:time.google.com /syncfromflags:MANUAL /reliable:yes /update"
            $W32TM_Update_Arg = "/config /update"
            $W32TM_ReSync_Arg = "/resync /nowait /rediscover"
            $Windows_Update_Args = 'Get-WindowsUpdate -Download -IgnoreReboot -NotCategory "Drivers"'
    $Test_Choco = Get-Command -Name choco -ea Ignore
        # Check for Chocolatey Installation if can't be found install it.
            if (-not($Test_Choco)) { Invoke-RestMethod minseochoi.tech/script/install-choco | Invoke-Expression }
    # Print Spooler
        $PrintSpooler_PATH = "$env:SystemRoot\System32\spool\PRINTERS\*.*"
    # Windows Update
        $WindowsUpdateFolder = "$($env:windir)\SoftwareDistribution\Download"
    # NTP Server Tweaks
        $NTPserviceName = "W32Time"
        $NTPservice = Get-Service -Name $NTPserviceName -ea SilentlyContinue
    # Check if the current user has administrative privileges
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    # Auto-Suppresses error messages
        $ErrorActionPreference = "SilentlyContinue"  
    
        
# ------------------------------------------------------------------------------------------------------------------------

# Start
    if (-not($debug)) {Clear-Host}

# Stop File Explorer
    Write-Host -NoNewLine "Stopping Windows Explorer..."
    $Arguments = '/f /im "explorer.exe"'
    CustomTweakProcess -Apps "taskkill" -Arguments $Arguments  # If you have a function to handle this
        # Wait for a moment to allow Explorer to close
            Start-Sleep -Seconds 2
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Write-Host " (Stopped)" } else { Write-Host " (Failed)" }   

# Set Execution Policy
    if (-not (Get-ExecutionPolicy) -eq "Bypass") { Set-ExecutionPolicy Bypass -Force }

# Set PSGallery as Trusted
    CustomTweakProcess -Apps powershell.exe -Arguments $PSGallery_Trusted_Args

# Installing NuGet Package
    CustomTweakProcess -Apps powershell.exe -Arguments $NuGet_Args

# Installing Windows Update Module
    CustomTweakProcess -Apps powershell.exe -Arguments $Windows_Update_Module_Args
    
# Importing Windows Update Module
    CustomTweakProcess -Apps powershell.exe -Arguments $Import_Windows_Update_Module_Args
    
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

# Delete Temporary Files for All Users
    Write-Host -NoNewline "Removing Temporary Files"
        try {
            Get-ChildItem -Path "$env:windir\Temp\" *.* -Recurse | Remove-Item -Force -Recurse -ea SilentlyContinue
            Get-ChildItem -Path $env:TEMP *.* -Recurse | Remove-Item -Force -Recurse -ea SilentlyContinue
            Write-Host " (Removed)"
        }
        catch { Write-Host " (Failed: Removal)" }

# Delete Windows update files
    Write-Host -NoNewLine "Deleting Windows update files..."
        try {
            Remove-Item "$WindowsUpdateFolder\*" -Recurse -Force -ea SilentlyContinue
            # Output message that it has been finished
                Write-Host " (Finished)"
        }
        catch { Write-Host " (Failed: Deletion)" }

# Delete old Windows installation files
    Write-Host -NoNewLine "Deleting old Windows installation files..."
        try {
            CustomTweakProcess -Apps "DISM" -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup /ResetBase"
            # Output message that it has been finished
                Write-Host " (Finished)"
        }
        catch { Write-Host " (Failed: Deletion)" }
    
# Flush Cache
    Write-Host -NoNewLine "Flushing IP Cache"
    try {
        CustomTweakProcess -Apps "ipconfig" -Arguments "/flushdns"
        # Output message that it has been finished
            Write-Host " (Finished)"
    }
    catch { Write-Host " (Failed)" }
    

# Empty Recycle Bin
    Write-Host -NoNewLine "Emptying Recycle Bin"
    try {
        Clear-RecycleBin -DriveLetter C -Force -ea Ignore
        # Output message that it has been finished
            Write-Host " (Finished)"
    }
    catch { Write-Host " (Failed)" }

# Cleanup Print Queue & Delete Old Print Jobs & Restarting Print Spooler
    Write-Host -NoNewLine "Fixing Print Spooler"
        try {
            Stop-Service -Name Spooler -Force
            Remove-Item -Path $PrintSpooler_PATH -ea Ignore
            Start-Service -Name Spooler
        # Output message that it has been finished
            Write-Host " (Finished)"
        }
        catch { Write-Host " (Failed:Spooler)" }

# Windows NTP Server Tweaks
    Write-Host -NoNewLine "Fixing Workstation's NTP Server"
        if (-not($isAdmin)) {Write-Host " (Failed: Permission)"}
        else {
            try {
                if (($NTPservice).Status -eq 'Stopped') { Start-Service -Name "W32Time" }
                CustomTweakProcess -Apps w32tm -Arguments $W32TM_ManualPeerList_Arg
                Restart-Service -Name "W32Time"
                CustomTweakProcess -Apps w32tm -Arguments $W32TM_Update_Arg
                CustomTweakProcess -Apps w32tm -Arguments $W32TM_ReSync_Arg
                    # Output message that it has been finished
                        Write-Host " (Finished)"
            }
            catch { Write-Host " (Failed)" }
        }   

# Running Disk Cleanup
    Write-Host -NoNewLine "Starting Disk Cleanup"
        try {
        foreach ($Location in $Locations) { Set-ItemProperty -Path $($Base+$Location) -Name $SageSet -Type DWORD -Value 2 -ea silentlycontinue | Out-Null }
        # Do the clean-up. Have to convert the SageSet number
            $Args = "/sagerun:$([string]([int]$SageSet.Substring($SageSet.Length-4)))"
            CustomTweakProcess -Apps "$env:SystemRoot\System32\cleanmgr.exe" -Arguments $Args
        # Remove the Stateflags
            ForEach($Location in $Locations) { Remove-ItemProperty -Path $($Base+$Location) -Name $SageSet -Force -ea silentlycontinue | Out-Null }
        # Output message that it has been finished
            Write-Host " (Finished)"
        }
        catch { Write-Host " (Failed: Disk Cleanup)" }



# Check and repair system files
    Write-Host -NoNewLine "Checking and repairing system files..."
        try {
            CustomTweakProcess -Apps "sfc" -Arguments "/scannow"
        # Output message that it has been finished
            Write-Host " (Finished)"
        }
        catch { Write-Host " (Failed)" }

# Windows Update
    Write-Host -NoNewLine "Checking for Windows Update"
        try {
        # Check for Windows updates (excluding drivers)
        CustomTweakProcess -Apps "powershell" -Arguments $Windows_Update_Args
        # Output message that it has been finished
        Write-Host " (Finished)"
        }
        catch { Write-Host " (Failed)" }
    
   
# Starting File Explorer
    Write-Host -NoNewLine "Re-starting Windows Explorer..."
        if (-not(Get-Process -Name explorer -ea SilentlyContinue)) { Start-Process Explorer.exe }
        Start-Sleep 5
        if (Get-Process -Name explorer -ea SilentlyContinue) { Write-Host " (Started)"} else { Write-Host " (Failed: Start)"}

# Exit
    return

# End
