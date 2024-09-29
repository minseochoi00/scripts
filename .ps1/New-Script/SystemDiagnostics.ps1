<#
.SYNOPSIS
    System Diagnostics and Maintenance Script

.DESCRIPTION
    This script performs several system diagnostics and maintenance tasks to help maintain a healthy and stable Windows OS.
    It runs silently and reports which tasks succeeded and which need attention.

.NOTES
    Author: Minseo Choi
    Version: v1
#>

# Function to run a command silently and capture output
function Run-Command {
    param (
        [string]$Command,
        [string]$TaskName
    )

    Write-Host "Starting $TaskName..." -ForegroundColor Cyan

    try {
        # Initialize ProcessStartInfo object
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = "cmd.exe"
        $processInfo.Arguments = "/c $Command"
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true

        # Start the process
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        $process.Start() | Out-Null

        # Capture output and error streams
        $standardOutput = $process.StandardOutput.ReadToEnd()
        $standardError = $process.StandardError.ReadToEnd()

        $process.WaitForExit()

        $exitCode = $process.ExitCode

        if ($exitCode -eq 0) {
            Write-Host "$TaskName completed successfully." -ForegroundColor Green
        } else {
            Write-Host "$TaskName encountered errors. Please check logs." -ForegroundColor Red
        }

        # Save output to log files
        $logDirectory = "$PSScriptRoot\Logs"
        if (!(Test-Path $logDirectory)) {
            New-Item -ItemType Directory -Path $logDirectory | Out-Null
        }

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $outputFile = "$logDirectory\$TaskName`_$timestamp`_output.log"
        $errorFile = "$logDirectory\$TaskName`_$timestamp`_error.log"

        $standardOutput | Out-File -FilePath $outputFile -Encoding utf8
        $standardError | Out-File -FilePath $errorFile -Encoding utf8

    } catch {
        Write-Host "Failed to execute $TaskName. Error: $_" -ForegroundColor Red
    }
}

# Function to check for Windows Updates
function Check-WindowsUpdates {
    Write-Host "Checking for Windows Updates..." -ForegroundColor Cyan

    try {
        # Install PSWindowsUpdate module if not installed
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Install-Module -Name PSWindowsUpdate -Force -ErrorAction Stop
        }

        Import-Module PSWindowsUpdate

        # Set execution policy to allow scripts to run
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

        # Check for updates
        $Updates = Get-WindowsUpdate -AcceptAll -IgnoreReboot

        if ($Updates) {
            Write-Host "Updates are available. Initiating installation..." -ForegroundColor Yellow
            Install-WindowsUpdate -AcceptAll -IgnoreReboot -AutoReboot
            Write-Host "Windows Updates installed successfully." -ForegroundColor Green
        } else {
            Write-Host "No updates available." -ForegroundColor Green
        }
    } catch {
        Write-Host "Failed to check/install Windows Updates. Error: $_" -ForegroundColor Red
    }
}

# Main script execution
Write-Host "System Diagnostics and Maintenance Script" -ForegroundColor White
Write-Host "=========================================" -ForegroundColor White

# Create logs directory
$logDirectory = "$PSScriptRoot\Logs"
if (!(Test-Path $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory | Out-Null
}

# Run DISM to restore health
Run-Command -Command "Dism /Online /Cleanup-Image /RestoreHealth" -TaskName "DISM_RestoreHealth"

# Run SFC to scan and repair system files
Run-Command -Command "sfc /scannow" -TaskName "System_File_Checker_SFC"

# Optionally, check disk health
Run-Command -Command "chkdsk /scan" -TaskName "Check_Disk_Scan"

# Check for Windows Updates
Check-WindowsUpdates

Write-Host "Diagnostics and Maintenance Tasks Completed." -ForegroundColor White
