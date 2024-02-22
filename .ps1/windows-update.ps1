# Import the PSWindowsUpdate module
Import-Module PSWindowsUpdate

# Function to get and install updates
function Perform-Updates {
    # Get a list of all available updates, excluding drivers
    $AvailableUpdates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -Category "Critical Updates","Security Updates" -NotCategory "Drivers"

    if ($AvailableUpdates.Count -gt 0) {
        Write-Host "There are $($AvailableUpdates.Count) updates available. Do you want to proceed with installation? (Y/N/Skip)"
        $UserDecision = Read-Host
        switch ($UserDecision) {
            "Y" {
                # Install the updates
                Install-WindowsUpdate -Update $AvailableUpdates -AcceptAll -IgnoreReboot
                # Uncomment the following line if you want to reboot automatically after updates
                # Restart-Computer -Force
            }
            "N" {
                Write-Host "Update process aborted by the user."
                return $false
            }
            "Skip" {
                Write-Host "Skipping updates..."
                return $true
            }
            default {
                Write-Host "Invalid option selected, stopping."
                return $false
            }
        }
    } else {
        Write-Host "No updates are available."
    }
    return $true
}

# Call the Perform-Updates function
$ContinueWithScript = Perform-Updates

# Check if we should continue with the rest of the script
if ($ContinueWithScript) {
    # Continue with other tasks or scripts
    Write-Host "Continuing with other parts of the script..."
    # Add your additional script or command executions here
} else {
    Write-Host "The script has stopped based on user decision."
}
