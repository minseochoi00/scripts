# Env
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $GetChocoCommand = Get-Command -Name choco -ErrorAction Ignore
    $current_chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion

function Install {
    param (
        [string]$Apps,
        [string]$Arguments
    )
    if ($isAdmin){
        if ($null -ne $Arguments -and $Arguments -ne "") {
            try {
                Start-Process -FilePath "$Apps" -ArgumentList ($Arguments -split " ") -Verb RunAs -WindowStyle Hidden -Wait
            } catch { 
                # Write-Host " (Failed: Installation of $Apps)"
                Write-Host "Error Installing: $_" 
            }
        } else {
            try {
                Start-Process -FilePath "$Apps" -Verb RunAs -WindowStyle Hidden -Wait
            } catch {
                # Write-Host " (Failed: Installation of $Apps)"
                Write-Host "Error Installing: $_" 
            }
        }
    } else {
        Write-Host " (Failed: Permission)"
    }
}

if ($isAdmin) {
    if (($GetChocoCommand) -and ($current_chocoVersion)) {
        Write-Host ""
        Write-Host "Chocolatey: Installed | Checking for Updates."
            # Checking for Updates for Chocolatey
            choco upgrade chocolatey -y
            # Enable Chocolatey Feature that allows you to install without argument -y or --confirm
            choco feature enable -n allowGlobalConfirmation
            # Import Powershell Module that allows you to refresh environment
            Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
            # Command: Refresh Envirmonment
            refreshenv
        Write-Host ""

        # Checking if Version has been updated.
            $new_chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion
            if ($current_chocoVersion -eq $new_chocoVersion) { Write-host "There is no chocolatey update. Chocolatey is currently up to date." }
            elseif ($null -eq $new_chocoVersion) { Write-Host "Chocolatey has not been successfully installed."}
            else { Write-Host "Version of chocolatey has been upgraded from '$current_chocoVersion' to '$new_chocoVersion'." }
        return

    } else {

        Write-Host ""

        Write-Host "Chocolatey: Not Installed | Starting Auto-Installer."
            Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            # Enable Chocolatey Feature that allows you to install without argument -y or --confirm
            choco feature enable -n allowGlobalConfirmation
            # Import Powershell Module that allows you to refresh environment
            Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
            # Command: Refresh Envirmonment
            refreshenv
        Write-Host ""
        return

    }

    $Test_Choco = Get-Command -Name choco -ErrorAction Ignore
        if (-not ($Test_Choco)) { Write-Host "Failed: Install Chocolatey."; pause }

} else {
    Write-Host "Chocolatey can not be installed without Administrator Previlage."
    return
}