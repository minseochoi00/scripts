# Check if the script is running as Administrator
$adminCheck = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $adminCheck.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must be run as an Administrator!" -ForegroundColor Red
    exit
}

$FolderPath = "C:\Your\Folder\Path"

# Get all running processes with additional details
Get-CimInstance Win32_Process | ForEach-Object {
    try {
        $ProcessPath = $_.ExecutablePath
        if ($ProcessPath -and $ProcessPath.StartsWith($FolderPath, "CurrentCultureIgnoreCase")) {
            # Retrieve additional process details
            $processInfo = New-Object PSObject -Property @{
                "Process Name"  = $_.ProcessName
                "PID"           = $_.ProcessId
                "ExecutablePath" = $_.ExecutablePath
                "CommandLine"   = $_.CommandLine
                "Description"   = (Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Description)
            }
            $processInfo
        }
    } catch {
        Write-Error "Error processing process with ID $($_.ProcessId): $_"
    }
}
