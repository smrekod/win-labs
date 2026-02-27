# 00-Enable-Telemetry.ps1
param([switch]$ShowEvents)

$start = Get-Date
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Enable-TaskTelemetry

if ($ShowEvents) { Show-RecentEvents -Since $start }
