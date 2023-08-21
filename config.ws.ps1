Clear-Host
# env
Write-Host "Comment: Aug v2.1"
Write-Host "Setting up the required variables..."

$debug = $true

# Custom Functions
    function CreateShortcut {
        param (
            [string]$TargetFile,
            [string]$ShortcutFile
        )
        try {
            $WScriptShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
            $Shortcut.TargetPath = $TargetFile
            $Shortcut.Save()
        } catch { 
            # Write-Host " (Failed: Shortcut)"
            Write-Host "Error creating shortcut: $_"
        }
    }

    function Install {
        param (
            [string]$Apps,
            [string]$Arguments
        )
        if ($isAdmin) {
            if ($null -ne $Arguments -and $Arguments -ne "") {
                try {
                    Start-Process -FilePath "$Apps" -ArgumentList ($Arguments -split " ") -Verb RunAs -WindowStyle Hidden -Wait
                } catch { 
                    # Write-Host " (Failed: Installation of $Apps)"
                    Write-Host "Error Installing: $_" 
                }
            } else {
                try {
                    Start-Process -FilePath "$Apps" -Verb RunAs -WindowStyle Hidden -Wait
                } catch {
                    # Write-Host " (Failed: Installation of $Apps)"
                    Write-Host "Error Installing: $_" 
                }
            }
        } else {
            Write-Host " (Failed: Permission)"
        }
    }

    function CustomTweakProcess {
        param (
            [string]$Apps,
            [string]$Arguments
        )
            if (-not($isAdmin)) {
                if ($null -ne $Arguments -and $Arguments -ne "") {
                    try {
                        Start-Process -FilePath "$Apps" -ArgumentList ($Arguments -split " ") -WindowStyle Hidden -Wait
                    } catch {
                        # Write-Host " (Failed: Tweak)"
                        Write-Host "Error Tweaking: $_" 
                    }
                } else {
                    try {
                        Start-Process -FilePath "$Apps" -WindowStyle Hidden -Wait
                    } catch { 
                        # Write-Host " (Failed: Tweak)"
                        Write-Host "Error Tweaking: $_" 
                    }
                }
            }
            if ($isAdmin) {
                if ($null -ne $Arguments -and $Arguments -ne "") {
                    try {
                        Start-Process -FilePath "$Apps" -ArgumentList ($Arguments -split " ") -Verb RunAs -WindowStyle Hidden -Wait
                    } catch {
                        # Write-Host " (Failed: Tweak)"
                        Write-Host "Error Tweaking: $_" 
                    }
                } else {
                    try {
                        Start-Process -FilePath "$Apps" -Verb RunAs -WindowStyle Hidden -Wait
                    } catch { 
                        # Write-Host " (Failed: Tweak)"
                        Write-Host "Error Tweaking: $_" 
                    }
                }
            }
    }

    
# Retreieve
    $computerName = $env:COMPUTERNAME                                                   # Retreieving Current Computer's Name
    $userName = $env:USERNAME                                                           # Retreieving Current User's Name
    $processor = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name     # Retreieving Processor's Information
    $manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer      # Retreieving Manufacturer
    $Domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain                  # Retreieving Domain
    $battery = (Get-WmiObject Win32_Battery).Description                                # Retreiving Battery Information
    $OS_Name = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption               # Retreiving Operating System's Name
    $OS_Version = (Get-CimInstance -ClassName Win32_OperatingSystem).Version            # Retreiving Operating System's Version
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Custom Tweaks
    # Power-Plan Tweaks
        $HpowerPlanGUID = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"            # High-Performance Power-Plan GUID
        $LpowerPlanGUID = "381b4222-f694-41f0-9685-ff5bb260df2e"            # Low-Performance  Power-Plan GUID
    # NVIDIA High Definition Audio
        $NVIDIA = Get-PnpDevice -FriendlyName "NVIDIA High Definition Audio" -ea SilentlyContinue
            if ($NVIDIA) {
                $VaudioDeviceID = $true
                $audioDeviceId = (Get-PnpDevice -FriendlyName "NVIDIA High Definition Audio").InstanceId 
            }
    # Permission Administrator Check
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    # Administrator Account Tweak
        $password = "l0c@l@dm1n"        # Generic Password that it will be reset to.
    # Get-Process | Get-Service
        # Explorer
            $Explorer = Get-Process explorer -ea SilentlyContinue
        # NTP-Server
            $NTPservice = Get-Service -Name "W32Time" -ea SilentlyContinue
            
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Default Variable
    # Software installation
        $Softwares = $false             # Auto Installation of Default Softwares.
    # NVIDIA High Definition Audio
        $VaudioDeviceID = $false        # Check for NVIDIA High Definition Audio is installed
