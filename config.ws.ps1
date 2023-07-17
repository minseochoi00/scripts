# env
    Write-Host "Setting up the required variables..."
# General
    $space = Write-Host ""
    $clean = Clear-Host

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
    $serviceName = "W32Time"
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

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

# Set a Password for the local Administrator Account
    $password = "l0c@l@dm1n"
    $AdminActive = $false
    $AdminPW = $false

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

$clean

# Prompt for User either Desktop or Laptop
do {
    $wsChoice = Read-Host -Prompt "Is $computerName / $userName a LAPTOP(L), DESKTOP (D) or SERVER (S)?: "
    if ($wsChoice.ToUpper() -eq "LAPTOP" -or $wsChoice.ToUpper() -eq "L") { $laptop = $true } 
    elseif ($wsChoice.ToUpper() -eq "DESKTOP" -or $wsChoice.ToUpper() -eq "D") { $desktop = $true } 
    elseif ($wsChoice.ToUpper() -eq "SERVER" -or $wsChoice.ToUpper() -eq "S") { $server = $true } 
    else { 
        Write-Host "You must select either Laptop (L), Desktop (D), or Server (S)." 
    }
} while (-not ($laptop -eq "True" -or $desktop -eq "True" -or $server -eq "True"))

$clean
$space

# Windows Service Tweaks
    foreach ($service in $services) {
        Write-Host "Tweaking $service"
        # Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled 
        Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled -ErrorAction SilentlyContinue
    }

$space

# Windows NTP Server Tweaks
    Write-Host "Fixing Workstation's NTP Server"
    if ($service -eq $null) { Start-Service -Name $serviceName }
    Start-Process -FilePath w32tm -ArgumentList '/config /manualpeerlist:time.google.com /syncfromflags:MANUAL /reliable:yes /update' -WindowStyle Hidden
    Restart-Service W32Time
    Start-Process -FilePath w32tm -ArgumentList '/config /update' -WindowStyle Hidden
    Start-Process -FilePath w32tm -ArgumentList '/resync /nowait /rediscover' -WindowStyle Hidden

$space

    # Windows Classic Right-Click Tweak for Windows 11
    Write-Host "Enabling Windows 10 Right-Click Style in Windows 11"
    if ((Get-CimInstance -ClassName Win32_OperatingSystem).Version -notmatch "^10") {
        Write-Host "Right-Click tweak is 'ONLY' intended for Windows 11"
    } else {
        # Adding Registry to Workstation for Classic Right Click
        Write-Host "Tweaking 'Classic Right-Click' for Windows 11"
        reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
        # Restarting Windows Explorer
        if (Get-Process explorer) { Stop-Process -name explorer }
    }

$space

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
        $user = [ADSI]"WinNT://$env:COMPUTERNAME/Administrator,user"
        $user.SetPassword($password)
        $user.SetInfo()
        $AdminPW = $true
    if ($AdminPW) { Write-Host "Local Administrator Account's Password has been changed to its default value " } else { Write-Host "Password Value has not been set. Local Administrator Account's Password has not been changed." }

$space

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

$space

# Ask client for Software installation on workstation
    do {
        $swChoice = Read-Host -Prompt "Will $computerName / $userName require a General Application 'Auto-Install'?: "
        if ($swChoice.ToUpper() -eq "YES" -or $swChoice.ToUpper() -eq "Y") { $Softwares = "True" } 
        elseif ($swChoice.ToUpper() -eq "NO" -or $swChoice.ToUpper() -eq "N") { $Softwares = "False" } 
        else { 
            Write-Host "You must select either Yes (Y) or No (N)." 
        }
    } while (-not ($Softwares -eq "True" -or $Softwares -eq "False"))

# Software Installation
    if ($Softwares) {
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
        if (-not ($Test_Choco)) { Start-Process powershell.exe -ArgumentList "irm minseochoi.tech/script/install-choco" -Verb RunAs }
        if (-not (Test-WinUtil-PATH-Checker -winget)) { Start-Process powershell.exe -ArgumentList "irm minseochoi.tech/script/script/install-winget" }

    # Installing software from the list from above
        Try {
            foreach ($csoftware in $csoftwares) {
                Write-Host "Installing $csoftware"
                Start-Process powershell.exe -ArgumentList "choco install $csoftware --limitoutput --no-progress" -Verb RunAs -ErrorAction Ignore
            }
        } catch {
            Write-Host "Error occurred while working on: $csoftware"
        }

        Try {
            foreach ($wsoftware in $wsoftwares) {
                Write-Host "Installing $wsoftware"
                Start-Process powershell.exe -ArgumentList "winget install $wsoftware --limitoutput --no-progress" -Verb RunAs -ErrorAction Ignore
            }
        } catch {
            Write-Host "Error occurred while working on: $wsoftware"
        }
    }

# Exit
    pause
    Exit

# End