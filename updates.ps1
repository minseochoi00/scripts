# env
    # Choco
    $Test_Choco = Get-Command -Name choco -ErrorAction Ignore
        
    
# Check for Chocolatey Installation if can't be found install it.
    if ($Test_Choco) {
        Start-Process -FilePath choco -ArgumentList "upgrade chocolatey" -Verb RunAs -Wait
        Start-Process -FilePath choco -ArgumentList "upgrade all" -Verb RunAs -Wait
    }