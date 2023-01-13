#Run this with PowerShell / PowerShell ISE
Write-Host "Installing Scoop for Installation of ThisIsWin11"

# Installing Scoop
iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
Add-MpPreference -ExclusionPath "$($env:programdata)\scoop", "$($env:scoop)"

# Installing GIT & Essentials
scoop install git
scoop bucket add extras

# Installing ThisIsWin11
Write-Host "Installing ThisIsWin11-Latest"
scoop install thisiswin11

# Waiting for Uninstall of ThisIsWin11 & Scoop
Write-Host "Pausing for Uninstallation."
Write-Host "Please close ThisIsWin11 for uninstallation"
Pause

# Uninstalling Scoop
Remove-MpPreference -ExclusionPath "$($env:programdata)\scoop", "$($env:scoop)"
scoop uninstall scoop
del .\scoop -Force
