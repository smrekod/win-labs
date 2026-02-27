# 18-Trigger-HealthChange.ps1
# Triggers: 3002 (health status changed)
# Changes multiple Defender settings rapidly to trigger a health status change event.
# Event 3002 fires when Defender's overall health assessment changes (e.g., features disabled).
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

$prefs = Get-MpPreference

Write-Host "[*] Rapidly toggling multiple protection features to trigger health change (Event 3002)..."

# Disable several features at once to trigger an unhealthy state
Write-Host "    Disabling real-time monitoring..."
Set-MpPreference -DisableRealtimeMonitoring $true
Start-Sleep -Seconds 2

Write-Host "    Disabling behavior monitoring..."
Set-MpPreference -DisableBehaviorMonitoring $true
Start-Sleep -Seconds 2

Write-Host "    Disabling IOAV protection..."
Set-MpPreference -DisableIOAVProtection $true
Start-Sleep -Seconds 3

Write-Host "[*] Checking health status..."
try {
    $status = Get-MpComputerStatus
    Write-Host "    AntivirusEnabled : $($status.AntivirusEnabled)"
    Write-Host "    RealTimeEnabled  : $($status.RealTimeProtectionEnabled)"
    Write-Host "    AMRunningMode    : $($status.AMRunningMode)"
} catch {
    Write-Host "    Could not query status."
}

# Restore everything
Write-Host "[*] Restoring all features..."
Set-MpPreference -DisableRealtimeMonitoring $prefs.DisableRealtimeMonitoring
Set-MpPreference -DisableBehaviorMonitoring $prefs.DisableBehaviorMonitoring
Set-MpPreference -DisableIOAVProtection     $prefs.DisableIOAVProtection
Start-Sleep -Seconds 3

Write-Host "[+] Health change trigger completed."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
