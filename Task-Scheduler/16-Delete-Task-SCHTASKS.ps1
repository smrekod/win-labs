# 16-Delete-Task-SCHTASKS.ps1
param(
  [string]$BaseName="SOC-Lab",
  [string]$TaskNameSuffix="SCHTASKS-Delete",
  [string]$OutputFile="$env:ProgramData\SocLab\ScheduledTaskTest.log",
  [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Ensure-OutputPath $OutputFile

$TaskName = "$BaseName-$TaskNameSuffix"

# Create then delete
& schtasks /Delete /TN $TaskName /F 2>$null | Out-Null
$tr = "cmd.exe /c echo $([DateTime]::UtcNow.ToString('o')) schtasks-delete >> `"$OutputFile`""
& schtasks /Create /TN $TaskName /TR $tr /SC ONCE /ST 23:59 /RL HIGHEST /RU SYSTEM /F | Out-Null
Start-Sleep -Seconds 1

& schtasks /Delete /TN $TaskName /F | Out-Null
Start-Sleep -Seconds 1

Write-Host "[*] Deleted via schtasks: $TaskName"

if ($ShowEvents) { Show-RecentEvents -Since $start }
