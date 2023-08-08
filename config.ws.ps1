# env
Write-Host "Version: Aug.2023 Version 5"
Write-Host "Setting up the required variables..."

# Choco
    # Checking if Chocolatey is installed.
        $Test_Choco = Get-Command -Name choco -ErrorAction Ignore
    
    # if Chocolatey is not installed, installed them.
        if (-not ($Test_Choco)) { Invoke-RestMethod minseochoi.tech/script/install-choco | Invoke-Expression }

# Retreieve
    $computerName = $env:COMPUTERNAME                                                 # Retreieving Current Computer's Name
    $userName = $env:USERNAME                                                         # Retreieving Current User's Name
    $processor = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name   # Retreieving Processor's Information
    $manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer

# Custom Tweaks
    # NTP-Server Tweaks
        $NTPserviceName = "W32Time"
        $NTPservice = Get-Service -Name $NTPserviceName -ErrorAction SilentlyContinue

    # Power-Plan Tweaks
        $HpowerPlanGUID = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
        $LpowerPlanGUID = "381b4222-f694-41f0-9685-ff5bb260df2e"

    # NVIDIA High Definition Audio
        if (Get-PnpDevice -FriendlyName "NVIDIA High Definition Audio") {
            $VaudioDeviceID = $true
            $audioDeviceId = (Get-PnpDevice -FriendlyName "NVIDIA High Definition Audio").InstanceId 
        }

    # Check if the current user has administrative privileges
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    # Administrator Account Tweak
        $password = "l0c@l@dm1n"    # Generic Password that it will be reset to.
        $Empty_password = ""        # Default Variable = Checking if the $password is empty
        $AdminActive = $false       # Default Variable = Checking if Local Administrator account is in 'active' status.
        $AdminPW = $false           # Default Variable = Checking if Local Administrator's Password has been 'changed'.

# Default Variable
    # Software installation
        $Softwares = $false            # Auto Installation of Default Softwares.

    # NVIDIA High Definition Audio
        $VaudioDeviceID = $false

    # ExecutionPolicy
        $GEP = Get-ExecutionPolicy
        $BP = "Bypass"
            # Set Execution Policy
                if (-not ($GEP -eq $BP)) { Set-ExecutionPolicy $BP -Force }
    # Workstation Choice Reset
        $laptop = $false
        $desktop = $false
        $initial = $false
        $skip = $false
        $lcds = $false
        $chodae = $false

# Windows Service List
    $services = @(
        "DiagTrack",             # Connected User Experiences and Telemetry
        "fxssvc.exe",            # Fax
        "AxInstSV",              # AllJoyn Router Service
        "PcaSvc",                # Program Compatibility Assistant Service
        "dmwappushservice",      # Device Management Wireless Application Protocol (WAP) Push message Routing Service
        "Remote Registry",       # Remote Registry
        "WMPNetworkSvc",         # Windows Media Player Network Sharing Service
        "StiSvc",                # Windows Image Acquisition
        "XblAuthManager",        # Xbox Live Auth Manager
        "XblGameSave",           # Xbox Live Game Save Service
        "XboxNetApiSvc",         # Xbox Live Networking Service
        "ndu"                    # Windows Network Data Usage Monitor
    )

# Software Installation List
    $intels = @(
        "intel-chipset-device-software",            # Intel Chipset
        "intel-dsa"                                 # Intel Driver & Support Assistant
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
        "dellcommandupdate"                         # Dell Update Command
    )

    $lcds_softwares = @(
        "vlc",                                      # VLC Media Player
        "adobereader"                               # Adobe Reader DC
    )

    $chodae_softwares = @(
        "obs-studio --version 29.1.3",              # OBS Version of 29.1.3
        "obs-ndi",                                  # OBS NDI Integration
        #"streamdeck",                               # Stream-Deck
        "cloudstation",                             # Synology Cloud Station
        "slack"                                     # Slack
        #"x32-edit"                                  # X32-Edit
        #"zoom"                                      # Zoom
    )

# ----------------------------------------------------------------------------------------------------------------------------------------

Clear-Host

