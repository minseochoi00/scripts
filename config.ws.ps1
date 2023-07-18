# env
    Write-Host "Setting up the required variables..."

# Choco
    $Test_Choco = Get-Command -Name choco -ErrorAction Ignore

# Winget
    function Test-WinUtil-PATH-Checker {
        <# .COMMENTS = This Function is for checking Winget #>
        Param([System.Management.Automation.SwitchParameter]$winget)
        if ($winget) { if (Test-Path ~\AppData\Local\Microsoft\WindowsApps\winget.exe) { return $true } }
        return $false
    }

# Retreieve Computer Name & UserName
    $computerName = $env:COMPUTERNAME
    $userName = $env:USERNAME

# NTP Server Tweaks
    $NTPserviceName = "W32Time"
    $NTPservice = Get-Service -Name $NTPserviceName -ErrorAction SilentlyContinue

# Software installation Default
    $Softwares = "False"

# Retrieve Processor's Information
    $processor = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name

# ExecutionPolicy
    $BP = 'Bypass'
    $RS = 'RemoteSigned'
    # Set Execution Policy
        if (-not (Get-ExecutionPolicy) -eq $BP) { Set-ExecutionPolicy $BP -Force -ErrorAction SilentlyContinue }

# Define thse power plan GUID for "High performance" and "Balanced"
    $HpowerPlanGUID = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
    $LpowerPlanGUID = '381b4222-f694-41f0-9685-ff5bb260df2e'

# Get the List of InstanceID with the Name "NVIDIA High Definition Audio"
    if (Get-PnpDevice -FriendlyName "NVIDIA High Definition Audio" -ErrorAction SilentlyContinue) { $NVIDIA_HDA = $true } else { $NVIDIA_HDA = $false }
    if ($NVIDIA_HDA) { $audioDeviceId = (Get-PnpDevice -FriendlyName "NVIDIA High Definition Audio").InstanceId }

# Administrator Account Tweka
    $password = "l0c@l@dm1n"
    $AdminActive = $false
    $AdminPW = $false
    
    # Check if the current user has administrative privileges
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Workstation Choice Reset
    $laptop = $false
    $desktop = $false
    $server = $false

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
    $csoftwares = @(
        "googlechrome",          # Google Chrome
        "firefox"                # Firefox
    )

    $wsoftwares = @(    
        "Microsoft.VCRedist.2015+.x64",    # Microsoft C++ 2015-2022 x64
        "Microsoft.VCRedist.2015+.x86",    # Microsoft C++ 2015-2022 x86
        "Oracle.JavaRuntimeEnvironment",   # Java 8
        "Microsoft.PowerShell"             # PowerShell (Latest)
    )

# ----------------------------------------------------------------------------------------------------------------------------------------

Clear-Host

# Prompt for User either Desktop or Laptop
do {
    $wsChoice = Read-Host -Prompt "Is $computerName / $userName a LAPTOP(L), DESKTOP (D) or SERVER (S)?: "
    if ($wsChoice.ToUpper() -eq "LAPTOP" -or $wsChoice.ToUpper() -eq "L") { $laptop = $true } 
    elseif ($wsChoice.ToUpper() -eq "DESKTOP" -or $wsChoice.ToUpper() -eq "D") { $desktop = $true } 
    elseif ($wsChoice.ToUpper() -eq "SERVER" -or $wsChoice.ToUpper() -eq "S") { $server = $true } 
    else { 
        Write-Host "You must select either Laptop (L), Desktop (D), or Server (S)." 
    }
} while (-not ($laptop -eq $true -or $desktop -eq $true -or $server -eq $true))

Clear-Host
Write-Host ""

# Windows Service Tweaks
    foreach ($service in $services) {
        Write-Host "Tweaking Services.. ($service)"
        # Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled 
        Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled -ErrorAction SilentlyContinue
    }

Write-Host ""

# Windows NTP Server Tweaks
    Write-Host "Fixing Workstation's NTP Server"
    if ($NTPservice -eq $null) { Start-Service -Name $NTPserviceName }
    Start-Process -FilePath w32tm -ArgumentList '/config /manualpeerlist:time.google.com /syncfromflags:MANUAL /reliable:yes /update' -WindowStyle Hidden
    Restart-Service W32Time
    Start-Process -FilePath w32tm -ArgumentList '/config /update' -WindowStyle Hidden
    Start-Process -FilePath w32tm -ArgumentList '/resync /nowait /rediscover' -WindowStyle Hidden

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
        if (Get-Process explorer) { Stop-Process -name explorer -force}
    }

Write-Host ""

