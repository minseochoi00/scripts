# env
# General
    $space = Write-Host ""
    $stop = 'pause'

# Choco
    $cinstall = choco install
    $cuninstall = choco uninstall
    $Test_Choco = Get-Command -Name choco -ErrorAction Ignore

# Winget
    $winstall = winget install
    $wuninstall = winget uninstall

    function Test-WinUtil-PATH-Checker {
        <# .COMMENTS = This Function is for checking Winget #>
        Param([System.Management.Automation.SwitchParameter]$winget)
        if ($winget) { if (Test-Path ~\AppData\Local\Microsoft\WindowsApps\winget.exe) { return $true } }
        return $false
    }

# NVIDIA High Definition Audio Default
    $NVIDIA_HDA = 'True'

# Software installation Default
    $Softwares = "False"

# Retrieve Processor's Information
    $processor = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name

# ExecutionPolicy
    $Get_EXE_Policy = Get-ExecutionPolicy
    $BP = 'Bypass'
    $RS = 'RemoteSigned'
    # Set Execution Policy
        if (-not $Get_EXE_Policy -eq $BP) { Set-ExecutionPolicy $BP -Force -ErrorAction SilentlyContinue }

# Define the power plan GUID for "High performance" and "Balanced"
    $HpowerPlanGUID = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
    $LpowerPlanGUID = '381b4222-f694-41f0-9685-ff5bb260df2e'

# Get the List of InstanceID with the Name "NVIDIA High Definition Audio"
    try { Get-PnpDevice -FriendlyName "NVIDIA High Definition Audio" } catch { $NVIDIA_HDA = 'False' }
    if ($NVIDIA_HDA -eq 'True') { $audioDeviceId = (Get-PnpDevice -FriendlyName "NVIDIA High Definition Audio").InstanceId }

# Check if the current user has administrative privileges
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)

# Administrator Privileges
    $NoAdmin = "No"

# Set a Password for the local Administrator Account
    $password = "l0c@l@dm1n"

# Workstation Choice Reset
    $laptop = "False"
    $desktop = "False"
    $server = "False"

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

# Prompt for User either Desktop or Laptop
    if ($wsChoice.ToUpper() -eq "LAPTOP" -or $wsChoice.ToUpper() -eq "L") { $laptop = "True" } 
    elseif ($wsChoice.ToUpper() -eq "DESKTOP" -or $wsChoice.ToUpper() -eq "D") { $desktop = "True" } 
    elseif ($wsChoice.ToUpper() -eq "SERVER" -or $wsChoice.ToUpper() -eq "S") { $server = "True" } 
    else { 
        Write-Host "You must select either Laptop (L), Desktop (D), or Server (S)." 
        return
    }

# Windows Service Tweaks
    foreach ($service in $services) {
        Write-Output "Tweaking $service"
        Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled 
    }

# Windows NTP Server Tweaks
    Write-Host "Fixing Workstation's NTP Server"
    Start-Service 'W32Time'
    Start-Process -FilePath w32tm -ArgumentList '/config /manualpeerlist:time.google.com /syncfromflags:MANUAL /reliable:yes /update' -WindowStyle Hidden
    Restart-Service W32Time
    Start-Process -FilePath w32tm -ArgumentList '/config /update' -WindowStyle Hidden
    Start-Process -FilePath w32tm -ArgumentList '/resync /nowait /rediscover' -WindowStyle Hidden

# Windows Classic Right-Click Tweak for Windows 11
    Write-Host "Enabling Windows 10 Right-Click Style in Windows 11"
    if ((Get-CimInstance -ClassName Win32_OperatingSystem).Version -notmatch "^10") {
        Write-Host "Right-click tweak is only intended for Windows 11"
    } else {
        # Adding Registry to Workstation for Classic Right Click
        Write-Host "Tweaking to Classic Right-Click for Windows 11"
        reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
        # Restarting Windows Explorer
        Get-Process explorer | Stop-Process
    }

