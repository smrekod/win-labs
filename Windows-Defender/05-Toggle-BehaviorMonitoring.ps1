# 05-Toggle-BehaviorMonitoring.ps1
# Triggers: 1013 (behavior monitoring enabled), 1014 (behavior monitoring disabled)
# Toggles behavior monitoring off then back on.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

$original = (Get-MpPreference).DisableBehaviorMonitoring

Write-Host "[*] Disabling behavior monitoring (Event 1014)..."
Set-MpPreference -DisableBehaviorMonitoring $true
Start-Sleep -Seconds 3

Write-Host "[*] Re-enabling behavior monitoring (Event 1013)..."
Set-MpPreference -DisableBehaviorMonitoring $false
Start-Sleep -Seconds 3

Set-MpPreference -DisableBehaviorMonitoring $original
Write-Host "[+] Behavior monitoring restored to original state."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
