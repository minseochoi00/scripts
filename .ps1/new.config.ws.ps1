<# LIST
    - Chocolatey Installation
    - Service Tweak
    - Local Administrator Tweak
    - Registry Tweak
#>
# ENV
    # Retreieve
        $computerName = $env:COMPUTERNAME                                                   # Retreieving Current Computer's Name
        $userName = $env:USERNAME                                                           # Retreieving Current User's Name
        $processor = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name     # Retreieving Processor's Information
        $manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer      # Retreieving Manufacturer
        $Domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain                  # Retreieving Domain
        $battery = (Get-WmiObject Win32_Battery).Description                                # Retreiving Battery Information
        $OS_Name = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption               # Retreiving Operating System's Name
        $OS_Version = (Get-CimInstance -ClassName Win32_OperatingSystem).Version            # Retreiving Operating System's Version
        $IP_Address = ()


    # Permission Administrator Check
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
# if Chocolatey is not installed, installed them.
    if (($isAdmin)) {
        if (-not(Get-Command -Name choco -ea Ignore)) { Invoke-RestMethod minseochoi.tech/script/install-choco | Invoke-Expression }
    } else {
            Write-Host "$userName does not have Administrative Previlage to install Chocolatey."
    }


# START




# END