# Prompt for User either Desktop or Laptop
do {
    $wsChoice = Read-Host -Prompt "Is $computerName / $userName a LAPTOP(L), DESKTOP (D)?: "
    
    if ($wsChoice -eq "LAPTOP" -or $wsChoice -eq "L") { $laptop = $true } 
    elseif ($wsChoice -eq "DESKTOP" -or $wsChoice -eq "D") { $desktop = $true } 
    elseif ($wsChoice -eq "I" -or $wsChoice -eq "i") { $initial = $true }
    elseif ($wsChoice -eq "S" -or $wsChoice -eq "s") { $skip = $true }
    else { Write-Host "You must select either Laptop (L), Desktop (D), or Server (S)." }
    } 
    while (-not ($laptop -eq $true -or $desktop -eq $true -or $initial -eq $true -or $skip -eq $true -or $lcds -eq $true))

Clear-Host
Write-Host ""   

if ($initial -or $laptop -or $desktop -or $lcds) {
    # Windows Service Tweaks
        foreach ($service in $services) {
            Write-Host "Tweaking Services.. ($service)"
            Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled -ErrorAction SilentlyContinue
        }

Write-Host ""

# Windows NTP Server Tweaks
    Write-Host "Fixing Workstation's NTP Server"
    if ($null -eq $NTPservice) { Start-Service -Name $NTPserviceName }
    Start-Process -FilePath w32tm -ArgumentList "/config /manualpeerlist:time.google.com /syncfromflags:MANUAL /reliable:yes /update" -WindowStyle Hidden
    if ($isAdmin) { Restart-Service -Name $NTPserviceName } else { Write-Host "Administrative Previlage require to restart $NTPserviceName." }
    Start-Process -FilePath w32tm -ArgumentList "/config /update" -WindowStyle Hidden
    Start-Process -FilePath w32tm -ArgumentList "/resync /nowait /rediscover" -WindowStyle Hidden

Write-Host ""

    # Windows Classic Right-Click Tweak for Windows 11
    Write-Host "Enabling Windows 10 Right-Click Style in Windows 11"
    if ((Get-CimInstance -ClassName Win32_OperatingSystem).Version -notmatch "^10") {
        Write-Host "Right-Click tweak is 'ONLY' intended for Windows 11"
    } else {
        # Adding Registry to Workstation for Classic Right Click
        Write-Host "Tweaking 'Classic Right-Click' for Windows 11"
        reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
        # Restarting Windows Explorer
        if (Get-Process explorer) { Stop-Process -name explorer -force }
    }

Write-Host ""

# Windows Default Administrator Account Tweak
    # Activating Local Administrator Account    
    Write-Host "Activating Local Administrator Account..."
    if ((net user Administrator | Select-String -Pattern "Account active               No")) {
    net user Administrator /active:yes
    $AdminActive = $true
    }
    if ($AdminActive) { Write-Host "Local Administrator Account is NOW active" } else { Write-Host "Local Administrator Account is ALREADY active" }

# Set Local Administrator Account Password
Write-Host "Local Administrator Account's Password is Changing to its default value"
if ($Empty_password -eq $password) { Write-Host "Password has not been set." }
else { 
    if ($isAdmin) {
        $user = [ADSI]"WinNT://$env:COMPUTERNAME/Administrator,user"
        $user.SetPassword($password)
        $user.SetInfo()
        $AdminPW = $true
    } else { Write-Host "This $userName does not have previlage." }
}
if ($AdminPW) { Write-Host "Local Administrator Account's Password has been changed to its default value " } else { Write-Host "Password Value has not been set. Local Administrator Account's Password has not been changed." }

Write-Host ""
}

# Laptop
if ($laptop) {
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
        Disable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false -ErrorAction SilentlyContinue 
    }
}

# Desktop
if ($desktop) {
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
        Disable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false -ErrorAction SilentlyContinue
    }
}

