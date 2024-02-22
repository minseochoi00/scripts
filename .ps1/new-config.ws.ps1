Clear-Host

# env
  Write-Host "Comment: Feb v1"
  Write-Host "Setting up the required variables..."

# custom functions
  function Install {
      param (
          [string]$Apps,
          [string]$Arguments,
          [string]$NoHidden
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
        #$password = ""        # Generic Password that it will be reset to.
    # Get-Process | Get-Service
        # Explorer
            $Explorer = Get-Process explorer -ea SilentlyContinue
        # NTP-Server
            $NTPservice = Get-Service -Name "W32Time" -ea SilentlyContinue
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Default Variables
  # Software Installation
    $softwares = $false             # Auto Installation of Default Softwares.
  # NVIDIA High Definition Audio
    $VaudioDeviceID = $false        # Check for NVIDIA High Definition Audio is installed
  # Choice Reset
    $laptop = $false
    $desktop = $false
    $initial = $false
    $selectedOption = $null
    $selectedOption2 = $null
  # Default Administrator Account related reset
    $AdminActive = $false           # Default Variable = Checking if Local Administrator account is in 'active' status.
    $AdminPW = $false               # Default Variable = Checking if Local Administrator's Password has been 'changed'.
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
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Installation List
  # Intel
    $intel = @(
        "intel-chipset-device-software",           # Intel Chipset
        #"intel-dsa"                                # Intel Driver & Support Assistant
    )
  # AMD
    $amd = @(
        "amd-ryzen-chipset"                         # AMD Ryzen Chipset
    )
  # General
    $csoftwares = @(
        "brave",                                    # Brave Browser
        "vcredist-all",                             # Microsoft C++ 2015-2022 
        "javaruntime",                              # Java Runtime Environment
        "powershell-core"                           # Microsoft PowerShell
    )
  # Dell
    $dell_softwares = @(
        "dellcommandupdate",                        # Dell Update Command
        "supportassist"                             # Dell SupportAssist
    )
# Arguments
    $W32TM_ManualPeerList_Arg = "/config /manualpeerlist:time.google.com /syncfromflags:MANUAL /reliable:yes /update"
    $W32TM_Update_Arg = "/config /update"
    $W32TM_ReSync_Arg = "/resync /nowait /rediscover"
    $Win10_Style_RightClick_Arg = 'add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve'
    $BuiltIn_Administrator_Active_Check = (net user Administrator) -match "Account active               No"
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
