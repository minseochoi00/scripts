$DefaultPath = "C:\Data"
if (Test-Path $DefaultPath) {
    # NEED THIS LINE BELOW
    Import-Module BitsTransfer
} else {
    # Make Directory @ "C" Drive 
    mkdir "C:\Data"
    # NEED THIS LINE BELOW
    Import-Module BitsTransfer
}

$NewPath = "$DefaultPath\TIW11-Install\ThisIsWin11.exe"

Write-Host "Downloading This is Win 11"
# ONLY DOWNLOAD ThisIsWin11 on Windows 11 [ Not Funtionable in Windows 10 ]
$url="https://github.com/builtbybel/ThisIsWin11/releases/download/1.4.1/TIW11.zip"
$Path="$DefaultPath\TIW11-Install.zip"
Start-BitsTransfer -Source $url -Destination $path
Expand-Archive -Path "$DefaultPath\TIW11-Install.zip" -DestinationPath "$DefaultPath\TIW11-Install"
Start-Process "$NewPath"