# Ask client for Software installation on workstation
do {
    Write-Host ""
    $swChoice = Read-Host -Prompt "Will $computerName / $userName require a General Application 'Auto-Install'?: "
    
    if ($swChoice -eq "YES" -or $swChoice -eq "Y") { $Softwares = $true } 
    elseif ($swChoice -eq "NO" -or $swChoice -eq "N") { $Softwares = $false } 
    elseif ($swChoice -eq "lcds" -or $swChoice -eq "LCDS") { $lcds = $true }
    elseif ($swChoice -eq "chodae" -or $swChoice -eq "CHODAE") { $chodae = $true }
    else { 
        Write-Host "You must select either Yes (Y) or No (N)." 
    }
} while (-not ($Softwares -eq $true -or $Softwares -eq $false -or $lcds -eq $true -or $chodae -eq $true))

if ($lcds -or $chodae) { $softwares = $true }

# Software Installation
if ($Softwares) {

# General Softwares
    Write-Host "Installing Softwares using Installation Methods of Chocolatey"

# AMD
    if ($processor -like '*AMD*') {
        foreach ($amd in $amds) {
            if (choco list | Select-String $amd) {
                Write-Host "$amd is already installed."
            } else {
                Write-Host -NoNewline "Installing ($amd)"
                Start-Process -FilePath choco -ArgumentList "install $amd --limitoutput --no-progress" -Verb RunAs
                    Wait-Process -Name Choco -ErrorAction SilentlyContinue
                        if (choco list | Select-String $amd) { Write-Host " Installed" } else { Write-Host " Failed" }
            }
        }
    }

# Intel
    if ($processor -like '*Intel*') {
        foreach ($intel in $intels) {
            if (choco list | Select-String $intel) {
                Write-Host "$intel is already installed." 
            } else {
                Write-Host -NoNewline "Installing ($intel)"
                Start-Process -FilePath choco -ArgumentList "install $intel --limitoutput --no-progress" -Verb RunAs
                    Wait-Process -Name Choco -ErrorAction SilentlyContinue
                        if (choco list | Select-String $intel) { Write-Host " Installed" } else { Write-Host " Failed" }
            }
        }
    }

# Installing software from the list from above
    foreach ($csoftware in $csoftwares) {
        if (choco list | Select-String $csoftware) {
            Write-Host "$csoftware is already installed." 
        } else {
            Write-Host -NoNewline "Installing ($csoftware).."
            Start-Process -FilePath choco -ArgumentList "install $csoftware --limitoutput --no-progress" -Verb RunAs
                Wait-Process -Name Choco -ErrorAction SilentlyContinue
                if (choco list | Select-String $csoftware) { Write-Host " Installed" } else { Write-Host " Failed" }
        } 
    }

    if ($manufacturer -like '*Dell*') {
        foreach ($dell_software in $dell_softwares) {
            if (choco list | Select-String $dell_software) {
                Write-Host "$dell_software is already installed." 
            } else {
                Write-Host "Installing $dell_software"
                Start-Process -FilePath choco -ArgumentList "install $dell_software --limitoutput --no-progress" -Verb RunAs
                Wait-Process -Name Choco -ErrorAction SilentlyContinue
                if (choco list | Select-String $dell_software) { Write-Host " Installed" } else { Write-Host " Failed" }
            }
        }
    }

    if ($lcds) {
        foreach ($lcds_software in $lcds_softwares) {
            if (choco list | Select-String $lcds_software){
                Write-Host "$lcds_software is already installed."
            } else {
                Write-Host "Installing $lcds_software"
                Start-Process -FilePath choco -ArgumentList "install $lcds_software --limitoutput --no-progress" -Verb RunAs
                Wait-Process -Name Choco -ErrorAction SilentlyContinue
                if (choco list | Select-String $lcds_software) { Write-Host " Installed" } else { Write-Host " Failed" }
            }
        }
    }

    if ($chodae) {
        foreach ($chodae_software in $chodae_softwares) {
            if (choco list | Select-String $chodae_software){
                Write-Host "$chodae_software is already installed."
            } else {
                Write-Host "Installing $chodae_software"
                Start-Process -FilePath choco -ArgumentList "install $chodae_software --limitoutput --no-progress" -Verb RunAs
                    Wait-Process -Name Choco -ErrorAction SilentlyContinue
                    if (choco list | Select-String $chodae_software) { Write-Host " Installed" } else { Write-Host " Failed" }
            }
        }
    }
}
return

# End