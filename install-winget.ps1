function Test-WinUtil-PATH-Checker {
    <#
        .COMMENTS
        This Function is for checking Winget or Chocolatey
    #>

    Param(
        [System.Management.Automation.SwitchParameter]$winget,
        [System.Management.Automation.SwitchParameter]$choco
    )

    if($winget){
        if (Test-Path ~\AppData\Local\Microsoft\WindowsApps\winget.exe) {
            return $true
        }
    }

    if($choco){
        if ((Get-Command -Name choco -ErrorAction Ignore) -and ($chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion)){
            return $true
        }
    }

    return $false
}


Try {
    Write-Host "Checking if WinGet is installed..."

    if (Test-WinUtil-PATH-Checker -winget) {
            #Checks if winget executable exists and if the Windows Version is 1809 or higher
            Write-Host "Winget already Installed"
            pause
            return
    }

    # Getting the computer's information
    if ($null -eq $sync.ComputerInfo){
        $ComputerInfo = Get-ComputerInfo -ErrorAction Stop
    } else {
        $ComputerInfo = $sync.ComputerInfo
    }

    if (($ComputerInfo.WindowsVersion) -lt "1809") {
        # Checks if Windows Version is too old for winget
        Write-Host "Winget is not supported on this version of Windows (Pre-1809)"
        return
    }

    # Gets the Windows Edition
    $OSName = if ($ComputerInfo.OSName) {
        $ComputerInfo.OSName
    } else {
        $ComputerInfo.WindowsProductName
    }
    
    if (((($OSName.IndexOf("LTSC")) -ne -1) -or ($OSName.IndexOf("Server") -ne -1)) -and (($ComputerInfo.WindowsVersion) -ge "1809")) {

        Write-Host "Running Alternative Installer for LTSC/Server Editions"

        # Switching to winget-install from PSGallery from asheroto
        # Source: https://github.com/asheroto/winget-installer

        # adding the code from the asheroto repo
        Set-ExecutionPolicy RemoteSigned -force
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
        Install-Script -Name winget-install -force
        winget-instal
            
            
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-command irm https://raw.githubusercontent.com/ChrisTitusTech/winutil/$BranchToUse/winget.ps1 | iex | Out-Host" -WindowStyle Normal -ErrorAction Stop

        if(!(Test-WinUtilPackageManager -winget)){
            break
        }
    } else {
        # Installing Winget from the Microsoft Store
        Write-Host "Winget not found, installing it now."
        Start-Process "ms-appinstaller:?source=https://aka.ms/getwinget"
        $nid = (Get-Process AppInstaller).Id
        Wait-Process -Id $nid

        if(!(Test-WinUtilPackageManager -winget)){
            break
        }
    }
        Write-Host "Winget Installed"
        pause
        return
}
    Catch {
    throw [WingetFailedInstall]::new('Failed to install')
}
