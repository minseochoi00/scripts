Clear-Host
# env
Write-Host "Comment: Sep v3 - latest"
Write-Host "Setting up the required variables..."

$debug = $false

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
            Write-Host " (Fail: Shortcut)"
        }
    }

    function Install {
        param (
            [string]$Apps,
            [string]$Arguments,
            [bool]$Hidden = $true,
            [bool]$Admin = $true,
            [bool]$Credential = $true
        )

        if ($Hidden) { $windowStyle = "Hidden" } else { $windowStyle = "Normal"}

        $startProcessParams = @{
            FilePath      = $Apps
            WindowStyle   = $windowStyle
            Wait          = $true
        }
        
        if ($null -ne $Arguments -and $Arguments -ne "") {
            $startProcessParams['ArgumentList'] = $Arguments -split " "
        }
        
        if ($Admin) { $startProcessParams['Verb'] = 'RunAs' }
        
        if ($Credential) { $startProcessParams['Credential'] = $cred }
        elseif ($null -eq $cred) { Write-Host " (Fail: Credentials is Empty)"}
        else { Write-Host " (Fail: Credentials)"}

        
        try {
            Start-Process @startProcessParams
        } catch {
            Write-Host " (Fail: Installation)"
        }
    }
    
    function CustomTweakProcess {
        param (
            [string]$Apps,
            [string]$Arguments,
            [bool]$Admin = $false,
            [bool]$Credential = $true
        )
    
        $startProcessParams = @{
            FilePath      = $Apps
            WindowStyle   = 'Hidden'
            Wait          = $true
        }

        if ($null -ne $Arguments -and $Arguments -ne "") {
            $startProcessParams['ArgumentList'] = $Arguments -split " "
        }
    
        if ($Admin) { $startProcessParams['Verb'] = 'RunAs' }
        
        if ($Credential) { $startProcessParams['Credential'] = $cred }
        elseif ($null -eq $cred) { Write-Host " (Fail: Credentials is Empty)"}
        else { Write-Host " (Fail: Credentials)"}
    
        Start-Process @startProcessParams
    }    

