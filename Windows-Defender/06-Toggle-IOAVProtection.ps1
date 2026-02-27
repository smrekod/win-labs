# 06-Toggle-IOAVProtection.ps1
# Triggers: 1015 (IOAV enabled), 1016 (IOAV disabled)
# Toggles IOAV (download scanning) off then back on.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

$original = (Get-MpPreference).DisableIOAVProtection

Write-Host "[*] Disabling IOAV / download scanning (Event 1016)..."
Set-MpPreference -DisableIOAVProtection $true
Start-Sleep -Seconds 3

Write-Host "[*] Re-enabling IOAV / download scanning (Event 1015)..."
Set-MpPreference -DisableIOAVProtection $false
Start-Sleep -Seconds 3

Set-MpPreference -DisableIOAVProtection $original
Write-Host "[+] IOAV protection restored to original state."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
