# Ensure the script is running with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrative privileges. Please run it as an administrator." -ForegroundColor Red
    exit
}

# Check if OpenSSH Server is installed
$sshCapability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

if ($sshCapability.State -ne 'Installed') {
    Write-Host "Installing OpenSSH Server..."
    dism /Online /Add-Capability /CapabilityName:OpenSSH.Server~~~~0.0.1.0
} else {
    Write-Host "OpenSSH Server is already installed."
}

# Ensure SSHD service is started and set to automatic
if ((Get-Service -Name sshd -ErrorAction SilentlyContinue).Status -ne 'Running') {
    Write-Host "Starting SSHD service..."
    Start-Service sshd
} else {
    Write-Host "SSHD service is already running."
}
Set-Service -Name sshd -StartupType 'Automatic'

# Ensure SSH-Agent service is started and set to automatic
if ((Get-Service -Name ssh-agent -ErrorAction SilentlyContinue).Status -ne 'Running') {
    Write-Host "Starting SSH-Agent service..."
    Start-Service ssh-agent
} else {
    Write-Host "SSH-Agent service is already running."
}
Set-Service -Name ssh-agent -StartupType 'Automatic'

# Ensure firewall rule is added for SSHD
$firewallRule = Get-NetFirewallRule -DisplayName "SSHD service" -ErrorAction SilentlyContinue
if (-not $firewallRule) {
    Write-Host "Adding firewall rule for SSHD..."
    netsh advfirewall firewall add rule name="SSHD service" dir=in action=allow protocol=TCP localport=22
} else {
    Write-Host "Firewall rule for SSHD already exists."
}
