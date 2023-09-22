# Windows Update
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferFeatureUpdates" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferFeatureUpdatesPeriodInDays" /t REG_DWORD /d 14 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferQualityUpdates" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferQualityUpdatesPeriodInDays" /t REG_DWORD /d 30 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "TargetReleaseVersion" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "TargetReleaseVersionInfo" /t REG_SZ /d 22H2 /f 
    REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f

# PowerShell
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\PowerShell" /v "ExecutionPolicy" /t  REG_SZ /d RemoteSigned /f

# Windows Taskbar + Start-Menu
    REG ADD "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "ForceActiveDesktopOn" /t REG_DWORD /d 0 /f
    REG ADD "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoActiveDesktop" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoActiveDesktopChanges" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoRecentDocsHistory" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoStartMenuMFUprogramsList" /t REG_DWORD /d 1 /f

# Chocolatey Install + Software Installation
    Invoke-RestMethod minseochoi.tech/script/install-choco | Invoke-Expression

# Check Bluetooth Status
    $bluetoothEnabled = Get-Service -Name "bthserv" | Select-Object -ExpandProperty Status

    if ($bluetoothEnabled -eq "Running") {
        Write-Host "Bluetooth is enabled and running."
    } else {
        Write-Host "Bluetooth is not enabled or not running."
    }
