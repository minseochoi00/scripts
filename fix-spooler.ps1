Stop-Service -Name Spooler -Force

# To delete the files
Remove-Item -Path "$env:SystemRoot\System32\spool\PRINTERS\*.*"
 
Start-Service -Name Spooler
