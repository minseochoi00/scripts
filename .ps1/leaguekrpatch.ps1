<#
    This leaguekrpatch.ps1 is for Korean Patch for US League of Legegends.
    This will automatically help the user to patch from any language to KR.
#>
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/minseochoi00/LeagueOfLegendsKoreanPatch/main/c_krpatch.ps1'))