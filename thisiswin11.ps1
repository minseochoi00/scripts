Write-Host "Downloading This is Win 11"
# ONLY DOWNLOAD ThisIsWin11 on Windows 11 [ Not Funtionable in Windows 10 ]
$url="https://github.com/builtbybel/ThisIsWin11/releases/download/1.4.1/TIW11.zip"
$Path="$DefaultPath\TIW11-Install.TIW11.zip"
Start-BitsTransfer -Source $url -Destination $path
Start-Process "$Path"