# Execution Policy
    $GEP = Get-ExecutionPolicy
    $BP = "Bypass"
    # If the current Execution Policy is not already set to Bypass
        if (-not ($GEP -eq $BP)) {
        # Define the script block to change Execution Policy
            $Code = { Set-ExecutionPolicy -ExecutionPolicy $using:BP -Force }
        # Start a background job to change the Execution Policy
            Start-Job -ScriptBlock $Code | Wait-Job | Remove-Job
    }
    # Choice Reset
        $laptop = $false
        $desktop = $false
        $initial = $false
        $lcds = $false
        $selectedOption = $null
        $selectedOption2 = $null
    # Domain
        $domainName = "lcds.internal"
    # Administrator Account Related Reset
    $AdminActive = $false           # Default Variable = Checking if Local Administrator account is in 'active' status.
    $AdminPW = $false               # Default Variable = Checking if Local Administrator's Password has been 'changed'.
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# if Chocolatey is not installed, installed them.
    if (-not(Get-Command -Name choco -ea Ignore)) { irm minseochoi.tech/script/install-choco | iex }
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Windows Service List
    $services = @(
        "DiagTrack",                # Connected User Experiences and Telemetry
        "fxssvc.exe",               # Fax
        "AxInstSV",                 # AllJoyn Router Service
        "PcaSvc",                   # Program Compatibility Assistant Service
        "dmwappushservice",         # Device Management Wireless Application Protocol (WAP) Push message Routing Service
        "Remote Registry",          # Remote Registry
        "WMPNetworkSvc",            # Windows Media Player Network Sharing Service
        "StiSvc",                   # Windows Image Acquisition
        "XblAuthManager",           # Xbox Live Auth Manager
        "XblGameSave",              # Xbox Live Game Save Service
        "XboxNetApiSvc",            # Xbox Live Networking Service
        "ndu"                       # Windows Network Data Usage Monitor
    )
