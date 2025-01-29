Clear-Host

# Settings
Write-Host "Setting up the required variables..."

# Check if running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Error: This script must be run as Administrator!" -ForegroundColor Red
    Pause
    Exit
}

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
        if ($Arguments) { $processArgs.ArgumentList = $Arguments }
        Start-Process @processArgs
    } catch {
        Write-Host "Error Tweaking: $_"
    }
}

try {
    # Stop File Explorer
    Write-Host "Stopping Windows Explorer..."
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    # Set Execution Policy to Bypass
    Set-ExecutionPolicy Bypass -Force

    # Delete Temporary Files
    Write-Host "Clearing Temporary Files..."
    $tempPaths = @(
        "$env:windir\Temp\*",
        "$env:TEMP\*",
        "$env:windir\SoftwareDistribution\Download\*",
        "C:\Windows\Prefetch\*",
        "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache\*",
        "C:\Windows\Logs\CBS\*"
    )
    foreach ($path in $tempPaths) {
        Remove-Item -Path $path -Force -Recurse -ErrorAction SilentlyContinue
    }
    Write-Host "(Completed)"

    # Empty Recycle Bin for all drives
    Write-Host "Emptying Recycle Bin..."
    $drives = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root
    foreach ($drive in $drives) {
        Clear-RecycleBin -DriveLetter $drive[0] -Force -ErrorAction SilentlyContinue
    }
    Write-Host "(Completed)"

    # Windows NTP Server Adjustment
    Write-Host "Adjusting NTP Server settings..."
    $NTP_Args = @(
        "/config /manualpeerlist:time.nist.gov /syncfromflags:MANUAL /reliable:YES /update",
        "/config /update",
        "/resync /nowait /rediscover"
    )
    foreach ($arg in $NTP_Args) { CustomTweakProcess -Apps "w32tm" -Arguments $arg }
    Write-Host "(Completed)"

    # Flush DNS Cache
    Write-Host "Flushing DNS cache..."
    CustomTweakProcess -Apps "ipconfig" -Arguments "/flushdns"
    Write-Host "(Completed)"

    # Reset Windows Update Components
    Write-Host "Resetting Windows Update Components..."
    CustomTweakProcess -Apps "net" -Arguments "stop wuauserv"
    CustomTweakProcess -Apps "net" -Arguments "stop cryptSvc"
    CustomTweakProcess -Apps "net" -Arguments "stop bits"
    CustomTweakProcess -Apps "net" -Arguments "stop msiserver"
    Remove-Item "$env:SystemRoot\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\System32\catroot2\*" -Recurse -Force -ErrorAction SilentlyContinue
    CustomTweakProcess -Apps "net" -Arguments "start wuauserv"
    CustomTweakProcess -Apps "net" -Arguments "start cryptSvc"
    CustomTweakProcess -Apps "net" -Arguments "start bits"
    CustomTweakProcess -Apps "net" -Arguments "start msiserver"
    Write-Host "(Completed)"

    # System Image Check
    Write-Host "Fixing Windows Image using DISM..."
    CustomTweakProcess -Apps "dism" -Arguments "/online /cleanup-image /restorehealth"
    Write-Host "(Completed)"

    # System File Check
    Write-Host "Checking and repairing system files..."
    CustomTweakProcess -Apps "sfc" -Arguments "/scannow"
    Write-Host "(Completed)"

    # Running Disk Cleanup
    Write-Host "Starting Disk Cleanup..."
    foreach ($Location in $Locations) {
        Set-ItemProperty -Path "$Base$Location" -Name $SageSet -Type DWORD -Value 2 -ErrorAction SilentlyContinue | Out-Null
    }
    CustomTweakProcess -Apps "$env:SystemRoot\System32\cleanmgr.exe" -Arguments "/sagerun:99"
    foreach ($Location in $Locations) {
        Remove-ItemProperty -Path "$Base$Location" -Name $SageSet -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Host "(Completed)"

    # Start File Explorer
    Write-Host "Starting Windows Explorer..."
    Start-Process "explorer.exe"
    Write-Host "(Started)"

} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host "Script execution completed."
