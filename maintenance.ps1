function global:Write-Verbose ( [string]$Message )

# check $VerbosePreference variable, and turns -Verbose on
{ if ( $VerbosePreference -ne ‘SilentlyContinue’ )
{ Write-Host ” $Message” -ForegroundColor ‘Yellow’ } }
$VerbosePreference = “Continue”

# Settings
$DaysToDelete = 1
$LogDate = get-date -format “MM-d-yy-HH”
$objShell = New-Object -ComObject Shell.Application
$objFolder = $objShell.Namespace(0xA)
$ErrorActionPreference = “silentlycontinue”
Start-Transcript -PATH C:\Windows\Temp\$LogDate.log

## Cleans all code off of the screen.
Clear-Host

$size = Get-ChildItem C:\Users\* -Include *.iso, *.vhd -Recurse -ErrorAction SilentlyContinue |
Sort Length -Descending |
Select-Object Name,
@{Name=”Size (GB)”;Expression={ “{0:N2}” -f ($_.Length / 1GB) }}, Directory |
Format-Table -AutoSize | Out-String
$Before = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq “3” } | Select-Object SystemName,

@{ Name = “Drive” ; Expression = { ( $_.DeviceID ) } },
@{ Name = “Size (GB)” ; Expression = {“{0:N1}” -f( $_.Size / 1gb)}},
@{ Name = “FreeSpace (GB)” ; Expression = {“{0:N1}” -f( $_.Freespace / 1gb ) } },
@{ Name = “PercentFree” ; Expression = {“{0:P1}” -f( $_.FreeSpace / $_.Size ) } } |

Format-Table -AutoSize | Out-String

## Stops the windows update service.

Get-Service -Name wuauserv | Stop-Service -Force -Verbose -ErrorAction SilentlyContinue

## Windows Update Service has been stopped successfully!

## Deletes the contents of windows software distribution.

Get-ChildItem “C:\Windows\SoftwareDistribution\*” -Recurse -Force -Verbose -ErrorAction SilentlyContinue | Remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue

## The Contents of Windows SoftwareDistribution have been Removed successfully!

 

## Deletes the contents of the Windows Temp folder.

Get-ChildItem “C:\Windows\Temp\*” -Recurse -Force -Verbose -ErrorAction SilentlyContinue |

Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete)) } |

Remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue

## The Contents of Windows Temp have been Removed successfully!

## Deletes all files and folders in user’s Temp folder.

Get-ChildItem “C:\users\*\AppData\Local\Temp\*” -Recurse -Force -ErrorAction SilentlyContinue |

Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete))} |

Remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue

## The contents of C:\users\$env:USERNAME\AppData\Local\Temp\ have been Removed successfully!

## Remove all files and folders in user’s Temporary Internet Files.