# Questions @ Start
    # Auto Checking if Workstation is Desktop or Laptop
        if ($battery -eq 'Internal Battery') { $laptop = $true } else { $desktop = $true }
    # Auto Provide Varibles to each keybinds
        $options = @(
            [PSCustomObject]@{ Key = 'I'; Description = 'Initial Tweaks'; Variable = 'initial' }
            [PSCustomObject]@{ Key = 'SK'; Description = 'Skipping Tweaks'; Variable = 'skip' }
            [PSCustomObject]@{ Key = 'LCDS'; Description = 'LCDS Tweaks'; Variable = 'lcds' }
        )
        $options2 = @(
            [PSCustomObject]@{ Key = 'Yes' ; Description = 'General Installation Start'; Variable = 'softwares' }
            [PSCustomObject]@{ Key = 'NO'; Description = 'No General Installation'; Variable = 'no_softwares' }
            [PSCustomObject]@{ Key = 'LCDS'; Description = 'LCDS Tweaks & Installation'; Variable = 'lcds' }
        )
    
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# LCDS Microsoft Office Install Function
    $User_PATH = "C:\Users\$userName\Desktop"
        $PPT_USER_PATH = "$User_PATH\PowerPoint.lnk"
        $WORD_USER_PATH = "$User_PATH\Word.lnk"
        $EXCEL_USER_PATH = "$User_PATH\Excel.lnk"

    $User2_PATH = "\\lcds-22-fs1\userdata$\faculty\$userName"
        $PPT_USER2_PATH = "$User2_PATH\PowerPoint.lnk"
        $WORD_USER2_PATH = "$User2_PATH\Word.lnk"
        $EXCEL_USER2_PATH = "$User2_PATH\Excel.lnk"

    $Check_OFFICE_PATH = "C:\Program Files\Microsoft Office\root\Office16"
        $PPT_PATH = "$Check_OFFICE_PATH\POWERPNT.exe"
        $WORD_PATH = "$Check_OFFICE_PATH\WINWORD.exe"
        $EXCEL_PATH = "$Check_OFFICE_PATH\EXCEL.exe"

    $LCDS_Network_Application_PATH = "\\lcds-22-fs1\Netapps\_Initial_Install"
    $2019_Office_Installation_PATH = "$LCDS_Network_Application_PATH\new_office_2019\setup.exe"
        $Install_Arg = "/configure $LCDS_Network_Application_PATH\new_office_2019\config.xml"
    $Office2019 = "Microsoft Office Professional Plus 2019"

    $VIRASEC_TeamViewer = "VIRASEC TeamViewer Host"
        $TeamViewer_Host = "TeamViewer Host"
        $VIRASEC_TeamViewer_Installation_PATH = "$LCDS_Network_Application_PATH\VIRASEC-TeamViewer\TeamViewer_Host_Setup.exe"


    # Local User Path Shortcut Functions
        $Applications1 = @(
            @{ Name = "PowerPoint"; TargetPath = $PPT_PATH; ShortcutFile = $PPT_USER_PATH },
            @{ Name = "Word"; TargetPath = $WORD_PATH; ShortcutFile = $WORD_USER_PATH },
            @{ Name = "Excel"; TargetPath = $EXCEL_PATH; ShortcutFile = $EXCEL_USER_PATH }
        )
        $Applications2 = @(
            @{ Name = "PowerPoint"; TargetPath = $PPT_PATH; ShortcutFile = $PPT_USER2_PATH },
            @{ Name = "Word"; TargetPath = $WORD_PATH; ShortcutFile = $WORD_USER2_PATH },
            @{ Name = "Excel"; TargetPath = $EXCEL_PATH; ShortcutFile = $EXCEL_USER2_PATH }
        )
    # Function to Create a This PC, Documents, Download Shortcut to the Desktop
        # Specify paths
            $DesktopPath = [System.Environment]::GetFolderPath("Desktop")
            $ThisPCPath = [System.Environment]::GetFolderPath("MyComputer")
            $DocumentsPath = [System.Environment]::GetFolderPath("MyDocuments")
            $DownloadsPath = [System.Environment]::GetFolderPath("Desktop") + "\Downloads"
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Software Installation List
    $intels = @(
        "intel-chipset-device-software",           # Intel Chipset
        "intel-dsa"                                # Intel Driver & Support Assistant
    )
    $amds = @(
        "amd-ryzen-chipset"                         # AMD Ryzen Chipset
    )

    $csoftwares = @(
        "googlechrome",                             # Google Chrome
        "firefox",                                  # Firefox
        "vcredist140",                              # Microsoft C++ 2015-2022 
        "javaruntime",                              # Java Runtime Environment
        "powershell-core"                           # Microsoft PowerShell
    )

    $dell_softwares = @(
        "dellcommandupdate",                        # Dell Update Command
        "supportassist"                             # Dell SupportAssist
    )

    $lcds_softwares = @(
        "vlc",                                      # VLC Media Player
        "adobereader"                               # Adobe Reader DC
    )

 # Arguments
    $W32TM_ManualPeerList_Arg = "/config /manualpeerlist:time.google.com /syncfromflags:MANUAL /reliable:yes /update"
    $W32TM_Update_Arg = "/config /update"
    $W32TM_ReSync_Arg = "/resync /nowait /rediscover"
    $Win10_Style_RightClick_Arg = 'add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve'
    $BuiltIn_Administrator_Active_Check = (net user Administrator) -match "Account active               No"
    $Add_WS_TO_DOMAIN_Arg = "Add-Computer -DomainName $domainName -Credential (Get-Credential)"


