# Check if Winget is already installed
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Winget is already installed."
    exit 0
}

# Download the latest version of Winget
$wingetUrl = "https://github.com/microsoft/winget-cli/releases/download/v1.4.10173/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
$wingetFilePath = "$($env:TEMP)\winget.appxbundle"

Write-Host "Downloading Winget from $wingetUrl..."
Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetFilePath

# Install Winget
Write-Host "Installing Winget from $wingetFilePath..."
Add-AppxPackage -Path $wingetFilePath

# Check if Winget was installed successfully
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Winget installed successfully."
    # Check if Winget is working
    try {
        winget --version
    } catch {
        Write-Host "Winget is not working."
        # Remove Winget
        Remove-AppxPackage -Package Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
        Remove-Item -Path $wingetFilePath -Force
        exit 1
    }
    Remove-Item -Path $wingetFilePath -Force
    exit 0
} else {
    Write-Host "Winget installation failed."
    Remove-Item -Path $wingetFilePath -Force
    exit 1
}
