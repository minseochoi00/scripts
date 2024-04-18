# Environment Setup
Clear-Host
Import-Module -DisableNameChecking "$PSScriptRoot\..\lib\force-mkdir.psm1" -ErrorAction Ignore
Import-Module -DisableNameChecking "$PSScriptRoot\..\lib\take-own.psm1" -ErrorAction Ignore
$ErrorActionPreference = "SilentlyContinue"

# Function Definitions
function Restart-Explorer {
    $explorerProcess = Get-Process -Name Explorer -ErrorAction SilentlyContinue
    if ($explorerProcess) {
        Stop-Process -Name Explorer -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 2
    Start-Process "explorer.exe"
}

# Script Start
Write-Host "Stopping OneDrive process..."
Start-Process -FilePath "taskkill" -ArgumentList "/f /im OneDrive.exe" -Verb RunAs -Wait -ErrorAction SilentlyContinue

# Uninstall OneDrive
$oneDriveSetupPaths = @("$env:systemroot\System32\OneDriveSetup.exe", "$env:systemroot\SysWOW64\OneDriveSetup.exe")
foreach ($path in $oneDriveSetupPaths) {
    if (Test-Path $path) {
        Write-Host "Uninstalling OneDrive from $path"
        Start-Process -FilePath $path -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue
    }
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
$regPaths = @("HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\OneDrive", "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}", "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}")
foreach ($regPath in $regPaths) {
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force -ErrorAction Ignore | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $regPath -Name "DisableFileSyncNGSC" -Value 1 -ErrorAction SilentlyContinue
}

# Remove Run Hooks for New Users
& reg load "hku\Default" "C:\Users\Default\NTUSER.DAT"
& reg delete "HKEY_USERS\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f
& reg unload "hku\Default"

# Final Cleanup and Restart Explorer
Write-Host "Finalizing cleanup and restarting Windows Explorer..."
Restart-Explorer