#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Start
    if (-not($debug)) {Clear-Host}

# Choose Options
    while (-not $selectedOption) {
        Write-Host "Select One of the Options:"
            $options | ForEach-Object { Write-Host "$($_.Key) - $($_.Description)" }
            $wsChoice = Read-Host -Prompt "Enter the option key: "
            $selectedOption = $options | Where-Object { $_.Key -eq $wsChoice } 
    if (-not $selectedOption) {
        Write-Host ""
        Write-Host "Invalid choice. Please select a valid option."
        Write-Host ""
    }
}

# Set the selected option variable to $true
    Set-Variable -Name $selectedOption.Variable -Value $true
        if ($skip) { $laptop = $false; $desktop = $false }
        if ($lcds) { $softwares = $true }

Write-Host "--------------------------------------------------------------------------------------------------------"  

if ($initial -or $lcds) {
    # Create Default Shortcut
    Write-Host -NoNewLine "Creating Default Shortcut to the desktop"
        try {
            Create-Shortcut -TargetPath $ThisPCPath -ShortcutPath "$DesktopPath\This PC.lnk" -ea SilentlyContinue
            Create-Shortcut -TargetPath $DocumentsPath -ShortcutPath "$DesktopPath\Documents.lnk" -ea SilentlyContinue
            Create-Shortcut -TargetPath $DownloadsPath -ShortcutPath "$DesktopPath\Downloads.lnk" -ea SilentlyContinue
            Write-Host " (Finished)"
        }
        catch { Write-Host " (Failed: Shortcut)" }
    # Windows Service Tweaks
        foreach ($service in $services) {
            try {
                Write-Host "Tweaking Services.. ($service)"
                Get-Service -Name $service -ea SilentlyContinue | Set-Service -StartupType Disabled -ea SilentlyContinue
            }
            catch {
                Write-Host "Failed Tweaking Services.. ($service)"
            }
        }
    Write-Host "--------------------------------------------------------------------------------------------------------"
    # Windows NTP Server Tweaks
        Write-Host -NoNewLine "Fixing Workstation's NTP Server"
        if ($isAdmin) {
            try {
                if (($NTPservice).Status -eq 'Stopped') { Start-Service -Name "W32Time" }
                    CustomTweakProcess -Apps "w32tm" -Arguments $W32TM_ManualPeerList_Arg
                    CustomTweakProcess -Apps "powershell" -Arguments "Restart-Service -Name ""W32Time"""
                    CustomTweakProcess -Apps "w32tm" -Arguments $W32TM_Update_Arg
                    CustomTweakProcess -Apps "w32tm" -Arguments $W32TM_ReSync_Arg
                        # Output message that it has been finished
                            Write-Host " (Finished)"
                } catch { Write-Host " (Failed: $_)" }
        } else {
            Write-Host " (Failed: Permission)"
        }
            

    # Windows Classic Right-Click Tweak for Windows 11
        Write-Host -NoNewLine "Enabling Windows 10 Right-Click Style in Windows 11"
            if ($OS_Version -notmatch "^10") {
                Write-Host " (Failed: Version mismatch)"
            } else {
                # Adding Registry to Workstation for Classic Right Click
                        try {
                            CustomTweakProcess -Apps "reg" -Arguments $Win10_Style_RightClick_Arg
                            Write-Host " (Finished)"
                        } catch {
                            Write-Host "Error Tweaking: $_"
                        }
                }  
                # Restarting Windows Explorer
                    if ($Explorer) { Stop-Process -Name explorer -Force ; Start-Sleep 5 }

    if ($lcds) {
        # Windows Default Administrator Account Tweak
            # Activating Local Administrator Account    
                Write-Host -NoNewLine "Checking if Local Administrator Account is Active..."
                    if ($BuiltIn_Administrator_Active_Check) { 
                        if ($isAdmin) {
                            CustomTweakProcess -Apps "net" -Arguments "user Administrator /active:yes"
                            $AdminActive = $true
                        } else {
                            Write-Host " (Failed: Permission)"
                        } 
                    }
                if ($AdminActive) { Write-Host " (Active)" } else { Write-Host " (Already Active)"}

            # Set Local Administrator Account Password
                Write-Host -NoNewLine "Resetting Local Administrator Password to Generic Password"
                    if ($null -eq $password -and $password -ne "" ) { Write-Host " (Failed: Value)" }
                    elseif ($isAdmin) {
                        try {
                            $user = [ADSI]"WinNT://$env:COMPUTERNAME/Administrator,user"
                            $user.SetPassword($password)
                            $user.SetInfo()
                            $AdminPW = $true
                        } catch { Write-Host " (Failed : $_)" }
                    } else { Write-Host " (Failed : Permission)"}
                if ($AdminPW) { Write-Host " (Done)"}
    }
}

