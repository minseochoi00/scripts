# Windows Update
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferFeatureUpdates" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferFeatureUpdatesPeriodInDays" /t REG_DWORD /d 14 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferQualityUpdates" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferQualityUpdatesPeriodInDays" /t REG_DWORD /d 30 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "TargetReleaseVersion" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "TargetReleaseVersionInfo" /t REG_SZ /d 22H2 /f 
    REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f

# Google
    REG ADD "HKLM\SOFTWARE\Policies\Google\Chrome" /v "HomepageLocation" /t REG_SZ /d http://www.lcds.org /f

# PowerShell
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\PowerShell" /v "ExecutionPolicy" /t  REG_SZ /d RemoteSigned /f

# Windows Taskbar + Start-Menu
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "ForceActiveDesktopOn" /t REG_DWORD /d 0 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "NoActiveDesktop" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "NoActiveDesktopChanges" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "NoRecentDocsHistory" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "NoStartMenuMFUprogramsList" /t REG_DWORD /d 1 /f

# Mouse
    REG ADD "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d 0 /f
    REG ADD "HKCU\Control Panel\Mouse" /v "MouseSensitivity" /t REG_SZ /d 10 /f
    
# Keyboard
    REG ADD "HKCU\Control Panel\Keyboard" /v "KeyboardDelay" /t REG_SZ /d 0 /f
    REG ADD "HKCU\Control Panel\Keyboard" /v "KeyboardSpeed" /t REG_SZ /d 31 /f
    REG ADD "HKCU\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d 2 /f

# Chocolatey Install + Software Installation
    Invoke-RestMethod minseochoi.tech/script/install-choco | Invoke-Expression

# Check Bluetooth Status
    $bluetoothEnabled = Get-Service -Name "bthserv" | Select-Object -ExpandProperty Status

    if ($bluetoothEnabled -eq "Running") {
        Write-Host "Bluetooth is enabled and running."
    } else {
        Write-Host "Bluetooth is not enabled or not running."
    }
