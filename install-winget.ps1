# Check if Winget is already installed
if (Get-Command winget -ErrorAction SilentlyContinue) {
    
    Write-Host "Winget is already installed."
    Write-Host ""

Try {
    # Download the latest version of Winget
    $wingetUrl = "https://github.com/microsoft/winget-cli/releases/download/v1.4.10173/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    $wingetFilePath = "$($env:TEMP)\winget.appxbundle"

    Write-Host "Downloading Winget from $wingetUrl..."
    Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetFilePath

    # Install Winget
    Write-Host "Installing Winget from $wingetFilePath..."
    Add-AppxPackage -Path $wingetFilePath
}

# Check if Winget was installed successfully
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Winget installed successfully."
        # Check if Winget is working
    }
        try {
         winget --version
        } catch {
            Write-Host "Winget is not working."
            Write-Host "Trying Alternate Installation"
        }

Try {
        Write-Host "Checking if Winget is Installed..."
        if (Test-WinUtilPackageManager -winget) {
            #Checks if winget executable exists and if the Windows Version is 1809 or higher
            Write-Host "Winget Already Installed"
            return
        }

        #Gets the computer's information
        if ($null -eq $sync.ComputerInfo){
            $ComputerInfo = Get-ComputerInfo -ErrorAction Stop
        }
        Else {
            $ComputerInfo = $sync.ComputerInfo
        }

        if (($ComputerInfo.WindowsVersion) -lt "1809") {
            #Checks if Windows Version is too old for winget
            Write-Host "Winget is not supported on this version of Windows (Pre-1809)"
            return
        }

        #Gets the Windows Edition
        $OSName = if ($ComputerInfo.OSName) {
            $ComputerInfo.OSName
        }else {
            $ComputerInfo.WindowsProductName
        }

        if (((($OSName.IndexOf("LTSC")) -ne -1) -or ($OSName.IndexOf("Server") -ne -1)) -and (($ComputerInfo.WindowsVersion) -ge "1809")) {

            Write-Host "Running Alternative Installer for LTSC/Server Editions"

            # Switching to winget-install from PSGallery from asheroto
            # Source: https://github.com/asheroto/winget-installer

            Start-Process powershell.exe -Verb RunAs -ArgumentList "-command irm https://raw.githubusercontent.com/ChrisTitusTech/winutil/$BranchToUse/winget.ps1 | iex | Out-Host" -WindowStyle Normal -ErrorAction Stop

            if(!(Test-WinUtilPackageManager -winget)){
                break
            }
        }

        else {
            #Installing Winget from the Microsoft Store
            Write-Host "Winget not found, installing it now."
            Start-Process "ms-appinstaller:?source=https://aka.ms/getwinget"
            $nid = (Get-Process AppInstaller).Id
            Wait-Process -Id $nid

            if(!(Test-WinUtilPackageManager -winget)){
                break
            }
        }
    }
}

# Check if Winget was installed successfully
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Winget installed successfully."
        # Check if Winget is working
    }
        try {
         winget --version
        } catch {
            Write-Host "Winget is not working or installation has been failed."
        }
