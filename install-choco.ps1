$Space = Write-Host ""
# Check if chocolatey is installed and get its version
if ((Get-Command -Name choco -ErrorAction Ignore) -and ($current_chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion)) {

    $Space

    Write-Host "Checking for Chocolatey Update"
    powershell choco upgrade chocolatey -y
    powershell choco feature enable -n allowGlobalConfirmation
    Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1
    
    $Space

    $new_chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion
    
    if ($current_chocoVersion -eq $new_chocoVersion) {
    
        Write-host "There is no chocolatey update. Chocolatey is currently up to date."
    
    } else {
    
        Write-Host "Version of chocolatey has been upgraded from '$current_chocoVersion' to '$new_chocoVersion'."
    
    }
    
    return

} else {

    $Space

    Write-Host "chocolatey is not currently installed. auto-installing chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    powershell choco feature enable -n allowGlobalConfirmation
    Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1
    
    return

}

        $Test_Choco = Get-Command -Name choco -ErrorAction Ignore

        if (-not $Test_Choco) {

        Write-Host "Error has occured while installing chocolatey."
        Pause
        
        }

return