# Windows Default Administrator Account Tweak
    # Activating Local Administrator Account    
    Write-Host "Activating Local Administrator Account..."
    if ((net user Administrator | Select-String -Pattern "Account active               No")) {
    net user Administrator /active:yes
    $AdminActive = $true
    }
    if ($AdminActive) { Write-Host "Local Administrator Account is NOW active" } else { Write-Host "Local Administrator Account is ALREADY active"}
    
    # Set Local Administrator Account Password
    Write-Host "Local Administrator Account's Password is Changing to its default value"
    if ($isAdmin) {
        $user = [ADSI]"WinNT://$env:COMPUTERNAME/Administrator,user"
        $user.SetPassword($password)
        $user.SetInfo()
        $AdminPW = $true
    } else { Write-Host "This $userName does not have previlage." }
    if ($AdminPW) { Write-Host "Local Administrator Account's Password has been changed to its default value " } else { Write-Host "Password Value has not been set. Local Administrator Account's Password has not been changed." }

Write-Host ""

    # Laptop
    if ($laptop) {
        Write-Host "Starting a Laptop Configuration.."

    # Power Plan Tweaks
        Write-Host "Tweaking Power Plan for Laptop"
        powercfg.exe /setactive $LpowerPlanGUID

        # 'Display Turn OFF' Value
        powercfg /change monitor-timeout-ac '30'
        powercfg /change monitor-timeout-dc '15'

        # Sleep Value
        powercfg /change standby-timeout-ac '0'
        powercfg /change standby-timeout-dc '0'

    # Disabling NVIDIA High Definition Audio for Monitor
        Write-Host "Disabling NVIDIA High Definition Audio for Monitor"
        if (-not($audioDeviceId -eq $null)) { Disable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false -ErrorAction SilentlyContinue }
}

# Desktop
    if ($desktop) {
        # Change Power Plan to High Performance
        Write-Host "Tweaking Power Plan for Desktop"
        powercfg.exe /setactive $HpowerPlanGUID

        # 'Display Turn OFF' Value
        powercfg /change monitor-timeout-ac '30'

        # Sleep Value
        powercfg /change standby-timeout-ac '0'

        # Disabling NVIDIA High Definition Audio for Monitor
        Write-Host "Disabling NVIDIA High Definition Audio for Monitor"
        if (-not($audioDeviceId -eq $null)) { Disable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false -ErrorAction SilentlyContinue }
}

# Server
    if ($server) {
        Write-Host "Tweaks for Server are still in maintenance."
}

Write-Host ""

# Ask client for Software installation on workstation
    do {
        $swChoice = Read-Host -Prompt "Will $computerName / $userName require a General Application 'Auto-Install'?: "
        if ($swChoice.ToUpper() -eq "YES" -or $swChoice.ToUpper() -eq "Y") { $Softwares = $true } 
        elseif ($swChoice.ToUpper() -eq "NO" -or $swChoice.ToUpper() -eq "N") { $Softwares = $false } 
        else { 
            Write-Host "You must select either Yes (Y) or No (N)." 
        }
    } while (-not ($Softwares -eq $true -or $Softwares -eq $false))

# Check for Administrator Previlage
    if (-not ($isAdmin)) {
    # Prompt for credentials
    $cred = Get-Credential -Message "Please enter the credentials of an account with administrative privileges."

    # Validate the credentials
    $principal = New-Object Security.Principal.WindowsPrincipal $cred.GetNetworkCredential().UserName
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        if (-not $isAdmin) {
            Write-Host "The provided account does not have administrative privileges."
            exit
        }
    }

# Software Installation
    if ($Softwares -eq $true) {
        # Chipset
        Write-Host "Installing Processor's Latest Chipset Driver"
        # determine and install
        if ($processor -like '*AMD*') { Start-Process powershell.exe -ArgumentList "choco install 'amd-ryzen-chipset' --limitoutput --no-progress" -Verb RunAs -ErrorAction Ignore } 
        elseif ($processor -like '*Intel*') { Start-Process powershell.exe -ArgumentList "choco install 'intel-chipset-device-software' --limitoutput --no-progress" -Verb RunAs -ErrorAction Ignore } 
        else { 
            Write-Host "Failed to determine processor's information." 
        }

    # General Softwares
        Write-Host "Installing Softwares using Installation Methods of Chocolatey & Winget"

    # Checking if 'Chocolatey & Winget' is installed
        if (-not ($Test_Choco)) { irm minseochoi.tech/script/install-choco }
        if (-not (Test-WinUtil-PATH-Checker -winget)) { irm minseochoi.tech/script/script/install-winget }

    # Installing software from the list from above
            foreach ($csoftware in $csoftwares) {
                Write-Host "Installing $csoftware"
                choco install $csoftware --limitoutput --no-progress
                if (-not(choco list -e $csoftware)) { { Write-Host "Failed to Install $csoftware" } }
            }
            
        foreach ($wsoftware in $wsoftwares) {
                Write-Host "Installing $wsoftware"
                winget install $wsoftware --accept-package-agreements --accept-source -agreements --uninstall-previous --silent
                if (-not(winget list -q $wsoftware)) { Write-Host "Failed to Install $wsoftware" }
            }
        }

# Exit
    pause
    Exit

# End