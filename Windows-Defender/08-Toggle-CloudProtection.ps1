# 08-Toggle-CloudProtection.ps1
# Triggers: 1020 (cloud protection enabled), 1021 (cloud protection disabled)
# Toggles cloud-delivered protection (MAPS) off then back on.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

$original = (Get-MpPreference).MAPSReporting

Write-Host "[*] Disabling cloud protection / MAPS (Event 1021)..."
Set-MpPreference -MAPSReporting 0
Start-Sleep -Seconds 3

Write-Host "[*] Re-enabling cloud protection / MAPS — Advanced (Event 1020)..."
Set-MpPreference -MAPSReporting 2
Start-Sleep -Seconds 3

Set-MpPreference -MAPSReporting $original
Write-Host "[+] Cloud protection restored to original state (MAPSReporting = $original)."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
