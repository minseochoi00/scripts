<#
.SYNOPSIS
    System Diagnostics and Maintenance Script with Timeout Handling

.DESCRIPTION
    This script performs system diagnostics and maintenance tasks to help maintain a healthy and stable Windows OS.
    It includes timeout handling to prevent commands from getting stuck.

.NOTES
    Author: Minseo Choi
    Version: v1
#>

# Function to run a command silently with timeout handling
function Run-Command {
    param (
        [string]$Command,
        [string]$TaskName,
        [int]$TimeoutInSeconds = 1800  # Default timeout set to 30 minutes
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

        # Capture output and error streams asynchronously
        $standardOutput = ''
        $standardError = ''

        $outputEvent = [System.Threading.AutoResetEvent]::new($false)
        $errorEvent = [System.Threading.AutoResetEvent]::new($false)

        $process.OutputDataReceived += {
            $standardOutput += $_.Data + "`n"
            if ($_.Data -eq $null) { $outputEvent.Set() }
        }
        $process.ErrorDataReceived += {
            $standardError += $_.Data + "`n"
            if ($_.Data -eq $null) { $errorEvent.Set() }
        }

        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()

        # Wait for the process to exit or timeout
        if ($process.WaitForExit($TimeoutInSeconds * 1000)) {
            # Wait for output streams to finish
            $outputEvent.WaitOne()
            $errorEvent.WaitOne()

            $exitCode = $process.ExitCode

            if ($exitCode -eq 0) {
                Write-Host "$TaskName completed successfully." -ForegroundColor Green
            } else {
                Write-Host "$TaskName encountered errors. Please check logs." -ForegroundColor Red
            }
        } else {
            # Timeout occurred
            Write-Host "$TaskName timed out after $TimeoutInSeconds seconds." -ForegroundColor Yellow
            $process.Kill()

            # Indicate timeout in exit code
            $exitCode = -1
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

# Define a timeout for long-running commands (in seconds)
$commandTimeout = 3600  # 1 hour timeout

# Run DISM to restore health with timeout
Run-Command -Command "Dism /Online /Cleanup-Image /RestoreHealth" -TaskName "DISM_RestoreHealth" -TimeoutInSeconds $commandTimeout

# Run SFC to scan and repair system files with timeout
Run-Command -Command "sfc /scannow" -TaskName "System_File_Checker_SFC" -TimeoutInSeconds $commandTimeout

# Optionally, check disk health with timeout
Run-Command -Command "chkdsk /scan" -TaskName "Check_Disk_Scan" -TimeoutInSeconds $commandTimeout

# Check for Windows Updates
Check-WindowsUpdates

Write-Host "Diagnostics and Maintenance Tasks Completed." -ForegroundColor White
