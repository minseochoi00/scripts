# Function to check if WinGet is installed
function Test-WinUtil-PATH-Checker {
    <#
        .COMMENTS
        This Function checks if Winget is installed
    #>

    Param(
        [System.Management.Automation.SwitchParameter]$winget
    )

    if ($winget) {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            return $true
        }
    }

    return $false
}

# Getting the computer's information
$ComputerInfo = Get-ComputerInfo -ErrorAction Stop

# Gets the Windows Edition
$OSName = $ComputerInfo.OSName ?? $ComputerInfo.WindowsProductName

# Start
Write-Host "Checking if WinGet is installed..."

if (Test-WinUtil-PATH-Checker -winget) {
    Write-Host "WinGet is already installed."
    Pause
    return
}

if ([int]$ComputerInfo.WindowsVersion -lt 1809) {
    Write-Host "WinGet is not supported on this version of Windows (Pre-1809)."
    Pause
    return
}

if ($OSName -match "LTSC|Server") {
    Write-Host "Running Alternative Installer for LTSC/Server Editions"

    # Install dependencies
    Set-ExecutionPolicy RemoteSigned -Force
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    Install-Script -Name winget-install -Force

    # Run the installer
    & "$env:ProgramFiles\WindowsPowerShell\Scripts\winget-install.ps1"

    Start-Process powershell.exe -Verb RunAs -ArgumentList "-command irm https://raw.githubusercontent.com/ChrisTitusTech/winutil/$BranchToUse/winget.ps1 | iex | Out-Host" -WindowStyle Normal -ErrorAction Stop

    if (!(Test-WinUtil-PATH-Checker -winget)) {
        Write-Host "WinGet installation failed. Please try manually: https://aka.ms/getwinget"
        Pause
        return
    }
} else {
    throw "Failed to install WinGet."
}
