Install-Module -Name AudioDeviceCmdlets
Import-Module -Name AudioDeviceCmdlets

$deviceFound = $null
$targetDeviceID = $null
$audioDevices = $null
$ProPresenterPATH = $null
$PP = $null
$directoryPath = $null

$targetDeviceID = ""
$audioDevices = (Get-AudioDevice -List).ID
$deviceFound = $false
$ProPresenterPATH = "C:\Program Files\Renewed Vision\ProPresenter\ProPresenter.exe"
$PP = "ProPresenter"
$directoryPath = "$env:APPDATA\.wcdc"

if (-not (Test-Path -Path $directoryPath -PathType Container)) {
    # Directory doesn't exist; create it
    New-Item -Path $directoryPath -ItemType Directory
}


Stop-Process -Name $PP -Force -ea SilentlyContinue


foreach ($deviceID in $audioDevices) {
    if ($deviceID -eq $targetDeviceID) {
            $deviceFound = $true
        # Set my $targetDeviceID to Default
            Set-AudioDevice -ID $targetDeviceID -DefaultOnly
        # Set my $targetDeviceID to Communication Only
            Set-AudioDevice -ID $targetDeviceID -CommunicationOnly
        # Set Playback Audio Interface Mute toggle to OFF
            Set-AudioDevice -PlaybackMute $false
        # Set Playback Audio Interface's Volume to 75
            Set-AudioDevice -PlaybackVolume 75
        # Logging to $AppDATA    
            $date = Get-Date
            $message = "$date - Success: Changed Audio Device to Default"
            $message | Out-File -Append -FilePath "$env:APPDATA\.wcdc\log.txt"
        # Exit the loop since the device was found
            break  
        }
}

if (-not $deviceFound) {
    $date = Get-Date
    $message = "$date - Fail: USB Audio not detected."
    $message | Out-File -Append -FilePath "$env:APPDATA\.wcdc\log.txt"
}

if (Test-Path -Path $ProPresenterPATH) {
    Start-Process $ProPresenterPATH
    $date = Get-Date
    $message = "$date - Success: Started ProPresenter"
    $message | Out-File -Append -FilePath "$env:APPDATA\.wcdc\log.txt"
} else {
    $date = Get-Date
    $message = "$date - Fail: Started ProPresenter"
    $message | Out-File -Append -FilePath "$env:APPDATA\.wcdc\log.txt"
}
