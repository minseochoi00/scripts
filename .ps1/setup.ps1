Clear-Host

# --------------------- ENV Configuration ---------------------
    # Ensure the script is running with administrative privileges
        if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Write-Host "This script requires administrative privileges. Please run it as an administrator." -ForegroundColor Red
            exit
        }

    # Check if the operating system is 64-bit (AMD64)
        if ($env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
            Write-Host "This setup has been stopped" -ForegroundColor Red
            Write-Host ""
            Write-Host "Current: $env:PROCESSOR_ARCHITECTURE"
            Write-Host "Required: AMD64"
            Write-Host ""
            pause
            exit
        }

    # One-Drive Uninstallation
        $modules = @("force-mkdir.psm1", "take-own.psm1")
        foreach ($module in $modules) {
            $modulePath = Join-Path -Path "$PSScriptRoot\..\lib" -ChildPath $module
            if (Test-Path $modulePath) {
                Import-Module -DisableNameChecking $modulePath -ErrorAction Stop
            } else {
                Write-Host "Warning: Module $module not found. Skipping..."
            }
        }
        function Restart-Explorer {
            Stop-Process -Name Explorer -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Start-Process "explorer.exe"
            Write-Host "Windows Explorer restarted."
        }
        $ErrorActionPreference = "SilentlyContinue"
    
    # Suppress Progress Bars
        $ProgressPreference = 'SilentlyContinue'

    # Suppress Verbose and Debug Outputs:
        $VerbosePreference = 'SilentlyContinue'
        $DebugPreference = 'SilentlyContinue'

    # Desired NTP server
        $desiredNtpServer = "time.nist.gov"


# --------------------- SSH Configuration ---------------------
    # Check if OpenSSH Server is installed
        $sshCapability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
        if ($sshCapability.State -ne 'Installed') {
            Write-Host "Installing OpenSSH Server..."
            dism /Online /Add-Capability /CapabilityName:OpenSSH.Server~~~~0.0.1.0 | Out-Null
        } else {
            Write-Host "OpenSSH Server is already installed."
        }

    # Ensure SSHD service is started and set to automatic
        $sshdService = Get-Service -Name sshd -ErrorAction SilentlyContinue
        if ($sshdService -and $sshdService.Status -ne 'Running') {
            Write-Host "Starting SSHD service..."
            Start-Service sshd
        } else {
            Write-Host "SSHD service is already running."
        }
        Set-Service -Name sshd -StartupType 'Automatic'

    # Ensure SSH-Agent service is started and set to automatic
        $sshAgentService = Get-Service -Name ssh-agent -ErrorAction SilentlyContinue
        if ($sshAgentService -and $sshAgentService.Status -ne 'Running') {
            Write-Host "Starting SSH-Agent service..."
            Start-Service ssh-agent
        } else {
            Write-Host "SSH-Agent service is already running."
        }
        Set-Service -Name ssh-agent -StartupType 'Automatic'

    # Ensure firewall rule is added for SSHD
        if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
            Write-Host "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
            New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
        } else {
            Write-Host "Firewall rule 'OpenSSH-Server-In-TCP' already exists."
        }

