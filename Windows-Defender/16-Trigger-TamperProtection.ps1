# 16-Trigger-TamperProtection.ps1
# Triggers: 5013 (tamper protection blocked a change)
# Attempts to modify Defender settings while tamper protection is ON, which should be blocked.
# NOTE: Tamper protection must be ENABLED for this script to generate Event 5013.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

Write-Host "[*] Checking tamper protection status..."
$tamperStatus = (Get-MpComputerStatus).IsTamperProtected
Write-Host "    Tamper protection is: $(if ($tamperStatus) { 'ENABLED' } else { 'DISABLED' })"

if (-not $tamperStatus) {
    Write-Host "[!] Tamper protection is OFF. Event 5013 requires it to be ON."
    Write-Host "    Enable it: Windows Security > Virus & threat protection > Manage settings > Tamper Protection ON"
    Write-Host "    Then re-run this script."
    if ($ShowEvents) { Show-DefenderEvents -Since $start }
    return
}

Write-Host "[*] Attempting registry-based changes that tamper protection should block (Event 5013)..."

# Attempt 1: Try to disable Defender via registry (tamper protection should block)
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender"
try {
    Set-ItemProperty -Path $regPath -Name "DisableAntiVirus" -Value 1 -Type DWord -Force -ErrorAction Stop
    Write-Host "    Registry change succeeded — tamper protection may not be active."
    # Undo
    Remove-ItemProperty -Path $regPath -Name "DisableAntiVirus" -ErrorAction SilentlyContinue
} catch {
    Write-Host "[+] Registry change blocked: $($_.Exception.Message)"
}
Start-Sleep -Seconds 2

# Attempt 2: Try to stop the service
try {
    Stop-Service -Name "WinDefend" -Force -ErrorAction Stop
    Write-Host "    Service stop succeeded — tamper protection may not be active."
    Start-Service -Name "WinDefend" -ErrorAction SilentlyContinue
} catch {
    Write-Host "[+] Service stop blocked: $($_.Exception.Message)"
}
Start-Sleep -Seconds 2

# Attempt 3: Try to disable real-time monitoring via registry
$rtPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
try {
    if (-not (Test-Path $rtPath)) { New-Item -Path $rtPath -Force | Out-Null }
    Set-ItemProperty -Path $rtPath -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord -Force -ErrorAction Stop
    Write-Host "    Policy registry change succeeded — tamper protection may not cover policy keys."
    Remove-ItemProperty -Path $rtPath -Name "DisableRealtimeMonitoring" -ErrorAction SilentlyContinue
} catch {
    Write-Host "[+] Policy change blocked: $($_.Exception.Message)"
}
Start-Sleep -Seconds 3

Write-Host "[+] Tamper protection trigger attempts completed."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
