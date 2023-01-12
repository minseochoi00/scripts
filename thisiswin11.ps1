Write-Host "Installing Scoop for Installation of ThisIsWin11"
iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
Add-MpPreference -ExclusionPath "$($env:programdata)\scoop", "$($env:scoop)"
scoop install git
scoop bucket add extras
Write-Host "Installing ThisIsWin11-Latest"
scoop install thisiswin11
Remove-MpPreference -ExclusionPath "$($env:programdata)\scoop", "$($env:scoop)"
scoop uninstall scoop
del .\scoop -Force
