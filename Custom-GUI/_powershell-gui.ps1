﻿# Setting
    $version = "v1.0"
    $logoPath = "logo.ico"
    $Button1_Name = 'Configuration'
    $Button2_Name = 'Maintenance'
    $Button3_Name = 'Extras'
    $C_Button4_Name = 'Network IP Renewal'
    $C_Button5_Name = 'Print Spooler Fix'

# Features
    # .Net methods for hiding/showing the console in the background
    Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
    '

    function Show-Console
    {
        $consolePtr = [Console.Window]::GetConsoleWindow()

        # Hide = 0,
        # ShowNormal = 1,
        # ShowMinimized = 2,
        # ShowMaximized = 3,
        # Maximize = 3,
        # ShowNormalNoActivate = 4,
        # Show = 5,
        # Minimize = 6,
        # ShowMinNoActivate = 7,
        # ShowNoActivate = 8,
        # Restore = 9,
        # ShowDefault = 10,
        # ForceMinimized = 11

        [Console.Window]::ShowWindow($consolePtr, 4)
    }

    function Hide-Console
    {
        $consolePtr = [Console.Window]::GetConsoleWindow()
        #0 hide
        [Console.Window]::ShowWindow($consolePtr, 0)
    }


# Start

Add-Type -AssemblyName System.Windows.Forms

# Create a new form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Toolkit $version"
$Form.Size = New-Object System.Drawing.Size(500,250)
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$Form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

# Load an image from the same directory as the script
    $ImagePath = Join-Path $PSScriptRoot $logoPath
    $Icon = New-Object System.Drawing.Icon($ImagePath)
    # Set the form's icon to the loaded image
    $Form.Icon = $Icon

# Button Name Setting

# Button 1
    # Create three buttons
    $Button1 = New-Object System.Windows.Forms.Button
    $Button1.Location = New-Object System.Drawing.Point(50, 20)
    $Button1.Size = New-Object System.Drawing.Size(100, 30)
    $Button1.Text = $Button1_Name
    $Button1.Add_Click({
    
        # Change the button color to red
        $Button1.BackColor = 'Red'

        # Update the label
        $Label.Text = "Currently running script on button 1"

        # Code to run when Button 1 is clicked
        $betaPath = Join-Path $PSScriptRoot $1_Script
        $result = & $betaPath
        if ($result -is [System.Management.Automation.ErrorRecord]) {
            Write-Host "There was an error running the script!"
        }

    # Update the label to indicate which button finished running its script
    $Label.Text = "Button 1 finished running its script."

    $Button1.BackColor = 'White'
})

# Button2
    $Button2 = New-Object System.Windows.Forms.Button
    $Button2.Location = New-Object System.Drawing.Point(50, 60)
    $Button2.Size = New-Object System.Drawing.Size(100, 30)
    $Button2.Text = $Button2_Name
    $Button2.Add_Click({
        # Change the button color to red
        $Button2.BackColor = 'Red'

        # Change the button color back to blue after the code is finished running
        $Button2.BackColor = 'Blue'

        # Update the label to indicate which button finished running its script
        $Label.Text = "Button 2 finished running its script."

        $Button2.BackColor = 'White'
    })

# Extras
    $Button3 = New-Object System.Windows.Forms.Button
    $Button3.Location = New-Object System.Drawing.Point(50, 100)
    $Button3.Size = New-Object System.Drawing.Size(100, 30)
    $Button3.Text = $Button3_Name
    $Button3.Add_Click({
        # Change the button color to red
        $Extra_Button.BackColor = 'Red'
    
        # Code to run when Button 3 is clicked
        $ExtraForm = New-Object System.Windows.Forms.Form
        $ExtraForm.Text = "Extra Toolkits"
        $ExtraForm.Size = New-Object System.Drawing.Size(300,400)
        $ExtraForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
        $ExtraForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
        $ExtraForm.ControlBox = $false

        # Load an image from the same directory as the script
        $ImagePath = Join-Path $PSScriptRoot $logoPath
        $Icon = New-Object System.Drawing.Icon($ImagePath)
        # Set the form's icon to the loaded image
        $ExtraForm.Icon = $Icon

        # Create a label to display which button finished running its script
            $Label = New-Object System.Windows.Forms.Label
            $Label.Location = New-Object System.Drawing.Point(100, 0)
                $Label.Size = New-Object System.Drawing.Size(100, 100)
            $Label.Text = "Waiting..."
            $Label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
            $Form.Controls.Add($Label)

        # Network IP Renewal
            $Network_IP_Button = New-Object System.Windows.Forms.Button
            $Network_IP_Button.Location = New-Object System.Drawing.Point(100, 80)
            $Network_IP_Button.Size = New-Object System.Drawing.Size(100, 50)
            $Network_IP_Button.Text = $C_Button4_Name
            $Network_IP_Button.Add_Click({
                # Code to run when the child button is clicked
                $Network_IP_Button.BackColor = 'Red'
                $Label.Text = "Renewing IP Address"
                ipconfig /release
                ipconfig /flushdns
                ipconfig /renew
                $Label.Text = "Finished"
                $Network_IP_Button.BackColor = 'Green'
            })

        # Print Spooler Fix
            $Spooler_Button = New-Object System.Windows.Forms.Button
            $Spooler_Button.Location = New-Object System.Drawing.Point(100, 150)
            $Spooler_Button.Size = New-Object System.Drawing.Size(100, 50)
            $Spooler_Button.Text = $C_Button5_Name
            $Spooler_Button.Add_Click({
                # Code to run when the child button is clicked
                $Spooler_Button.BackColor = 'Red'
                irm minseochoi.tech/script/fix-spooler | iex
                $Spooler_Button.BackColor = 'Green'
            })

        # Create a back button to return to the main form
            $BackButton = New-Object System.Windows.Forms.Button
            $BackButton.Location = New-Object System.Drawing.Point(100, 300)
            $BackButton.Size = New-Object System.Drawing.Size(100, 30)
            $BackButton.Text = "Back"
            $BackButton.Add_Click({
                $Extra_Button.BackColor = 'White'
                $ExtraForm.Close()
            })

    # Finialize List
        $ExtraForm.Controls.Add($Network_IP_Button)
        $ExtraForm.Controls.Add($Spooler_Button)
        $ExtraForm.Controls.Add($Label)
        $ExtraForm.Controls.Add($BackButton)

        $ExtraForm.ShowDialog()
    })

# Create a label to display which button finished running its script
    $Label = New-Object System.Windows.Forms.Label
    $Label.Location = New-Object System.Drawing.Point(200, 50)
    $Label.Size = New-Object System.Drawing.Size(250, 100)
    $Label.Text = "Click a button to run a script."
    $Label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $Form.Controls.Add($Label)

# Add the buttons to the form
    $Button1.Location = New-Object System.Drawing.Point(50,50)
    $Button2.Location = New-Object System.Drawing.Point(50,90)
    $Button3.Location = New-Object System.Drawing.Point(50,130)
    $Form.Controls.Add($Button1)
    $Form.Controls.Add($Button2)
    $Form.Controls.Add($Button3)

Hide-Console

# Show the form
    $Form.ShowDialog() | Out-Null