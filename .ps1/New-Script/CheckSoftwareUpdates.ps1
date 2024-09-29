<#
.SYNOPSIS
    Checks for updates of specified software by comparing file hashes and versions.

.DESCRIPTION
    For each software item in the list, the script:
    - Computes the hash and version of the currently installed file.
    - Downloads the latest version from a specified URL.
    - Computes the hash and version of the downloaded file.
    - Compares the hashes to determine if an update is required.
    - Displays which software needs an update along with current and new versions.

.PARAMETER SoftwareList
    An array of software objects containing Name, CurrentFilePath, and DownloadUrl.

.EXAMPLE
    .\CheckSoftwareUpdates.ps1

.NOTES
    Author: [Minseo Choi]
    Version: [ v1 ]
#>

# Define the list of software to check
$SoftwareList = @(
    [PSCustomObject]@{
        Name = 'ExampleSoftware'
        CurrentFilePath = 'C:\Program Files\ExampleSoftware\Example.exe'
        DownloadUrl = 'https://example.com/Example.exe'
    },
    [PSCustomObject]@{
        Name = 'AnotherSoftware'
        CurrentFilePath = 'C:\Program Files\AnotherSoftware\Another.exe'
        DownloadUrl = 'https://example.com/Another.exe'
    }
)

# Function to check for software updates
function Check-SoftwareUpdate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Software
    )

    # Initialize result object
    $Result = [PSCustomObject]@{
        Name           = $Software.Name
        CurrentVersion = $null
        NewVersion     = $null
        UpdateRequired = $false
    }

    try {
        # Check if the current file exists
        if (Test-Path -Path $Software.CurrentFilePath) {
            # Compute hash of the current file
            $CurrentFileHash = Get-FileHash -Path $Software.CurrentFilePath -Algorithm SHA256

            # Get current version information
            $CurrentFileVersionInfo    = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($Software.CurrentFilePath)
            $Result.CurrentVersion     = $CurrentFileVersionInfo.FileVersion
        }
        else {
            Write-Host "Current file not found: $($Software.CurrentFilePath)"
            $CurrentFileHash           = $null
            $Result.CurrentVersion     = 'Not Installed'
        }

        # Download new file to a temporary location
        $TempFile = Join-Path -Path $env:TEMP -ChildPath "$($Software.Name)_$(Get-Random).tmp"
        Invoke-WebRequest -Uri $Software.DownloadUrl -OutFile $TempFile -ErrorAction Stop

        # Compute hash of the new file
        $NewFileHash = Get-FileHash -Path $TempFile -Algorithm SHA256

        # Get new version information
        $NewFileVersionInfo  = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($TempFile)
        $Result.NewVersion   = $NewFileVersionInfo.FileVersion

        # Compare hashes to determine if an update is required
        if ($CurrentFileHash -and ($CurrentFileHash.Hash -eq $NewFileHash.Hash)) {
            $Result.UpdateRequired = $false
        }
        else {
            $Result.UpdateRequired = $true
        }
    }
    catch {
        Write-Error "Error processing software $($Software.Name): $_"
    }
    finally {
        # Clean up the temporary file
        if (Test-Path -Path $TempFile) {
            Remove-Item -Path $TempFile -Force
        }
    }

    return $Result
}

# Array to store results
$Results = @()

# Process each software item
foreach ($Software in $SoftwareList) {
    $Result = Check-SoftwareUpdate -Software $Software
    $Results += $Result
}

# Display the results
Write-Host "`nUpdate Summary:`n"

foreach ($Result in $Results) {
    if ($Result.UpdateRequired) {
        Write-Host "$($Result.Name): Update required."
        Write-Host "Current Version: $($Result.CurrentVersion)"
        Write-Host "New Version:     $($Result.NewVersion)`n"
    }
    else {
        Write-Host "$($Result.Name): Up to date."
        Write-Host "Version: $($Result.CurrentVersion)`n"
    }
}