# Laptop
if ($laptop) {
    Write-Host "--------------------------------------------------------------------------------------------------------"
    Write-Host "Starting a Laptop Configuration.."

    # Power Plan Tweaks
        Write-Host "Tweaking Power Plan for Laptop"
        powercfg.exe /setactive $LpowerPlanGUID

    # 'Display Turn OFF' Value
        powercfg /change monitor-timeout-ac "30"
        powercfg /change monitor-timeout-dc "15"

    # Sleep Value
        powercfg /change standby-timeout-ac "0"
        powercfg /change standby-timeout-dc "0"

    # Disabling NVIDIA High Definition Audio for Monitor
        if ($VaudioDeviceId) { 
            Write-Host "Disabling NVIDIA High Definition Audio for Monitor"
            Disable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false -ea SilentlyContinue 
        }
}

# Desktop
if ($desktop) {
    Write-Host "--------------------------------------------------------------------------------------------------------"
    Write-Host "Starting a Desktop Configuration.."

    # Change Power Plan to High Performance
        Write-Host "Tweaking Power Plan for Desktop"
        powercfg.exe /setactive $HpowerPlanGUID

    # 'Display Turn OFF' Value
        powercfg /change monitor-timeout-ac "30"

    # Sleep Value
        powercfg /change standby-timeout-ac "0"

    # Disabling NVIDIA High Definition Audio for Monitor
        if ($VaudioDeviceId) {
            Write-Host "Disabling NVIDIA High Definition Audio for Monitor"
            Disable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false -ea SilentlyContinue
        }
}

# Ask client for Software installation on workstation
    if (-not($Softwares)){
        while (-not $selectedOption2) {
            Write-Host "--------------------------------------------------------------------------------------------------------"
            Write-Host "Will $computerName / $userName require a General Application 'Auto-Install'?: "
                $options2 | ForEach-Object { Write-Host "$($_.Key) - $($_.Description)" }
                $wsChoice = Read-Host -Prompt "Enter the option key: "
                $selectedOption2 = $options2 | Where-Object { $_.Key -eq $wsChoice }
                # Set the selected option variable to $true
            Set-Variable -Name $selectedOption2.Variable -Value $true
        if (-not $selectedOption2) {
            Write-Host "--------------------------------------------------------------------------------------------------------"
            Write-Host "Invalid choice. Please select a valid option."
        }
    }
}

if ($no_softwares) { $Softwares = $false }
if ($lcds) { $softwares = $true }