# --------------------- Remote Desktop Configuration ---------------------
    # Enable Remote Desktop via registry setting
        $rdpRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
        $rdpStatus = (Get-ItemProperty -Path $rdpRegistryPath -Name fDenyTSConnections -ErrorAction SilentlyContinue).fDenyTSConnections
        if ($rdpStatus -eq 1) {
            Set-ItemProperty -Path $rdpRegistryPath -Name fDenyTSConnections -Value 0
            Write-Host "Remote Desktop has been enabled in the registry."
        } else {
            Write-Host "Remote Desktop is already enabled in the registry."
        }

    # Ensure Remote Desktop Services (TermService) is running and set to automatic
        $rdpService = Get-Service -Name TermService -ErrorAction SilentlyContinue
        if ($rdpService) {
            if ($rdpService.Status -ne 'Running') {
                Write-Host "Starting Remote Desktop Services..."
                Start-Service TermService
            } else {
                Write-Host "Remote Desktop Services are already running."
            }
            Set-Service -Name TermService -StartupType Automatic
        } else {
            Write-Host "Remote Desktop Services (TermService) not found."
        }

    # Add firewall rule for Remote Desktop (TCP port 3389)
        if (-not (Get-NetFirewallRule -Name "RemoteDesktop-UserMode-In-TCP" -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -Name "RemoteDesktop-UserMode-In-TCP" -DisplayName "Remote Desktop (TCP-In)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 3389
            Write-Host "Firewall rule for Remote Desktop added."
        } else {
            Write-Host "Firewall rule for Remote Desktop already exists."
        }

    # --------------------- ICMP (Ping) Firewall Rule ---------------------
        if (-not (Get-NetFirewallRule -Name "ICMPv4-In" -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -Name "ICMPv4-In" -DisplayName "Allow ICMPv4-In" -Protocol ICMPv4 -IcmpType 8 -Enabled True -Direction Inbound -Action Allow
            Write-Host "Firewall rule for ICMP (ping) added."
        } else {
            Write-Host "Firewall rule for ICMP (ping) already exists."
        }

# --------------------- NTP Configuration ---------------------
    # Retrieve current NTP server configuration from the registry
        $currentNtp = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -ErrorAction SilentlyContinue).NtpServer

        if ($null -eq $currentNtp -or $currentNtp -notmatch $desiredNtpServer) {
            Write-Host "Configuring Windows Time service." -ForegroundColor Cyan
            
            # Configure the time service to use the desired NTP server
            w32tm /config /manualpeerlist:$desiredNtpServer /syncfromflags:manual /update | Out-Null
            Restart-Service w32time -Force
            w32tm /resync | Out-Null
            Write-Host "Time service configuration updated." -ForegroundColor Green
        } else {
            Write-Host "Windows Time service is already configured." -ForegroundColor Yellow
        }

# --------------------- Software Installation ---------------------

    # Base Network PATH
        $BasePath = "\\192.168.100.10\shared\_SW"

    # List of software folders
        $SW = @(
            "Google Chrome",            # Google Chrome
            "KakaoTalk",                # KakaoTalk
            "Microsoft Office",         # Microsoft Office
            #"Parsec",                   # Parsec
            "Synology Drive Client",    # Synology Drive Client
            "Zoom Workplace"           # Zoom Workplace
            #"Brave"                     # Brave Browser
        )

    # Define specific installation parameters for selected software.
        # Parameters can be defined for MSI or EXE installers.
            $SoftwareParameters = @{
                "Microsoft Office" = @{
                    # "msi" = '/quiet /norestart'
                    "exe" = '/configure config.xml'
                }
            }

    # Function to install MSI packages.
        function Install-MSI {
            param (
                [string]$InstallerPath,
                [string]$ExtraParams = ""
            )
        
            # Build the MSI installation arguments.
            $msiArgs = "/i `"$InstallerPath`" /quiet /qn /norestart"
            if ($ExtraParams -ne "") {
                $msiArgs = "/i `"$InstallerPath`" $ExtraParams"
            }
            
            try {
                Write-Host "Starting MSI installation: $InstallerPath" -ForegroundColor Cyan
                $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -ErrorAction Stop
                if ($process.ExitCode -ne 0) {
                    Write-Host "MSI installation failed with exit code $($process.ExitCode) for $InstallerPath." -ForegroundColor Red
                }
                else {
                    Write-Host "MSI installation completed successfully for $InstallerPath." -ForegroundColor Green
                }
            }
            catch {
                Write-Host "Error installing $($installer.Name) for $($software): $($_)" -ForegroundColor Red
            }
        }

    # Function to install EXE packages.
        function Install-EXE {
            param (
                [string]$InstallerPath,
                [string]$ExtraParams = ""
            )
            
            $installerDir = Split-Path -Path $InstallerPath
            try {
                Write-Host "Starting EXE installation: $InstallerPath" -ForegroundColor Cyan
                
                if ($ExtraParams -ne "") {
                    $process = Start-Process -FilePath $InstallerPath `
                                            -ArgumentList $ExtraParams `
                                            -WorkingDirectory $installerDir `
                                            -Wait -PassThru -ErrorAction Stop
                }
                else {
                    $process = Start-Process -FilePath $InstallerPath `
                                            -WorkingDirectory $installerDir `
                                            -Wait -PassThru -ErrorAction Stop
                }
                
                if ($process.ExitCode -ne 0) {
                    Write-Host "EXE installation failed with exit code $($process.ExitCode) for $InstallerPath." -ForegroundColor Red
                }
                else {
                    Write-Host "EXE installation completed successfully for $InstallerPath." -ForegroundColor Green
                }
            }
            catch {
                Write-Host "Error installing $($installer.Name) for $($software): $($_)" -ForegroundColor Red
            }
        }


    # Main installation loop - Process each software package in the list.
        foreach ($software in $SW) {
            Write-Host "Processing $software..." -ForegroundColor Cyan
            
            # Construct the full path to the software folder.
            $SoftwarePath = Join-Path -Path $BasePath -ChildPath $software
            
            # Append the "Windows" subfolder where the installer files are expected.
            $WindowsSubFolder = Join-Path -Path $SoftwarePath -ChildPath "Windows"
            
            if (-not (Test-Path $WindowsSubFolder)) {
                Write-Host "Windows subfolder not found in $SoftwarePath. Skipping installation for $software." -ForegroundColor Yellow
                continue
            }
            
            # Retrieve all installer files (.msi and .exe) from the "Windows" subfolder.
            $installerFiles = Get-ChildItem -Path $WindowsSubFolder -File | Where-Object { $_.Extension -match "(\.msi|\.exe)$" }
            if ($installerFiles.Count -eq 0) {
                Write-Host "No MSI or EXE installer files found in $WindowsSubFolder for $software." -ForegroundColor Yellow
                continue
            }
            
            foreach ($installer in $installerFiles) {
                # Use lowercase for a reliable extension comparison.
                $extension = $installer.Extension.ToLower()
                if ($extension -eq ".msi") {
                    # Retrieve any custom MSI parameters if defined.
                    $extraParams = ""
                    if ($SoftwareParameters.ContainsKey($software) -and $SoftwareParameters[$software].ContainsKey("msi")) {
                        $extraParams = $SoftwareParameters[$software]["msi"]
                    }
                    Install-MSI -InstallerPath $installer.FullName -ExtraParams $extraParams
                }
                elseif ($extension -eq ".exe") {
                    # Retrieve any custom EXE parameters if defined.
                    $extraParams = ""
                    if ($SoftwareParameters.ContainsKey($software) -and $SoftwareParameters[$software].ContainsKey("exe")) {
                        $extraParams = $SoftwareParameters[$software]["exe"]
                    }
                    Install-EXE -InstallerPath $installer.FullName -ExtraParams $extraParams
                }
                else {
                    Write-Host "Unsupported file extension $($installer.Extension) for file $($installer.Name)." -ForegroundColor Yellow
                }
            }
        }



# --------------------- OneDrive Cleanup ---------------------
    # Stop OneDrive Process
        $oneDriveProcess = Get-Process -Name OneDrive -ErrorAction SilentlyContinue
        if ($oneDriveProcess) {
            Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
            Write-Host "OneDrive process stopped."
        } else {
            Write-Host "OneDrive is not running."
        }

    # Uninstall OneDrive
        $oneDriveSetup = Get-Command -ErrorAction SilentlyContinue -Name "OneDriveSetup.exe"
        if ($oneDriveSetup) {
            Write-Host "Uninstalling OneDrive from $($oneDriveSetup.Source)"
            Start-Process -FilePath $oneDriveSetup.Source -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue
        } else {
            Write-Host "OneDriveSetup.exe not found in standard locations."
        }

    # Remove OneDrive directories
        $oneDriveDirectories = @("$env:localappdata\Microsoft\OneDrive", "$env:programdata\Microsoft OneDrive", "$env:systemdrive\OneDriveTemp", "$env:userprofile\OneDrive")
        foreach ($dir in $oneDriveDirectories) {
            if (Test-Path $dir) {
                Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Removed OneDrive directory: $dir"
            }
        }

    # Registry Modifications for Disabling OneDrive
        $regPaths = @(
            "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\OneDrive",
            "Registry::HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}",
            "Registry::HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
        )


        foreach ($regPath in $regPaths) {
            if (!(Test-Path $regPath)) {
                New-Item -Path $regPath -Force -ErrorAction Stop | Out-Null
            }
            Set-ItemProperty -Path $regPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $regPath -Name "DisableFileSyncNGSC" -Value 1 -ErrorAction SilentlyContinue
        }

    # Remove Run Hooks for All Users
        $users = Get-ChildItem "Registry::HKEY_USERS" | Where-Object { $_.Name -match "S-1-5-\d+$" }
        foreach ($user in $users) {
            $runKey = "Registry::$($user.Name)\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
            if (Test-Path $runKey) {
                Remove-ItemProperty -Path $runKey -Name "OneDriveSetup" -ErrorAction SilentlyContinue
                Write-Host "Removed OneDrive startup hook for $($user.Name)"
            }
        }


# --------------------- Windows 11 Right Click Fix ---------------------
    # Define the registry path
        $registryPath = "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    
    # Build the command string (using backticks to escape quotes)
        $command = "reg.exe add `"$registryPath`" /f /ve"
    
    # Inform the user of the operation
        Write-Output "Applying fix to revert Windows 11 right-click context menu..."

    try {
        # Execute the command
        Invoke-Expression $command

        # Confirm completion
        Write-Output "Registry operation completed successfully."
    }
    catch {
        Write-Output "An error occurred during the registry operation: $_"
    }

# --------------------- KakaoTalk Auto-Update Fix ---------------------
    # Define the two possible folder paths
        $path = "$env:LOCALAPPDATA\Kakao\KakaoTalk"

        try {
            # Check if the folder exists
            if (Test-Path $path) {
                # Build the full path to KakaoUpdate.exe
                $exeFile = Join-Path $path "KakaoUpdate.exe"
                
                # Check if the file exists
                if (Test-Path $exeFile) {
                    $oldFile = "$exeFile.old"
                    
                    # Remove the .old file if it exists
                    if (Test-Path $oldFile) {
                        Remove-Item -Path $oldFile -Force
                    }
                    
                    # Rename the existing file to KakaoUpdate.exe.old
                    Rename-Item -Path $exeFile -NewName "KakaoUpdate.exe.old" -Force
                    
                    # Create a new, empty file named KakaoUpdate.exe
                    New-Item -Path $exeFile -ItemType File -Force | Out-Null
                    
                    Write-Host "Processed file in path: $path"
                }
                else {
                    Write-Host "File not found: $exeFile"
                }
            }
            else {
                Write-Host "Path does not exist: $path"
            }
        }
        catch {
            Write-Host "An error occurred while processing $path. Error: $_"
        }

# --------------------- Final Cleanup and Restart Explorer ---------------------
    Write-Host "Finalizing cleanup and restarting Windows Explorer..."
    Restart-Explorer
