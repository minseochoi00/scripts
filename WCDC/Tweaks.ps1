# Windows Update
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferFeatureUpdates" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferFeatureUpdatesPeriodInDays" /t REG_DWORD /d 14 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferQualityUpdates" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferQualityUpdatesPeriodInDays" /t REG_DWORD /d 30 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f

# PowerShell
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\PowerShell" /v "ExecutionPolicy" /t  REG_SZ /d RemoteSigned /f

# Windows Taskbar + Start-Menu
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "ForceActiveDesktopOn" /t REG_DWORD /d 0 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "NoActiveDesktop" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "NoActiveDesktopChanges" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "NoRecentDocsHistory" /t REG_DWORD /d 1 /f
    REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "NoStartMenuMFUprogramsList" /t REG_DWORD /d 1 /f

# Chocolatey Install + Software Installation
    Invoke-RestMethod minseochoi.tech/script/install-choco | Invoke-Expression
