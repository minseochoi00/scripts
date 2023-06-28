# Settings
    # Define the power plan GUID for "High performance" and "Balanced"
        $HpowerPlanGUID = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
        $LpowerPlanGUID = '381b4222-f694-41f0-9685-ff5bb260df2e'
    # Get the List of InstanceID with the Name "NVIDIA High Definition Audio"
        $audioDeviceId = (Get-PnpDevice -FriendlyName "NVIDIA High Definition Audio").InstanceId
    # Check if this workstation has battery (to determine if it is a laptop or desktop)
        $hasBattery = Get-WmiObject -Class Win32_Battery
    # Check if the current user has administrative privileges
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    # Check if the local Administrator Account is ACTIVE
        $adminAccount = Get.Get-WmiObject -Class Win32_UserAccount -Filter "Name='Administrator'"
    # Set a Password for the local Administrator Account
        $password = "l0c@l@dm1n"
    # Administrator Priveilges
        $NoAdmin = "No"

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $NoAdmin = "Yes"
}

###- Connected User Experiences and Telemetry
###- FAX
###- AllJoyn Router Service
###- Program Compatibility Assistant Service
###- Device Management Wireless Application Protocol (WAP) Push message Routing Service
###- Remote Registry
###- Windows Media Player Network Sharing Service
###- Windows Image Acquisition
###- Xbox Services
###- Windows Network Data Usage Monitor###

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
	#"wisvc"								   # Windows Insider Service. Disable this service only if you're not in the Windows Insider program. Currently, as Windows 11 is only available through it, you shouldn't disable it. 
)	

foreach ($service in $services) {
    Write-Output "Trying to disable $service"
    Get-Service -Name $service | Set-Service -StartupType Disabled
}

try {
    Write-Host "Fixing Workstation NTP Server"
    Start-Service 'W32Time'
    w32tm /config /manualpeerlist:time.google.com /syncfromflags:MANUAL /reliable:yes /update
    Restart-Service W32Time
    w32tm /config /update
}
catch {
    Write-Output "An error occured while working on the Workstation's NTP Server: $($_.Exception.Message)"
}

try {
    Write-Host "Enabling Windows 10 Right-Click Style in Windows 11"
        if ((Get-CimInstance -ClassName Win32_OperatingSystem).Version -notmatch "^10") {
        Write-Host "This script is only intended for only Windows 11"
        Write-Host "This Script will be skipped automatically..."
        } else {
        # Adding Registry to Workstation for Classic Right Click
        reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
        # Restarting Windows Explorer
        Get-Process explorer | Stop-Process
            
            # Restore back to Windows 11
            # reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f
    }
}
catch {
    Write-Output "An error occured while tweaking Right Click Style on Windows 11: $($_.Exception.Message)"
}

if ($NoAdmin -eq 'No') {
    if (-not $adminAccount.Enabled) {
        Write-Error "The Local Administrator account is not active.."
        Write-Output "Activating Local Administrator Accounts now..."
        $adminAccount.Disabled = $false
        $adminAccount.Put()
    } 
    
    # Setting up Saved Password of $password as Local Administrator Passwords
        $user = [ADSI]"WinNT://$env:COMPUTERNAME/Administrator,user"
        $user.SetPassword($password)
        $user.SetInfo()
    
    Write-Output "The password for the local Administrator account has been set successfully."
}


if ($hasBattery) {

        Write-Host "Starting a Laptop Configuration.."

        # Laptop

        Write-Host "Setting Acitve Power Plan to Balanced"
            # $Variable is Up above at the settings
            powercfg.exe /setactive $LpowerPlanGUID

    try {

        # Disabling  NVIDIA High Definition Audio for Monitor
        Write-Host "Disabling  NVIDIA High Definition Audio for Monitor"
        # $Variable is Up above at the settings
            Disable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false
            # Enable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false
    }
    catch {
        Write-Output "An error occured while disabling NVIDIA Audio: $($_.Exception.Message)"
    }

} else {

    Write-Host "Starting a Desktop Configuration.."

    # Desktop

    try {
        
        # Set the active power plan to "High performance"
        Write-Host "Setting Acitve Power Plan to High Performance"
            # $Variable is Up above at the settings
            powercfg.exe /setactive $HpowerPlanGUID

        # Disabling  NVIDIA High Definition Audio for Monitor
        Write-Host "Disabling  NVIDIA High Definition Audio for Monitor"
            # $Variable is Up above at the settings
            
        Disable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false
            # Enable-PnpDevice -InstanceId $audioDeviceId -Confirm:$false
    }
    catch {
        Write-Output "An error occured while working on the Desktop Tweaks: $($_.Exception.Message)"
    }
}