# Software Installation
    if ($Softwares) {

        # General Softwares
            Write-Host "--------------------------------------------------------------------------------------------------------"
            Write-Host "Installing Softwares using Installation Methods of Chocolatey"
            Write-Host "--------------------------------------------------------------------------------------------------------"

        # AMD
            if ($processor -like '*AMD*') {
                foreach ($software in $amds) {
                    $amd_Arg = "install $software"
                    if (choco list | Select-String $software) {
                        Write-Host "$software is already installed."
                    } else {
                        Write-Host -NoNewline "Installing ($software)"
                        Install -Apps "choco" -Arguments $amd_Arg
                                if (choco list | Select-String $software) { Write-Host " (Installed)" } else { Write-Host " (Failed)" }
                    }
                }
            }

        # Intel
            if ($processor -like '*Intel*') {
                foreach ($software in $intels) {
                    $intel_Arg = "install $software --ignore-checksums"
                    if (choco list | Select-String $software) {
                        Write-Host "$software is already installed." 
                    } else {
                        Write-Host -NoNewline "Installing ($software)"
                        Install -Apps "choco" -Arguments $intel_Arg
                                if (choco list | Select-String $software) { Write-Host " (Installed)" } else { Write-Host " (Failed)" }
                    }
                }
            }

        # Installing software from the list from above
        foreach ($software in $csoftwares) {
            $firefox_Arg = "install $software --params ""/MaintenanceService=false /TaskbarShortcut=false /NoStartMenuShortcut=false"""
            $csoftware_Arg = "install $software --ignore-checksums"
            if ($csoftware -eq "firefox") {
                if (choco list | Select-String $software) {
                    Write-Host "$software is already installed."
                } else {
                    Write-Host -NoNewline "Installing ($software)"
                    Install -Apps "choco" -Arguments $firefox_Arg
                    if (choco list | Select-String $software) { Write-Host " (Installed)" } else { Write-Host " (Failed)" }
                }
            } else {
                if (choco list | Select-String $software) {
                    Write-Host "$software is already installed."
                } else {
                    Write-Host -NoNewline "Installing ($software)"
                    
                    Install -Apps "choco" -Arguments $csoftware_Arg
                    if (choco list | Select-String $software) { Write-Host " (Installed)" } else { Write-Host " (Failed)" }
                }
            }
        }
        

        # Dell
            if ($manufacturer -like '*Dell*') {
                foreach ($software in $dell_softwares) {
                    $dell_Arg = "install $software --ignore-checksums"
                    if (choco list | Select-String $software) {
                        Write-Host "$software is already installed." 
                    } else {
                        Write-Host -NoNewline "Installing ($software)"
                        Install -Apps "choco" -Arguments $dell_Arg
                        if (choco list | Select-String $software) { Write-Host " (Installed)" } else { Write-Host " (Failed)" }
                    }
                }
            }

        # LCDS
            if ($lcds) {
                foreach ($software in $lcds_softwares) {
                    $lcds_Arg = "install $software"
                    if (choco list | Select-String $software){
                    Write-Host "$software is already installed."
                    } else {
                        Write-Host -NoNewline "Installing ($software)"
                        Install -Apps "choco" -Arguments $lcds_Arg
                    if (choco list | Select-String $software) { Write-Host " (Installed)" } else { Write-Host " (Failed)" }
                    }
                }
            }
}
# End of Software Installation

