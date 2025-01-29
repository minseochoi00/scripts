Clear-Host

# Import modules
$modules = @("force-mkdir.psm1", "take-own.psm1")
foreach ($module in $modules) {
    $modulePath = Join-Path -Path "$PSScriptRoot\..\lib" -ChildPath $module
    if (Test-Path $modulePath) {
        Import-Module -DisableNameChecking $modulePath -ErrorAction Stop
    } else {
        Write-Host "Warning: Module $module not found. Skipping..."
    }
}

$ErrorActionPreference = "SilentlyContinue"

# Function Definitions
function Restart-Explorer {
    Stop-Process -Name Explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process "explorer.exe"
    Write-Host "Windows Explorer restarted."
}

# Stop OneDrive Process
$oneDriveProcess = Get-Process -Name OneDrive -ErrorAction SilentlyContinue
if ($oneDriveProcess) {
    Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
    Write-Host "OneDrive process stopped."
} else {
    Write-Host "OneDrive is not running."
}

# Uninstall OneDrive
$oneDriveSetup = Get-Command -ErrorAction SilentlyContinue -Name "OneDriveSetup.exe"
if ($oneDriveSetup) {
    Write-Host "Uninstalling OneDrive from $($oneDriveSetup.Source)"
    Start-Process -FilePath $oneDriveSetup.Source -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue
} else {
    Write-Host "OneDriveSetup.exe not found in standard locations."
}

# Remove OneDrive directories
$oneDriveDirectories = @("$env:localappdata\Microsoft\OneDrive", "$env:programdata\Microsoft OneDrive", "$env:systemdrive\OneDriveTemp", "$env:userprofile\OneDrive")
foreach ($dir in $oneDriveDirectories) {
    if (Test-Path $dir) {
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Removed OneDrive directory: $dir"
    }
}

# Registry Modifications for Disabling OneDrive
$regPaths = @(
    "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\OneDrive",
    "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}",
    "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
)

foreach ($regPath in $regPaths) {
    if (!(Test-Path $regPath)) {
        New-Item -Path $regPath -Force -ErrorAction Stop | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $regPath -Name "DisableFileSyncNGSC" -Value 1 -ErrorAction SilentlyContinue
}

# Remove Run Hooks for All Users
$users = Get-ChildItem "Registry::HKEY_USERS" | Where-Object { $_.Name -match "S-1-5-\d+$" }
foreach ($user in $users) {
    $runKey = "Registry::$($user.Name)\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $runKey) {
        Remove-ItemProperty -Path $runKey -Name "OneDriveSetup" -ErrorAction SilentlyContinue
        Write-Host "Removed OneDrive startup hook for $($user.Name)"
    }
}

# Final Cleanup and Restart Explorer
Write-Host "Finalizing cleanup and restarting Windows Explorer..."
Restart-Explorer
