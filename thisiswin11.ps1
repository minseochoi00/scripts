$DefaultPath = "C:\Data"
$Version = "1.4.1"
$NewPath = "$DefaultPath\TIW11-Install\ThisIsWin11.exe"

if (Test-Path $DefaultPath) {
    # NEED THIS LINE BELOW
    Import-Module BitsTransfer
} else {
    # Make Directory @ "C" Drive with Folder name "Data"
    mkdir "C:\Data"
    # NEED THIS LINE BELOW
    Import-Module BitsTransfer
}

Write-Host "Downloading, Extracting, Starting ThisisWin 11 Software"
# ONLY DOWNLOAD ThisIsWin11 on Windows 11 [ Not Funtionable in Windows 10 ]
$url="https://github.com/builtbybel/ThisIsWin11/releases/download/$Version/TIW11.zip"
$Path="$DefaultPath\TIW11-Install.zip"
Start-BitsTransfer -Source $url -Destination $path
Expand-Archive -Path "$DefaultPath\TIW11-Install.zip" -DestinationPath "$DefaultPath\TIW11-Install"
Start-Process "$NewPath"