# Additional for LCDS
if ($lcds) {
    if ($OS_Name -match "Home" -and $OS_Name -notmatch "Pro") { 
        Write-Host "--------------------------------------------------------------------------------------------------------"
        Write-Host "$computerName is currently running '$OS_Name'"
        pause
        Write-Host "--------------------------------------------------------------------------------------------------------"
        return 
    }
    # LCDS Domain Auto-Join
    Write-Host "--------------------------------------------------------------------------------------------------------"
        Write-Host -NoNewLine "Checking if $computerName is connected to $domainName"
        if (-not($Domain -eq $domainName)) {
            Write-Host " (Failed: $computerName is not joined to domain)"
            Write-Host -NoNewLine "Adding Workstation:$computerName into $domainName"
                try {
                    CustomTweakProcess -Apps powershell -Arguments $Add_WS_TO_DOMAIN_Arg
                    Write-Host " (Connected)" 
                }
                catch { Write-Host " (Failed: Unable to join to domain)" }    
        } else {
            Write-Host " (Already Connected)"
        }

    # Local Software install
    if ($Domain -eq $domainName) {
        Write-Host "--------------------------------------------------------------------------------------------------------"
        Write-Host "Installing Local Software"
        if (-not(Test-Path -Path $LCDS_Network_Application_PATH)) {
            Write-Host "Failed: PATH NOT EXIST"
            return
        }
        
        # Microsoft Office Professional Plus 2019 Installation 
        if (choco list -i | Select-String $Office2019){
            Write-Host "Write-Host $Office2019 is already installed."
            } else {
                Write-Host -NoNewline "Installing ($Office2019)"
                    Install -Apps "$2019_Office_Installation_PATH" -Arguments "$Install_Arg"
                        if (choco list -i | Select-String $Office2019) {Write-Host " (Installed)"} else {Write-Host " (Failed)"}
            }
        
        # VIRASEC TeamViewer Installation
        if (choco list -i | Select-String $TeamViewer_Host){
            Write-Host "$VIRASEC_TeamViewer is already installed."
            } else {
                Write-Host -NoNewline "Installing ($VIRASEC_TeamViewer)"
                    # Install -Apps "$VIRASEC_TeamViewer_Installation_PATH" -Arguments "/s"
                    # Start-Process -FilePath "$VIRASEC_TeamViewer_Installation_PATH" -ArgumentList "/s" -Verb RunAs -Wait
                    Start-Process -FilePath "$VIRASEC_TeamViewer_Installation_PATH" -Verb RunAs -Wait
                        if (choco list -i | select-string $TeamViewer_Host) {Write-Host " (Installed)"} else {Write-Host " (Failed)"}
            }
        
        # Microsoft Office 2019 Auto-Shortcut
            Write-Host "--------------------------------------------------------------------------------------------------------"
            Write-Host -NoNewLine "Looking for $Office2019 Directory"
                if (Test-Path $Check_OFFICE_PATH) { 
                    Write-Host " (Found.)" 
                } else { 
                    Write-Host " (Failed: Directory can't be found.)"
                    pause
                    return
                }
            Write-Host "--------------------------------------------------------------------------------------------------------"
            Write-Host -NoNewline "Looking for UserData"
                if (Test-Path $User_PATH) {
                    Write-Host " (Local-Drive Directory Found)"
                        foreach ($app1 in $Applications1) {
                            Write-Host -NoNewline "Creating $($app1.Name) shortcut..."
                            CreateShortcut -TargetFile $app1.TargetPath -ShortcutFile $app1.ShortcutFile
                            if (Test-Path $app1.ShortcutFile) { Write-Host " (Created)" } else { Write-Host " (Failed: Shortcut)" }
                        }
                } elseif (Test-Path $User2_PATH) {
                    Write-Host " (Network-Drive Directory Found)"
                        foreach ($app2 in $Applications2) {
                            Write-Host -NoNewline "Creating $($app2.Name) shortcut..."
                            CreateShortcut -TargetFile $app2.TargetPath -ShortcutFile $app2.ShortcutFile
                            if (Test-Path $app2.ShortcutFile) { Write-Host " (Created)" } else { Write-Host " (Failed: Shortcut)" }
                        }
                } else {
                    Write-Host " (Failed: Can't find nor detect any UserData)"
                    pause
                    return
                }
    }
}
Write-Host "--------------------------------------------------------------------------------------------------------"
Write-Host "Finished"
Write-Host "--------------------------------------------------------------------------------------------------------"
return
# End