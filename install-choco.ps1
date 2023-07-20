# Check if chocolatey is installed and get its version
if ((Get-Command -Name choco -ErrorAction Ignore) -and ($current_chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion)) {

    Write-Host ""

    Write-Host "Checking for Chocolatey Update"
    Start-Process -FilePath PowerShell -ArgumentList 'choco upgrade chocolatey -y' -Verb RunAs
    powershell choco feature enable -n allowGlobalConfirmation
    Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1
    refreshenv
    
    Write-Host ""

    $new_chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion
    
    if ($current_chocoVersion -eq $new_chocoVersion) { Write-host "There is no chocolatey update. Chocolatey is currently up to date." } 
    else { Write-Host "Version of chocolatey has been upgraded from '$current_chocoVersion' to '$new_chocoVersion'." }
    return

} else {

    Write-Host ""

    Write-Host "Chocolatey is not currently installed. Installing chocolatey..."
    Start-Process -FilePath PowerShell -ArgumentList 'Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))' -Verb RunAs
    choco feature enable -n allowGlobalConfirmation
    Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1
    refreshenv
    return

}

$Test_Choco = Get-Command -Name choco -ErrorAction Ignore
if (-not $Test_Choco) {
    Write-Host "Error has occured while installing chocolatey."
    Pause
}

return