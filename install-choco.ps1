# Check if chocolatey is installed and get its version
if ((Get-Command -Name choco -ErrorAction Ignore) -and ($chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion)) {

    Write-Output ""
    Write-Output "Checking for Chocolatey Update"
    powershell choco feature enable -n allowGlobalConfirmation
    powershell choco upgrade chocolatey -y
    Write-Output ""
    Write-Output "Chocolatey Version $chocoVersion is already installed or has been updated"

    Pause
    Return

} else {

    Write-Output ""
    Write-Output "Seems Chocolatey is not installed, installing now"
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    powershell choco feature enable -n allowGlobalConfirmation

    Pause
    Return

} elseif {
    
    Try {

        Get-Command -Name choco

    }

    catch {

        Write-Host "Error has occured while installing chocolatey."
        Pause
        Return

    }
}