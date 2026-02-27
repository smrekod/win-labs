# 04-Toggle-RealtimeProtection.ps1
# Triggers: 1010 (RT enabled), 1012 (RT disabled), 5001 (RT disabled), 5012 (RT config changed)
# Toggles real-time protection off then back on.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

$original = (Get-MpPreference).DisableRealtimeMonitoring

Write-Host "[*] Disabling real-time protection (Events 1012, 5001, 5012)..."
Set-MpPreference -DisableRealtimeMonitoring $true
Start-Sleep -Seconds 3

Write-Host "[*] Re-enabling real-time protection (Events 1010, 5012)..."
Set-MpPreference -DisableRealtimeMonitoring $false
Start-Sleep -Seconds 3

# Restore original state
Set-MpPreference -DisableRealtimeMonitoring $original
Write-Host "[+] Real-time protection restored to original state."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
