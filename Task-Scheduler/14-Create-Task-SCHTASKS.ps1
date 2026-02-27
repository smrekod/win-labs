# 14-Create-Task-SCHTASKS.ps1
param(
  [string]$BaseName="SOC-Lab",
  [string]$TaskNameSuffix="SCHTASKS-Create",
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

# Clean first
& schtasks /Delete /TN $TaskName /F 2>$null | Out-Null

# Benign action
$tr = "cmd.exe /c echo $([DateTime]::UtcNow.ToString('o')) schtasks-create >> `"$OutputFile`""

# Create (ONCE)
& schtasks /Create /TN $TaskName /TR $tr /SC ONCE /ST 23:59 /RL HIGHEST /RU SYSTEM /F | Out-Null
Start-Sleep -Seconds 1

Write-Host "[*] Created via schtasks: $TaskName"

if (-not $KeepTask) {
  & schtasks /Delete /TN $TaskName /F | Out-Null
}

if ($ShowEvents) { Show-RecentEvents -Since $start }
