# 22-Restart-ScheduleService.ps1
param(
  [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

Write-Host "[*] Restarting Task Scheduler service (Schedule)..."
Restart-Service -Name "Schedule" -Force
Start-Sleep -Seconds 2
Write-Host "[*] Service restarted."

if ($ShowEvents) { Show-RecentEvents -Since $start }