# Windows Default Administrator Account Tweak
    # Activating Local Administrator Account    
    Write-Output "Activating Local Administrator Accounts..."
    net user Administrator /active:yes

    # Set Local Administrator Account Password
    $user = [ADSI]"WinNT://$env:COMPUTERNAME/Administrator,user"
    $user.SetPassword($password)
    $user.SetInfo()
    Write-Output "The password for the local Administrator account has been set successfully."

# Laptop
    if ($laptop -eq "True") {
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
        Write-Host "Trying to disable 'NVIDIA High Definition Audio'"
        Disable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false -ErrorAction SilentlyContinue
        # Enable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false

    Pause
    return
}

# Desktop
elseif ($desktop -eq "True") {
    # Change Power Plan to High Performance
    Write-Host "Tweaking Power Plan for Desktop"
    powercfg.exe /setactive $HpowerPlanGUID

    # 'Display Turn OFF' Value
    powercfg /change monitor-timeout-ac '30'

    # Sleep Value
    powercfg /change standby-timeout-ac '0'

    # Disabling NVIDIA High Definition Audio for Monitor
    Write-Host "Disabling NVIDIA High Definition Audio for Monitor"
    Disable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false -ErrorAction SilentlyContinue
    # Enable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false

    Pause
    return
}

# Server
elseif ($server -eq "True") {
    Write-Host "Tweaks for Server are still in maintenance."
    Pause
    return   
}

else { Write-Host "No Options has been selected. Please make your selections." }

# Ask client for Software installation on workstation
    if ($swChoice.ToUpper() -eq "YES" -or $swChoice.ToUpper() -eq "Y") { $Softwares = "True" } 
    elseif ($swChoice.ToUpper() -eq "NO" -or $swChoice.ToUpper() -eq "N") { $Softwares = "False" } 
    else { 
        Write-Host "You must select either Yes (Y) or No (N)." 
        return
    }


# Software Installation
    if ($Softwares -eq "True") {
        # Chipset
        Write-Host "Installing Processor's Latest Chipset Driver"
        # determine and install
        if ($processor -like '*AMD*') { Start-Process powershell.exe -ArgumentList "$cinstall 'amd-ryzen-chipset' --limitoutput --no-progress" -Verb RunAs -ErrorAction Ignore } 
        elseif ($processor -like '*Intel*') { Start-Process powershell.exe -ArgumentList "$cinstall 'intel-chipset-device-software' --limitoutput --no-progress" -Verb RunAs -ErrorAction Ignore } 
        else { 
            Write-Host "Failed to determine processor's information." 
        }

    # General Softwares
        Write-Host "Installing Softwares using Installation Methods of Chocolatey & Winget"

    # Checking if 'Chocolatey & Winget' is installed
        if (-not $Test_Choco) { irm minseochoi.tech/script/install-choco }
        if (-not Test-WinUtil-PATH-Checker -winget) { irm minseochoi.tech/script/install-winget }

    # Installing software from the list from above
        Try {
            foreach ($csoftware in $csoftwares) {
                Write-Host "Installing $csoftware"
                # choco install $csoftwares --limitoutput --no-progress
                Start-Process powershell.exe -ArgumentList "$cinstall $csoftware --limitoutput --no-progress" -Verb RunAs -ErrorAction Ignore
            }
        } catch {
            Write-Host "Error occurred while working on: $csoftware"
        }

        Try {
            foreach ($wsoftware in $wsoftwares) {
                Write-Host "Installing $wsoftware"
                # winget install $wsoftwares
                Start-Process powershell.exe -ArgumentList "$winstall $wsoftware --limitoutput --no-progress" -Verb RunAs -ErrorAction Ignore
            }
        } catch {
            Write-Host "Error occurred while working on: $wsoftware"
        }
    }

# Exit
    $Stop
    Exit

# End