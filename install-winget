Write-Host "Downloading Windows Package Manager"
$url="https://github.com/microsoft/winget-cli/releases/download/v1.4.10173/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
$Path="$DefaultPath\WPM-Install.msixbundle"
Start-BitsTransfer -Source $url -Destination $path
Start-Process "$Path"
