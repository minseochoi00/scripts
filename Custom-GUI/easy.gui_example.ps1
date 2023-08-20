# Create a main button
$mainButton = New-Button -ButtonText "Main Button" -OnClick {
    Write-Host "Main Button Clicked"
}

# Create a sub-button with a sub-menu item
$subButton = New-SubButton -ButtonText "Sub Button" -OnClick {
    Write-Host "Sub Button Clicked"
}

# Create a sub-menu item under the sub-button
$menuItem = New-MenuItem -ButtonText "Sub Menu Item" -OnClick {
    Write-Host "Sub Menu Item Clicked"
}

# Add the sub-menu item to the sub-button
$subButton.DropDownItems.Add($menuItem)

# Display the buttons on a Windows Form
$form = New-Object Windows.Forms.Form
$form.Controls.Add($mainButton)
$form.Controls.Add($subButton)
$form.ShowDialog()