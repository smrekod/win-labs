# 15-Modify-Task-SCHTASKS.ps1
param(
  [string]$BaseName="SOC-Lab",
  [string]$TaskNameSuffix="SCHTASKS-Modify",
  [string]$OutputFile="$env:ProgramData\SocLab\ScheduledTaskTest.log",
  [switch]$KeepTask,
  [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Ensure-OutputPath $OutputFile

$TaskName = "$BaseName-$TaskNameSuffix"

# Create baseline task
& schtasks /Delete /TN $TaskName /F 2>$null | Out-Null
$tr1 = "cmd.exe /c echo $([DateTime]::UtcNow.ToString('o')) schtasks-before >> `"$OutputFile`""
& schtasks /Create /TN $TaskName /TR $tr1 /SC ONCE /ST 23:59 /RL HIGHEST /RU SYSTEM /F | Out-Null
Start-Sleep -Seconds 1

# Modify / Change TR
$tr2 = "cmd.exe /c echo $([DateTime]::UtcNow.ToString('o')) schtasks-after >> `"$OutputFile`""
& schtasks /Change /TN $TaskName /TR $tr2 | Out-Null
Start-Sleep -Seconds 1

Write-Host "[*] Modified via schtasks: $TaskName"

if (-not $KeepTask) {
  & schtasks /Delete /TN $TaskName /F | Out-Null
}

if ($ShowEvents) { Show-RecentEvents -Since $start }
