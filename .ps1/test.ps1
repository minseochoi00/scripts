# Load the Windows.Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object Windows.Forms.Form
$form.Text = "Idle Timer Form"
$form.Size = New-Object Drawing.Size(300, 100)

# Create a label for displaying idle time
$label = New-Object Windows.Forms.Label
$label.Text = "Idle Time: 0 seconds"
$label.Location = New-Object Drawing.Point(10, 10)
$form.Controls.Add($label)

# Define the idle threshold in seconds (5 seconds in this case)
$idleThreshold = 5

# Script to run when idle
$scriptToRun = {
    $label.Text = "Idle Time: $idleThreshold seconds. Running your script..."
    # Add your script code here that you want to run when idle
}

# Add an event handler for the form's Load event
$form.Add_Load({
    # Start a timer to monitor idle time
    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 1000  # Check idle time every second
    $timer.Add_Tick({
        $idleTime = [System.Windows.Forms.Application]::IdleTime.TotalSeconds
        $label.Text = "Idle Time: $idleTime seconds"

        if ($idleTime -ge $idleThreshold) {
            # Execute the script when idle
            Invoke-Command -ScriptBlock $scriptToRun
        }
    })
    $timer.Start()
})

# Show the form
$form.ShowDialog()

# Clean up when the form is closed
$form.Dispose()