Get-ChildItem “C:\users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*” `-Recurse -Force -Verbose -ErrorAction SilentlyContinue |

Where-Object {($_.CreationTime -le $(Get-Date).AddDays(-$DaysToDelete))} |

Remove-item -force -recurse -ErrorAction SilentlyContinue

## All Temporary Internet Files have been Removed successfully!

## Cleans IIS Logs if applicable.

Get-ChildItem “C:\inetpub\logs\LogFiles\*” -Recurse -Force -ErrorAction SilentlyContinue |

Where-Object { ($_.CreationTime -le $(Get-Date).AddDays(-60)) } |

Remove-Item -Force -Verbose -Recurse -ErrorAction SilentlyContinue

## All IIS Logfiles over x days old have been Removed Successfully!

## Deletes the contents of the recycling Bin.

## The Recycling Bin is now being emptied!

$objFolder.items() | ForEach-Object { Remove-Item $_.PATH -ErrorAction Ignore -Force -Verbose -Recurse }

## The Recycling Bin has been emptied!

## Starts the Windows Update Service
Get-Service -Name wuauserv | Start-Service -Verbose


# Set StateFlags0012 setting for each item in Windows disk cleanup utility
Set-ItemProperty -PATH ‘HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Memory Dump Files’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Archive Files’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Queue Files’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Archive Files’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Queue Files’ -name StateFlags0012 -type DWORD -Value 2
Set-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files’ -name StateFlags0012 -type DWORD -Value 2

# Disk Clean-Up
cleanmgr /sagerun:12

do {
“waiting for cleanmgr to complete. . .”
start-sleep 5
} while ((get-wmiobject win32_process | where-object {$_.processname -eq ‘cleanmgr.exe’} | measure).count)

#Remove StateFlags0012 setting for each item in Windows disk cleanup utility

Remove-ItemProperty -PATH ‘HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Removeup Temp Folders’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Memory Dump Files’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Removeup Log Files’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Removeup Files’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Archive Files’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Queue Files’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Archive Files’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Queue Files’ -name StateFlags0012
Remove-ItemProperty -PATH ‘HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files’ -name StateFlags0012

## Disk Defragementaion
$computer = $env:computername

#Get all local disks on the local computer via WMI class Win32_Volume
Get-WmiObject -ComputerName $computer -Class win32_volume | Where-Object { $_.drivetype -eq 3 -and $_.driveletter -ne $null } |

#Perform a defrag analysis on each disk returned
ForEach-Object -begin {} -process {

#Initialise properties hashtable
$properties = @{}

#perform the defrag analysis
Write-Verbose $(“Analyzing volume ” + $_.DriveLetter + ” on computer ” + $computer)
$results = $_.DefragAnalysis()

#if the return code is 0 the operation was successful so output the results using the properties hashtable
if ($results.ReturnValue -eq 0) {
$properties.Add(‘ComputerName’,$_.__Server)
$properties.Add(‘DriveLetter’, $_.DriveLetter )
if ($_.DefragAnalysis().DefragRecommended -eq $true) { $properties.Add( ‘DefragRequired’,$true ) } else {$properties.Add( ‘DefragRequired’,$false)}
if (($_.FreeSpace / 1GB) -gt (($_.Capacity / 1GB) * 0.15)) { $properties.Add( ‘SufficientFreeSpace’,$true ) } else {$properties.Add( ‘SufficientFreeSpace’,$false)}
Write-Verbose “Analysis complete”
New-Object PSObject -Property $properties
}

#If the return code is 1 then access to perform the defag analysis was denied

ElseIf ($results.ReturnValue -eq 1) {

write-output (“Defrag analysis for disk ” + $_.DriveLetter + ” on computer ” + $_.__Server + ” failed: Access Denied”)

}

#If the return code is 2 defragmentation is not supported for the device specified

ElseIf ($results.ReturnValue -eq 2) {

write-output (“Defrag analysis for disk ” + $_.DriveLetter + ” on computer ” + $_.__Server + ” failed: Defrag is not supported for this volume”)

}

#If the return code is 3 defrag analysis cannot be performed as the dirty bit is set for the device

ElseIf ($results.ReturnValue -eq 3) {

write-output (“Defrag analysis for disk ” + $_.DriveLetter + ” on computer ” + $_.__Server + ” failed: The dirty bit is set for this volume”)

}

#If the return code is 4 there is not enough free space to perform defragmentation

ElseIf ($results.ReturnValue -eq 4) {

write-output (“Defrag analysis for disk ” + $_.DriveLetter + ” on computer ” + $_.__Server + ” failed: The is not enough free space to perform this action”)

}

#If the return code is 5 defragmentation cannot be performed as a corrupt Master file table was detected

ElseIf ($results.ReturnValue -eq 5) {

write-output (“Defrag analysis for disk ” + $_.DriveLetter + ” on computer ” + $_.__Server + ” failed: Possible Master File Table corruption”)

}

#If the return code is 6 or 7 the operation was cancelled

ElseIf ($results.ReturnValue -eq 6 -or $results.ReturnValue -eq 7) {

write-output (“Defrag analysis for disk ” + $_.DriveLetter + ” on computer ” + $_.__Server + ” failed: The operation was cancelled”)

}

#If the return code is 8 the defrag engine is already running

ElseIf ($results.ReturnValue -eq 8) {

write-output (“Defrag analysis for disk ” + $_.DriveLetter + ” on computer ” + $_.__Server + ” failed: The defragmentation engine is already running”)

}

#If the return code is 9 the script could not connect to the defrag engine on the machine specified

ElseIf ($results.ReturnValue -eq 9) {

write-output (“Defrag analysis for disk ” + $_.DriveLetter + ” on computer ” + $_.__Server + ” failed: Could not connect to the defrag engine”)

}

#If the return code is 10 a degrag engine error occured

ElseIf ($results.ReturnValue -eq 10) {

write-output (“Defrag analysis for disk ” + $_.DriveLetter + ” on computer ” + $_.__Server + ” failed: A defrag engine error occured”)

}

#Else an unknown error occured

Else {

write-output (“Defrag analysis for disk ” + $_.DriveLetter + ” on computer ” + $_.__Server + ” failed: An unknown error occured”)

} 

} #Close ForEach loop for Defrag Analysis

#Close else clause on test-computer if conditional

## Disk Space After Maintenance

 

$After =  Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq “3” } | Select-Object SystemName,

@{ Name = “Drive” ; Expression = { ( $_.DeviceID ) } },
@{ Name = “Size (GB)” ; Expression = {“{0:N1}” -f( $_.Size / 1gb)}},
@{ Name = “FreeSpace (GB)” ; Expression = {“{0:N1}” -f( $_.Freespace / 1gb ) } },
@{ Name = “PercentFree” ; Expression = {“{0:P1}” -f( $_.FreeSpace / $_.Size ) } } |

Format-Table -AutoSize | Out-String

## Sends some before and after info for ticketing purposes

Hostname ; Get-Date | Select-Object DateTime

Write-Verbose “Before: $Before”
Write-Verbose “After: $After”
Write-Verbose $size

## Completed Successfully!

Stop-Transcript } Cleanup