# 07-Toggle-OnAccessProtection.ps1
# Triggers: 1017 (on-access enabled), 1018 (on-access disabled)
# Toggles on-access protection off then back on.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

$original = (Get-MpPreference).DisableOnAccessProtection

Write-Host "[*] Disabling on-access protection (Event 1018)..."
Set-MpPreference -DisableOnAccessProtection $true
Start-Sleep -Seconds 3

Write-Host "[*] Re-enabling on-access protection (Event 1017)..."
Set-MpPreference -DisableOnAccessProtection $false
Start-Sleep -Seconds 3

Set-MpPreference -DisableOnAccessProtection $original
Write-Host "[+] On-access protection restored to original state."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
