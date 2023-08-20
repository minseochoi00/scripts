# ENV
    # Softwares
        $X32EDIT = "X32-Edit"
            $X32EDIT_P = ""                     # Process Name of X32-Edit
        $OBS = "OBS-Studio"
            $OBS_P = ""                         # Process Name of OBS-Studio
        $ZOOM = "Zoom"
            $ZOOM_P = ""                        # Process Name of Zoom
        $WMP = "Windows Media Player"
            $WMP_P = ""                         # Process Name of Windows Media Player
        $X32D = "X32 Driver"                    # Need to Check Name
            $X32D_P = ""                        # Process Name of -
        $SDC = "Synology Drive Client"
            $SDC_P = ""                         # Process Name of Synology Drive Client
        $YS = "Chodae YouTube Studio"
            $YS_L = ""                          # URL of Chodae YouTube Studio
        $CB = "Chodae Weekly-Paper"
            $CB_L = ""                          # URL of Chodae Weekly-Paper
        $CW = "Chodae Website"
            $CW_L = "https://chodae.church"                                     # URL of Chodae Website
        $POT = "Chodae PotCast"
            $POT_L = ""                         # URL of Chodae PotCast
        $POT_F = "Chodae PotCast MP3 Folder"
            $POT_F_P = ""                       # PATH of Chodae PotCast MP3

# Start
$mainButton = New-Button -ButtonText "Start All" -OnClick {
    Write-Host "Main Button Clicked"
}

$mainButton = New-Button -ButtonText "Start X32-Edit" -OnClick {
    Write-Host "Start X32-Edit"
}

$mainButton = New-Button -ButtonText "OBS-Studio" -OnClick {
    Write-Host "Start X32-Edit"
}

$mainButton = New-Button -ButtonText "Zoom" -OnClick {
    Write-Host "Start X32-Edit"
}

$mainButton = New-Button -ButtonText "Windows Media Player" -OnClick {
    Write-Host "Start X32-Edit"
}

$mainButton = New-Button -ButtonText "X32" -OnClick {
    Write-Host "Start X32-Edit"
}

$mainButton = New-Button -ButtonText "Synology Drive Client" -OnClick {
    Write-Host "Start X32-Edit"
}


# Create a sub-button with a sub-menu item
$subButton = New-SubButton -ButtonText "Essential" -OnClick {
    Write-Host "Sub Button Clicked"
}

<# Create a sub-menu item under the sub-button
$menuItem = New-MenuItem -ButtonText "Sub Menu Item" -OnClick {
    Write-Host "Sub Menu Item Clicked"
}
# Add the sub-menu item to the sub-button
$subButton.DropDownItems.Add($menuItem)
#>

# Display the buttons on a Windows Form
$form = New-Object Windows.Forms.Form
$form.Controls.Add($mainButton)
$form.Controls.Add($subButton)
$form.ShowDialog()