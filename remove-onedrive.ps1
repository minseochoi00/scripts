Import-Module -DisableNameChecking $PSScriptRoot\..\lib\force-mkdir.psm1 -ea Ignore
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\take-own.psm1 -ea Ignore

Write-Output "Kill OneDrive process"
    Start-Process -FilePath "taskkill" -ArgumentList '/f /im "OneDrive.exe"' -Verb RunAs -ea SilentlyContinue
    Start-Process -FilePath "taskkill" -ArgumentList '/f /im "explorer.exe"' -Verb RunAs -ea SilentlyContinue

Write-Output -NoNewLine "Remove OneDrive"
    if (Test-Path "$env:systemroot\System32\OneDriveSetup.exe") {
        Write-Host " (Found)"
        & "$env:systemroot\System32\OneDriveSetup.exe" /uninstall
    } elseif (Test-Path "$env:systemroot\SysWOW64\OneDriveSetup.exe") {
        Write-Host " (Found)"
    & "$env:systemroot\SysWOW64\OneDriveSetup.exe" /uninstall
    } else {
        Write-Host " (Failed: Can't be found)"
    }

Write-Output "Removing OneDrive leftovers"
    Remove-Item -Recurse -Force -ea SilentlyContinue "$env:localappdata\Microsoft\OneDrive"
    Remove-Item -Recurse -Force -ea SilentlyContinue "$env:programdata\Microsoft OneDrive"
    Remove-Item -Recurse -Force -ea SilentlyContinue "$env:systemdrive\OneDriveTemp"

# check if directory is empty before removing:
    If ((Get-ChildItem "$env:userprofile\OneDrive" -Recurse | Measure-Object).Count -eq 0) { Remove-Item -Recurse -Force -ea SilentlyContinue "$env:userprofile\OneDrive" }

Write-Output -NoNewLine "Disable OneDrive via Group Policies"
    mkdir -Force "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\OneDrive"
    # Using [void] to suppress output
    try {
        [void](Set-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" 1)
        Write-Host " (Successful)"
    } catch { Write-Host " (Failed)" }

Write-Output -NoNewLine "Remove Onedrive from explorer sidebar"
    New-PSDrive -PSProvider "Registry" -Root "HKEY_CLASSES_ROOT" -Name "HKCR"
    mkdir -Force "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    try {
        Set-ItemProperty "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0
        Write-Host " (Successful 1)"
    } catch { Write-Host " (Failed 1)" }
    mkdir -Force "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    try {
        Set-ItemProperty "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0
        Write-Host " (Successful 1)"
    } catch { Write-Host " (Failed 1)" }
    Remove-PSDrive "HKCR"

Write-Output "Removing run hook for new users"
    Start-Process -FilePath reg -ArgumentList 'load "hku\Default" "C:\Users\Default\NTUSER.DAT"' -Verb RunAs -ea SilentlyContinue
    Start-Process -FilePath reg -ArgumentList 'delete "HKEY_USERS\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f' -Verb RunAs -ea SilentlyContinue
    Start-Process -FilePath reg -ArgumentList 'unload "hku\Default"' -Verb RunAs -ea SilentlyContinue

Write-Output "Removing startmenu entry"
    Remove-Item -Force -ea SilentlyContinue "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"

Write-Output "Removing scheduled task"
    Start-Process -FilePath reg -ArgumentList 'unload "hku\Default"' -Verb RunAs -ea SilentlyContinue
    foreach ($Task in (Get-ScheduledTask -TaskPath '\' -TaskName 'OneDrive*' -ea SilentlyContinue)) { Unregister-ScheduledTask -Confirm:$false }

Write-Output "Restarting explorer"
    Start-Process "explorer.exe"

Write-Output "Waiting for explorer to complete loading"
    Start-Sleep 10

Write-Output "Removing additional OneDrive leftovers"
    foreach ($item in (Get-ChildItem "$env:WinDir\WinSxS\*onedrive*")) { Remove-Item -Recurse -Force $item.FullName -ea SilentlyContinue }