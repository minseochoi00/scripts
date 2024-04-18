$FolderPath = "C:\Your\Folder\Path"

# Use Get-CimInstance for better performance and because Get-WmiObject is deprecated
Get-CimInstance Win32_Process | ForEach-Object {
    try {
        $ProcessPath = $_.ExecutablePath
        # Using StartsWith method for string comparison
        if ($ProcessPath -and $ProcessPath.StartsWith($FolderPath, "CurrentCultureIgnoreCase")) {
            $_ | Select-Object ProcessName, ExecutablePath
        }
    } catch {
        Write-Error "Error processing $_.ProcessName"
    }
}