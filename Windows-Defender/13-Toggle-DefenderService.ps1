# 13-Toggle-DefenderService.ps1
# Triggers: 1151 (service stopped), 1152 (service started), 5011 (service stopped)
# Attempts to stop and restart the Windows Defender (WinDefend) service.
# NOTE: On modern Windows 10/11, stopping WinDefend requires tamper protection to be OFF.
#       This script may fail if tamper protection is enabled — that is expected.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

Write-Host "[*] Attempting to stop WinDefend service (Events 1151, 5011)..."
Write-Host "    NOTE: This requires tamper protection to be disabled."
try {
    Stop-Service -Name "WinDefend" -Force -ErrorAction Stop
    Write-Host "[+] WinDefend service stopped."
    Start-Sleep -Seconds 5

    Write-Host "[*] Restarting WinDefend service (Event 1152)..."
    Start-Service -Name "WinDefend" -ErrorAction Stop
    Write-Host "[+] WinDefend service restarted."
    Start-Sleep -Seconds 3
} catch {
    Write-Host "[!] Could not stop/start WinDefend: $($_.Exception.Message)"
    Write-Host "    This is normal if tamper protection is enabled."
    Write-Host "    To disable tamper protection: Windows Security > Virus & threat protection > Manage settings > Tamper Protection OFF"

    # Alternative: use sc.exe
    Write-Host "`n[*] Trying alternative: sc.exe stop/start WinDefend..."
    $stopResult = & sc.exe stop WinDefend 2>&1
    Write-Host "    sc.exe stop: $stopResult"
    Start-Sleep -Seconds 5

    $startResult = & sc.exe start WinDefend 2>&1
    Write-Host "    sc.exe start: $startResult"
    Start-Sleep -Seconds 3
}

if ($ShowEvents) { Show-DefenderEvents -Since $start }
