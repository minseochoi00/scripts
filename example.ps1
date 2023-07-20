$question = "COMMANDS: "
$goBack = $false
$tempQuestion = "Any additional commands?"

:Main while (-not $goBack) {
    $commands = Read-Host -Prompt $question
    if ($commands.ToUpper() -eq "execute config" -or $commands.ToUpper() -eq "EXECUTE CONFIG" -or $commands.ToUpper() -eq "exe config" -or $commands.ToUpper() -eq "EXE CONFIG") { $config_ws = $true }
    elseif ($commands.ToUpper() -eq "execute install choco" -or $commands.ToUpper() -eq "EXECUTE INSTALL CHOCO" -or $commands.ToUpper() -eq "exe install choco" -or $commands.ToUpper() -eq "EXE INSTALL CHOCO") { $install_choco = $true }
    else { Write-Host "Invalid commands has been entered. $commands" }

    if ($config_ws) { irm minseochoi.tech/script/config.ws | iex }
    else { Write-Host "Error has occured." }

    Write-Host ""

    $choice = Read-Host -Prompt $tempQuestion
        if ($choice -eq "Yes" -or $choice -eq "yes" -or $choice -eq "Y" -or $choice -eq "y") { Write-Host "" }
        elseif ($choice -eq "No" -or $choice -eq "no" -or $choice -eq "N" -or $choice -eq "n") { break Main }
        else { Write-Host "Invalid choice. Enter either 'Y', or 'N'." }
}



<#
$question = "Enter multiple answers (separated by commas):"
$answers = @()

Write-Host $question
$answer = Read-Host

$answers += $answer.Split(',')

$goBack = $false

while (-not $goBack) {
    Write-Host "Current answers: $($answers -join ', ')"
    $prompt = "Do you want to change your answers? (Y/N)"
    $choice = Read-Host -Prompt $prompt

    if ($choice -eq "Y" -or $choice -eq "y") {
        $goBack = $true
        Write-Host "Enter new answers (separated by commas):"
        $newAnswer = Read-Host
        $answers = $newAnswer.Split(',')
    }
    elseif ($choice -eq "N" -or $choice -eq "n") {
        $goBack = $true
    }
    else {
        Write-Host "Invalid choice. Please enter 'Y' or 'N'."
    }
}

Write-Host "Answers: $($answers -join ', ')"
#>