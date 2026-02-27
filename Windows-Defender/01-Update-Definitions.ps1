# 01-Update-Definitions.ps1
# Triggers: 1000 (engine updated), 1001 (platform updated), 1002 (definitions updated)
# Forces a signature/definition update. Engine and platform events fire when updates are available.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

Write-Host "[*] Forcing signature and definition update (Events 1000, 1001, 1002)..."
Update-MpSignature -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5

Write-Host "[+] Update-MpSignature completed."
Write-Host "    Event 1002 (definitions updated) should always fire."
Write-Host "    Events 1000/1001 fire only when engine/platform updates are available."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
