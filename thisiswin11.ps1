Write-Host "Installing Scoop for Installation of ThisIsWin11"
iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
scoop bucket add extras
Write-Host "Installing ThisIsWin11-Latest"
scoop install thisiswin11
