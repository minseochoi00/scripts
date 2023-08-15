Clear-Host
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\force-mkdir.psm1 -ea Ignore
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\take-own.psm1 -ea Ignore
$ErrorActionPreference = "SilentlyContinue"  # Suppresses error messages

Write-Host -NoNewline "Stopping OneDrive process"
    Start-Process -FilePath "taskkill" -ArgumentList '/f /im "OneDrive.exe"' -Verb RunAs -ea Stop -Wait
    if (Get-Process -Name explorer -ea SilentlyContinue) { Start-Process -FilePath "taskkill" -ArgumentList '/f /im "explorer.exe"' -Verb RunAs -ea Stop -Wait }
    if (-not(Get-Process -Name Explorer -ea SilentlyContinue)) { Write-Host " (Stopped)"} else { Write-Host " (Failed)"}

Write-Host -NoNewLine "Uninstalling OneDrive Software"
    if (Test-Path "$env:systemroot\System32\OneDriveSetup.exe") {
        Write-Host " (Found: Starting)"
        & "$env:systemroot\System32\OneDriveSetup.exe" /uninstall
    } elseif (Test-Path "$env:systemroot\SysWOW64\OneDriveSetup.exe") {
        Write-Host " (Found: Starting)"
    & "$env:systemroot\SysWOW64\OneDriveSetup.exe" /uninstall
    } else {
        Write-Host " (Failed)"
    }

Write-Host -NoNewline "Removing OneDrive leftovers"
    try {
    Remove-Item -Recurse -Force -ea SilentlyContinue "$env:localappdata\Microsoft\OneDrive"
    Remove-Item -Recurse -Force -ea SilentlyContinue "$env:programdata\Microsoft OneDrive"
    Remove-Item -Recurse -Force -ea SilentlyContinue "$env:systemdrive\OneDriveTemp"
    Write-Host " (Removed)"
    }
    catch { Write-Host " (Failed)" }

# check if directory is empty before removing:
    If ((Get-ChildItem "$env:userprofile\OneDrive" -Recurse | Measure-Object).Count -eq 0) { 
        Remove-Item -Recurse -Force -ea SilentlyContinue "$env:userprofile\OneDrive" }

Write-Host -NoNewline "Disable OneDrive via Group Policies"
    $ErrorActionPreference = "SilentlyContinue"  # Suppresses error messages
    $regPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\OneDrive"
# Create the registry path if it doesn't exist
    if (!(Test-Path -Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    # Set the registry value to disable OneDrive file synchronization
    try {
        Set-ItemProperty -Path $regPath -Name "DisableFileSyncNGSC" -Value 1 -ErrorAction Stop
        Write-Host " (Successful)"
    } catch {
        Write-Host " (Failed: to disable)"
    }

Write-Host -NoNewLine "Remove Onedrive from explorer sidebar"
    try { 
        New-PSDrive -PSProvider "Registry" -Root "HKEY_CLASSES_ROOT" -Name "HKCR" -Scope Global -ea SilentlyContinue
        $regPath = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
            if (!(Test-Path -Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        # Set the registry value to disable OneDrive file synchronization
            try {
            Set-ItemProperty -Path $regPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -ErrorAction Stop
            Write-Host -NoNewLine " (Successful 1, "
            } catch { Write-Host -NoNewLine " (Failed: to disable 1, "}
        $regPath = "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
            if (!(Test-Path -Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        # Set the registry value to disable OneDrive file synchronization
        try {
            Set-ItemProperty -Path $regPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -ErrorAction Stop
            Write-Host "Successful 2)"
        } catch { Write-Host "Failed: to disable 2)"}
        } 
        catch { Write-Host " (Failed)" }

Write-Host -NoNewline "Removing run hook for new users"
    try {
    Start-Process -FilePath reg -ArgumentList 'load "hku\Default" "C:\Users\Default\NTUSER.DAT"' -Verb RunAs -ea Stop -Wait
    Start-Process -FilePath reg -ArgumentList 'delete "HKEY_USERS\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f' -Verb RunAs -ea Stop -Wait
    Start-Process -FilePath reg -ArgumentList 'unload "hku\Default"' -Verb RunAs -ea Stop -Wait
    Write-Host " (Removed)"
    }
    catch { Write-Host " (Failed)" }

Write-Host -NoNewline "Removing startmenu entry"
    try {
    Remove-Item -Force -ea SilentlyContinue "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"
    Write-Host " (Removed)"
    }
    catch { Write-Host " (Failed)" }    

Write-Host -NoNewline "Removing scheduled task"
    try {
    Start-Process -FilePath reg -ArgumentList 'unload "hku\Default"' -Verb RunAs -ea Stop
    foreach ($Task in (Get-ScheduledTask -TaskPath '\' -TaskName 'OneDrive*' -ea Stop)) { Unregister-ScheduledTask -Confirm:$false }
    Write-Host " (Removed)"
    }
    catch { Write-Host " (Failed)" }

# Starting File Explorer
    Write-Host -NoNewLine "Re-starting Windows Explorer..."
    if (-not(Get-Process -Name Explorer -ea SilentlyContinue)) { Start-Process Explorer.exe}
    Start-Sleep 10
    if (Get-Process -Name Explorer -ea SilentlyContinue) { Write-Host " (Started)"} else { Write-Host " (Failed: Start)"}

Write-Host -NoNewLine "Removing additional OneDrive leftovers"
    if (Test-Path "$env:WinDir\WinSxS\*onedrive*") {
    foreach ($item in (Get-ChildItem "$env:WinDir\WinSxS\*onedrive*")) 
    { Remove-Item -Recurse -Force $item.FullName -ea SilentlyContinue }
    Write-Host " (Removed)"
    } else { Write-Host " (Failed)" }

return