# Retreieve
    # Retreieve Current Computer's Name
        $computerName = $env:COMPUTERNAME                                                   
    # Retreieve Current User's Name
        $UserName = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty UserName
        $UserName = $UserName.Split('\')[-1]   
    # Retreieve Processor's Information                                
        $processor = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name
    # Retreieve Manufacturer
        $manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
    # Retreieve Domain
        $Domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
    # Retrieve Battery Information
        $battery = (Get-WmiObject Win32_Battery).Description
    # Retrieve Operating System's Name
        $OS_Name = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    # Retrieve Operating System's Version
        $OS_Version = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Default Variable
    # Software installation
        $Softwares = $false             # Auto Installation of Default Softwares.
    # NVIDIA High Definition Audio
        $VaudioDeviceID = $false        # Check for NVIDIA High Definition Audio is installed
    # Choice Reset
        $laptop = $false
        $desktop = $false
        $initial = $false
        $lcds = $false
        $cred = $null
        $selectedOption = $null
        $selectedOption2 = $null
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
            if (-not ($isAdmin)) {
                $cred = Get-Credential -Message "Enter Administrator Credentials" -UserName "lcds.internal\"
                if ($null -eq $cred) {
                    Write-Host "Credentials are missing"
                    Pause
                    exit
                }
            }
    # Administrator Account Tweak
        $password = "l0c@l@dm1n"        # Generic Password that it will be reset to.
    # Get-Process | Get-Service
        # Explorer
            $Explorer = Get-Process explorer -ea SilentlyContinue
        # NTP-Server
            $NTPservice = Get-Service -Name "W32Time" -ea SilentlyContinue
    # Domain
        $domainName = "lcds.internal"
    # Administrator Account Related Reset
    $AdminActive = $false           # Default Variable = Checking if Local Administrator account is in 'active' status.
    $AdminPW = $false               # Default Variable = Checking if Local Administrator's Password has been 'changed'.
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# if Chocolatey is not installed, installed them.
    if (-not(Get-Command -Name choco -ea Ignore)) { 
        Write-Host -NoNewLine "(Chocolatey) is not installed. Starting Installing"
        if ($null -eq $cred) {
            try {
                Invoke-RestMethod minseochoi.tech/script/install-choco | Invoke-Expression
                Write-Host " (Successful)"
            }
            catch {
                Write-Host "Fail: Couldn't Install Chocolatey"
            }
        }
        try {
            Invoke-RestMethod -Uri minseochoi.tech/script/install-choco -Credential $cred | Invoke-Expression
            Write-Host " (Successful)"
        }
        catch { Write-Host "Fail: Couldn't Install Chocolatey" }
    }
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
        $Office2019_Install_PATH = "$LCDS_Network_Application_PATH\new_office_2019\setup.exe"
        $Install_Arg = "/configure $LCDS_Network_Application_PATH\new_office_2019\config.xml"
        $Office2019 = "Microsoft Office Professional Plus 2019"

    $VIRASEC_TeamViewer = "VIRASEC TeamViewer Host"
        $TeamViewer_Host = "TeamViewer Host"
        $VTeamViewer_Install_PATH = "$LCDS_Network_Application_PATH\VIRASEC-TeamViewer\TeamViewer_Host_Setup.exe"


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
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Software Installation List
    $intels = @(
        "intel-chipset-device-software"           # Intel Chipset
        #"intel-dsa"                                # Intel Driver & Support Assistant
    )
    $amds = @(
        "amd-ryzen-chipset"                         # AMD Ryzen Chipset
    )

    $csoftwares = @(
        "googlechrome",                             # Google Chrome
        #"firefox",                                  # Firefox
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
    # Windows Service Tweaks
        foreach ($service in $services) {
            try {
                Write-Host "Tweaking Services.. ($service)"
                Get-Service -Name $service -ea SilentlyContinue | Set-Service -StartupType Disabled -ea SilentlyContinue
            }
            catch {
                Write-Host "Fail: Tweaking Services.. ($service)"
            }
        }
    Write-Host "--------------------------------------------------------------------------------------------------------"
    # Windows NTP Server Tweaks
        Write-Host -NoNewLine "Fixing Workstation's NTP Server"
            if (($NTPservice).Status -eq 'Stopped') { Start-Service -Name "W32Time" }
                CustomTweakProcess -Apps "w32tm" -Arguments $W32TM_ManualPeerList_Arg -Credential $true
                CustomTweakProcess -Apps "powershell" -Arguments 'Restart-Service -Name "W32Time"' -Credential $true
                CustomTweakProcess -Apps "w32tm" -Arguments $W32TM_Update_Arg -Credential $true
                CustomTweakProcess -Apps "w32tm" -Arguments $W32TM_ReSync_Arg -Credential $true
                    # Output message that it has been Finish
                        if (-not ($Output)) { Write-Host " (Finish)" }
            

    # Windows Classic Right-Click Tweak for Windows 11
        Write-Host -NoNewLine "Enabling Windows 10 Right-Click Style in Windows 11"
            if ($OS_Version -notmatch "^10") {
                Write-Host " (Fail: Version mismatch)"
            } else {
                # Adding Registry to Workstation for Classic Right Click
                try {
                    CustomTweakProcess -Apps "reg" -Arguments $Win10_Style_RightClick_Arg -Admin $false
                    Write-Host " (Finish)"
                }
                catch {
                    Write-Host " (Fail: Registry)"
                }
            }  
            # Restarting Windows Explorer
                if ($Explorer) { Stop-Process -Name explorer -Force -ea SilentlyContinue ; Start-Sleep 5 }

    if ($lcds) {
        # Windows Default Administrator Account Tweak
            # Activating Local Administrator Account    
                Write-Host -NoNewLine "Checking if Local Administrator Account is Active..."
                    if ($BuiltIn_Administrator_Active_Check) { 
                        CustomTweakProcess -Apps "net" -Arguments "user Administrator /active:yes" -Admin $true
                    }
                        if ($BuiltIn_Administrator_Active_Check) { $AdminActive = $true }
                if ($AdminActive) { Write-Host " (Active)" }

            # Set Local Administrator Account Password
                Write-Host -NoNewLine "Resetting Local Administrator Password to Generic Password"
                    if ($null -eq $password -and $password -ne "" ) { Write-Host " (Fail: Value)" }
                    elseif ($isAdmin) {
                        try {
                            $user = [ADSI]"WinNT://$env:COMPUTERNAME/Administrator,user"
                            $user.SetPassword($password)
                            $user.SetInfo()
                            $AdminPW = $true
                        } catch { Write-Host " (Fail : $_)" }
                    } else { Write-Host " (Fail : Permission)"}
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
                    if (choco list -i | Select-String $software) {
                        Write-Host "$software is already installed."
                    } else {
                        Write-Host -NoNewline "Installing ($software)"
                        Install -Apps "choco" -Arguments $amd_Arg 
                                if (choco list -i | Select-String $software) { Write-Host " (Installed)" }
                    }
                }
            }

        # Intel
            if ($processor -like '*Intel*') {
                foreach ($software in $intels) {
                    $intel_Arg = "install $software --ignore-checksums"
                    if (choco list -i | Select-String $software) {
                        Write-Host "$software is already installed." 
                    } else {
                        Write-Host -NoNewline "Installing ($software)"
                        Install -Apps "choco" -Arguments $intel_Arg
                                if (choco list -i | Select-String $software) { Write-Host " (Installed)" }
                    }
                }
            }

        # Installing software from the list from above
        foreach ($software in $csoftwares) {
            $firefox_Arg = 'install $software --force --params "/MaintenanceService=false /TaskbarShortcut=false /NoStartMenuShortcut=false"'
            $csoftware_Arg = "install $software --ignore-checksums --force"
            if ($csoftware -eq "firefox") {
                if (choco list -i | Select-String $software) {
                    Write-Host "$software is already installed."
                } else {
                    Write-Host -NoNewline "Installing ($software)"
                    Install -Apps "choco" -Arguments $firefox_Arg
                    if (choco list -i | Select-String $software) { Write-Host " (Installed)" }
                }
            } else {
                if (choco list | Select-String $software) {
                    Write-Host "$software is already installed."
                } else {
                    Write-Host -NoNewline "Installing ($software)"
                    Install -Apps "choco" -Arguments $csoftware_Arg
                    if (choco list -i | Select-String $software) { Write-Host " (Installed)" }
                }
            }
        }

        # Dell
            if ($manufacturer -like '*Dell*') {
                foreach ($software in $dell_softwares) {
                    $dell_Arg = "install $software --ignore-checksums --force"
                    if (choco list -i | Select-String $software) {
                        Write-Host "$software is already installed." 
                    } else {
                        Write-Host -NoNewline "Installing ($software)"
                        Install -Apps "choco" -Arguments $dell_Arg
                        if (choco list -i | Select-String $software) { Write-Host " (Installed)" }
                    }
                }
            }

        # LCDS
            if ($lcds) {
                foreach ($software in $lcds_softwares) {
                    $lcds_Arg = "install $software --force"
                    if (choco list -i | Select-String $software){
                    Write-Host "$software is already installed."
                    } else {
                        Write-Host -NoNewline "Installing ($software)"
                        Install -Apps "choco" -Arguments $lcds_Arg
                    if (choco list -i | Select-String $software) { Write-Host " (Installed)" }
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
    # Local Software install
    if ($Domain -eq $domainName) {
        Write-Host "--------------------------------------------------------------------------------------------------------"
        Write-Host "Installing Local Software"
        if (-not(Test-Path -Path $LCDS_Network_Application_PATH)) {
            Write-Host "Fail: PATH NOT EXIST"
            return
        }
        
        # Microsoft Office Professional Plus 2019 Installation 
        if (choco list -i | Select-String $Office2019){
            Write-Host "Write-Host $Office2019 is already installed."
            } else {
                Write-Host -NoNewline "Installing ($Office2019)"
                    Install -Apps "$Office2019_Install_PATH" -Arguments "$Install_Arg" -Hidden $true
                        if (choco list -i | Select-String $Office2019) {Write-Host " (Installed)"}
            }
        
        # VIRASEC TeamViewer Installation
        if (choco list -i | Select-String $TeamViewer_Host){
            Write-Host "$VIRASEC_TeamViewer is already installed."
            } else {
                Write-Host -NoNewline "Installing ($VIRASEC_TeamViewer)"
                    Install -Apps "$VTeamViewer_Install_PATH" -Hidden $false
                        if (choco list -i | select-string $TeamViewer_Host) {Write-Host " (Installed)"}
            }
  
        
        # Microsoft Office 2019 Auto-Shortcut
            Write-Host "--------------------------------------------------------------------------------------------------------"
            Write-Host -NoNewLine "Looking for $Office2019 Directory"
                if (Test-Path $Check_OFFICE_PATH) { 
                    Write-Host " (Found.)" 
                } else { 
                    Write-Host " (Fail: Directory can't be found.)"
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
                            if (Test-Path $app1.ShortcutFile) { Write-Host " (Created)" }
                        }
                } elseif (Test-Path $User2_PATH) {
                    Write-Host " (Network-Drive Directory Found)"
                        foreach ($app2 in $Applications2) {
                            Write-Host -NoNewline "Creating $($app2.Name) shortcut..."
                            CreateShortcut -TargetFile $app2.TargetPath -ShortcutFile $app2.ShortcutFile
                            if (Test-Path $app2.ShortcutFile) { Write-Host " (Created)" }
                        }
                } else {
                    Write-Host " (Fail: Can't find nor detect any UserData)"
                    pause
                    return
                }
    }
} else {
    Write-Host "$computerName is not currently joined to LCDS Domain"
}
Write-Host "--------------------------------------------------------------------------------------------------------"
Write-Host "Finish"
Write-Host "--------------------------------------------------------------------------------------------------------"
return
# End