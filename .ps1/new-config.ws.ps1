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
