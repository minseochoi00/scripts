$FolderPath = "C:\Your\Folder\Path"

Get-WmiObject Win32_Process | ForEach-Object {
    try {
        $ProcessPath = $_.ExecutablePath
        if ($ProcessPath -and $ProcessPath.StartsWith($FolderPath, [StringComparison]::OrdinalIgnoreCase)) {
            $_ | Select-Object ProcessName, ExecutablePath
        }
    } catch {
        Write-Error "Error processing $_.ProcessName"
    }
}
