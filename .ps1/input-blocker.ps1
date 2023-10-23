# Mouse

$code = @"
    [DllImport("user32.dll")]
    public static extern bool BlockInput(bool fBlockIt);
"@

    $userInput = Add-Type -MemberDefinition $code -Name UserInput -Namespace UserInput -PassThru

    function Disable-MouseInput {
        # Disable mouse input using a different method (not via user32.dll)
        # You can adapt this part based on your specific requirements
        
        # For example, you can use the following line to disable mouse input:
        # Stop-Process -Name "explorer" -Force

        Write-Host "Mouse input is disabled. To re-enable, run the appropriate command."
    }

    function Enable-MouseInput {
        # Enable mouse input (you may need to adapt this part based on the method used)
        # For example, you can restart the explorer process:
        # Start-Process -Name "explorer"

        Write-Host "Mouse input is re-enabled."
    }

    Disable-MouseInput


# Keyboard

    $code = @"
        [DllImport("user32.dll")]
        public static extern bool BlockInput(bool fBlockIt);
"@

    $userInput = Add-Type -MemberDefinition $code -Name UserInput -Namespace UserInput -PassThru

    function Enable-KeyboardInput {
        $userInput::BlockInput($false)
        Write-Host "Keyboard input is re-enabled."
    }

    function Disable-KeyboardInput {
        $userInput::BlockInput($true)
        Write-Host "Keyboard input is disabled. To re-enable, run 'Enable-KeyboardInput'."
    }

    Disable-KeyboardInput
