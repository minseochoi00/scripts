# env
    # Choco
    $cinstall = choco install
    $cuninstall = choco uninstall
# Winget
    $winstall = winget install
    $wuninstall = winget uninstall
# Pause
    $stop = 'pause'
# NVIDIA High Definition Audio Default
    $NVIDIA_HDA = 'True'
# Software installation Default
    $Softwares = "False"
# Retreive Processer's Information
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
    try { Get-PnpDevice -FriendlyName "NVIDIA High Definition Audio" }
    catch { $NVIDIA_HDA = 'False'}
    if ($NVIDIA_HDA = 'True') { $audioDeviceId = (Get-PnpDevice -FriendlyName "NVIDIA High Definition Audio").InstanceId }
# Check if the current user has administrative privileges
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
# Administrator Priveilges
    $NoAdmin = "No"
# Set a Password for the local Administrator Account
    $password = "l0c@l@dm1n"
# Workstation Choice Reset
    $laptop = "False"
    $desktop = "False"
    $server = "False"
# Windows Service List 
    $services = @(
        "DiagTrack"                                # Connected User Experiences and Telemetry. If you're concerned with privacy and don't want to send usage data to Microsoft for analysis, then this service is one to go.
        "fxssvc.exe"				               # Fax. As its name suggests, this is a service needed only if you want to send and receive faxes.
        "AxInstSV"								   # AllJoyn Router Service. This is a service that lets you connect Windows to the Internet of Things and communicate with devices such as smart TVs, refrigerators, light bulbs, thermostats, etc.
        "PcaSvc"                                   # Program Compatibility Assistant Service (Unless you're still using legacy software on your Windows 11 PC, you can easily turn off this service. This service lets you detect software incompatibility issues for old games and software. But if you're using programs and apps built for Window 11, go ahead and disable it.)
        "dmwappushservice"						   # Device Management Wireless Application Protocol (WAP) Push message Routing Service. This service is another service that helps to collect and send user data to Microsoft. Strengthen your privacy by disabling it, it is recommended that you do so. 
        "Remote Registry"                          # Remote Registry. This service lets any user access and modify the Windows registry. It is highly recommended that you disable this service for security purposes. Your ability to edit the registry locally (or as admin) won't be affected. 
        "WMPNetworkSvc"                            # Windows Media Player Network Sharing Service
        "StiSvc"                                   # Windows Image Acquisition. This service is important for people who connect scanners and digital cameras to their PC. But if you don't have one of those, or are never planning on getting one, disable it by all means.
        "XblAuthManager"                           # Xbox Live Auth Manager. If you don't use Xbox app to play games, then you don't need any of the Xbox services.
        "XblGameSave"                              # Xbox Live Game Save Service
        "XboxNetApiSvc"                            # Xbox Live Networking Service
        "ndu"                                      # Windows Network Data Usage Monitor
    )

# Prompt for User either Desktop or Laptop
Read-Host -Prompt "is 'Current Workstation' Laptop(L), Desktop(D) or Server(S)"
if ($wsChoice.ToUpper() -eq "laptop") { $laptop = "True" } 
elseif ($wsChoice.ToUpper() -eq "desktop") { $desktop = "True" } 
elseif ($wsChoice.ToUpper() -eq "server") { $server = "True" } 
elseif ($wsChoice.ToUpper() -eq "Laptop") { $laptop = "True" }
elseif ($wsChoice.ToUpper() -eq "Desktop") { $desktop = "True" } 
elseif ($wsChoice.ToUpper() -eq "Server") { $server = "True" }
elseif ($wsChoice.ToUpper() -eq "l") { $laptop = "True" }
elseif ($wsChoice.ToUpper() -eq "d") { $desktop = "True" }
elseif ($wsChoice.ToUpper() -eq "s") { $server = "True" }
elseif ($wsChoice.ToUpper() -eq "L") { $laptop = "True" }
elseif ($wsChoice.ToUpper() -eq "D") { $desktop = "True" }
elseif ($wsChoice.ToUpper() -eq "S") { $server = "True" }
else { Write-Host "You must select either of the choices." }

# Windows Service Tweaks
    foreach ($service in $services) {
        Write-Output "Tweaking $service"
        Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled
    }

# Windows NTP Server Tweaks
    Write-Host "Fixing Workstation's NTP Server"
        tart-Service 'W32Time'
        tart-Process -FilePath w32tm -ArgumentList '/config /manualpeerlist:time.google.com /syncfromflags:MANUAL /reliable:yes /update' -WindowStyle Hidden
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

        # Change Power Plan to Balanced
            Write-Host "Tweaking Power Plan for Laptop"
            powercfg.exe /setactive $LpowerPlanGUID
    
            # 'Display Turn OFF' Value
            powercfg /change monitor-timeout-ac '30' -ErrorAction SilentlyContinue
            powercfg /change monitor-timeout-dc '15' -ErrorAction SilentlyContinue
    
            # Sleep Value
            powercfg /change standby-timeout-ac '0' -ErrorAction SilentlyContinue
            powercfg /change standby-timeout-dc '0' -ErrorAction SilentlyContinue
    
            # Disabling  NVIDIA High Definition Audio for Monitor
                Write-Host "Trying to disable 'NVIDIA High Definition Audio'"
            # $Variable is Up above at the settings
                Disable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false -ErrorAction SilentlyContinue
                # Enable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false
    Pause
    return
}

# Desktop
    if ($desktop -eq "True") {
               
        # Change Power Plan to High Performance
        Write-Host "Tweaking Power Plan for Desktop"
            # $Variable is Up above at the settings
            powercfg.exe /setactive $HpowerPlanGUID

        
        # 'Display Turn OFF' Value
        powercfg /change monitor-timeout-ac '30'

        # Sleep Value
        powercfg /change standby-timeout-ac '0'
    
        # Disabling  NVIDIA High Definition Audio for Monitor
        Write-Host "Disabling  NVIDIA High Definition Audio for Monitor"
            # $Variable is Up above at the settings
            
        Disable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false -ErrorAction SilentlyContinue
            # Enable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false
    Pause
    return
}

# Server
    if ($server -eq "True") {
    Write-Host "Tweaks for Server is still in maintenance."
    Pause
    return   
}

Read-Host -Prompt "Will this workstation require any installation of softwares?"
if ($swChoice.ToUpper() -eq "Yes") { $Softwares = "True" } 
elseif ($swChoice.ToUpper() -eq "yes") { $Softwares = "True" } 
elseif ($swChoice.ToUpper() -eq "Y") { $Softwares = "True" } 
elseif ($swChoice.ToUpper() -eq "y") { $Softwares = "True" }
elseif ($swChoice.ToUpper() -eq "No") { $Softwares = "False" } 
elseif ($swChoice.ToUpper() -eq "no") { $Softwares = "False" }
elseif ($swChoice.ToUpper() -eq "N") { $Softwares = "False" }
elseif ($swChoice.ToUpper() -eq "n") { $Softwares = "False" }
else { Write-Host "You must select either of the choices." }

if ($Softwares -eq "True") {

# Chipset
    Write-Host "Installating Processor's Latest Chipset Driver"
        # Determine
        if ($processor -like '*AMD*') { choco install 'amd-ryzen-chipset' --limitoutput --no-progress} 
        elseif ($processor -like '*Intel*')  { choco install 'intel-chipset-device-software' --limitoutput --no-progress}
        else { Write-Host "Failed to determine processor's information." }

}

# Exit
$Stop
Exit

# End
