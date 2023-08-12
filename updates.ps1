# Check for Chocolatey Installation
    $Test_Choco = Get-Command -Name choco -ErrorAction Ignore
        if (-not $Test_Choco) { Write-Host "Can't find Chocolatey" }

# Function to Upgrade Chocolatey and All Packages
    function Upgrade {
        param (
            [string]$Apps,
            [string]$Arguments
        )
        try {
            $Apps = "choco"
            if ($null -ne $Arguments -and $Arguments -ne "") {
                $CleanedArguments = $Arguments.TrimStart("upgrade ").Trim()  # Remove "upgrade " prefix
                Start-Process -FilePath "$Apps" -ArgumentList $CleanedArguments -Verb RunAs -Wait
            } else {
                Start-Process -FilePath "$Apps" -Verb RunAs -Wait
            }
        } catch {
            Write-Host "Error Installing: $_"
        }
    }

Upgrade -Arguments "chocolatey"
Upgrade -Arguments "all"
