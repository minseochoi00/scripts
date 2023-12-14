Clear-Host

# Settings
Write-Host "Comment: Aug v2.0 Updated"
Write-Host "Setting up the required variables..."

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

# Check if the current user has administrative privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Function to handle custom process execution
function CustomTweakProcess {
    param (
        [string]$Apps,
        [string]$Arguments
    )
    try {
        $processArgs = @{
            FilePath = $Apps
            WindowStyle = "Hidden"
            Wait = $true
        }
        if ($Arguments) { $processArgs.ArgumentList = $Arguments -split " " }
        if ($isAdmin) { $processArgs.Verb = "RunAs" }
        
        Start-Process @processArgs
    } catch {
        Write-Host "Error Tweaking: $_"
    }
}

# Main script execution
try {

    # Stop File Explorer
        Write-Host -NoNewLine "Stopping Windows Explorer..."
        $Arguments = '/f /im "explorer.exe"'
        CustomTweakProcess -Apps "taskkill" -Arguments $Arguments  # If you have a function to handle this
            # Wait for a moment to allow Explorer to close
                Start-Sleep -Seconds 2
        if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Write-Host " (Stopped)" } else { Write-Host " (Failed)" }   

    # Set Execution Policy to Bypass
        Set-ExecutionPolicy Bypass -Force

    # Cleanup operations
        Write-Host "Performing cleanup operations..."

    # Delete Temporary Files
        Get-ChildItem "$env:windir\Temp\", "$env:TEMP", "$($env:windir)\SoftwareDistribution\Download\*" -Recurse | Remove-Item -Force -Recurse -ErrorAction Ignore
        Write-Host "Temporary files removed."

    # Empty Recycle Bin
        Clear-RecycleBin -DriveLetter C -Force -ErrorAction Ignore
        Write-Host "Recycle Bin emptied."

    # Windows NTP Server Adjustment (Only if Admin)
        if ($isAdmin) {
            Write-Host "Adjusting NTP Server settings..."
            $NTP_Args = @("/config /manualpeerlist:time.google.com /syncfromflags:MANUAL /reliable:yes /update", "/config /update", "/resync /nowait /rediscover")
            foreach ($arg in $NTP_Args) { CustomTweakProcess -Apps "w32tm" -Arguments $arg }
            Write-Host "NTP Server settings adjusted."
        }

    # System Image Check
        Write-Host "Fixing Windows Image using DISM"
        CustomTweakProcess -Apps "dism" -Arguments "/online /english /cleanup-image /restorehealth"
        CustomTweakProcess -Apps "dism" -Arguments "/cleanup-mountpoints"

    # System File Check
        Write-Host "Checking and repairing system files..."
        CustomTweakProcess -Apps "sfc" -Arguments "/scannow"
        Write-Host "System file check complete."

    # Running Disk Cleanup
        Write-Host -NoNewLine "Starting Disk Cleanup"
        try {
        foreach ($Location in $Locations) { Set-ItemProperty -Path $($Base+$Location) -Name $SageSet -Type DWORD -Value 2 -ea silentlycontinue | Out-Null }
        # Do the clean-up. Have to convert the SageSet number
            $Args = "/sagerun:$([string]([int]$SageSet.Substring($SageSet.Length-4)))"
            CustomTweakProcess -Apps "$env:SystemRoot\System32\cleanmgr.exe" -Arguments $Args
        # Remove the Stateflags
            foreach($Location in $Locations) { Remove-ItemProperty -Path $($Base+$Location) -Name $SageSet -Force -ea silentlycontinue | Out-Null }
        # Output message that it has been finished
            Write-Host " (Finished)"
        } catch { Write-Host " (Failed: Disk Cleanup)" 
        }

} catch {
    Write-Host "An error occurred: $_"
}

Write-Host "Script execution completed."
