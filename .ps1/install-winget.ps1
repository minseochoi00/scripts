# Settings
function Test-WinUtil-PATH-Checker {
    <#
        .COMMENTS
        This Function is for checking Winget
    #>

    Param(
        [System.Management.Automation.SwitchParameter]$winget
    )

    if($winget){
        if (Test-Path ~\AppData\Local\Microsoft\WindowsApps\winget.exe) {
            return $true
        }
    }

    return $false
}

# Getting the computer's information
if ($null -eq $sync.ComputerInfo){
    $ComputerInfo = Get-ComputerInfo -ErrorAction Stop
} else {
    $ComputerInfo = $sync.ComputerInfo
}

# Gets the Windows Edition
$OSName = if ($ComputerInfo.OSName) {
    $ComputerInfo.OSName
} else {
    $ComputerInfo.WindowsProductName
}

# Start
    Write-Host "Checking if WinGet is installed..."

    if (Test-WinUtil-PATH-Checker -winget) {
            #Checks if winget executable exists and if the Windows Version is 1809 or higher
            Write-Host "Winget already Installed"
            Pause
            Return
    }

    if (($ComputerInfo.WindowsVersion) -lt "1809") {
        # Checks if Windows Version is too old for winget
        Write-Host "Winget is not supported on this version of Windows (Pre-1809)"
        Pause
        return
    }
    
    if (((($OSName.IndexOf("LTSC")) -ne -1) -or ($OSName.IndexOf("Server") -ne -1)) -and (($ComputerInfo.WindowsVersion) -ge "1809")) {

        Write-Host "Running Alternative Installer for LTSC/Server Editions"

        # Switching to winget-install from PSGallery from asheroto
        # Source: https://github.com/asheroto/winget-installer

        # adding the code from the asheroto repo
        Set-ExecutionPolicy RemoteSigned -Force
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
        Install-Script -Name winget-install -Force
        winget-install.ps1
                
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-command irm https://raw.githubusercontent.com/ChrisTitusTech/winutil/$BranchToUse/winget.ps1 | iex | Out-Host" -WindowStyle Normal -ErrorAction Stop

        if(!(Test-WinUtilPackageManager -winget)){
        break
    }
    
    } else {

        throw [WingetFailedInstall]::new('Failed to install')
        Write-Host "Try Installing using a browser "https://aka.ms/getwinget" "
        Pause
        Return
    }