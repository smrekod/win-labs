# 03-Scan-Failure.ps1
# Triggers: 2003 (scan failed)
# Attempts a custom scan against a non-existent path to provoke a scan failure.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

$fakePath = "C:\NonExistent_SOCLab_ScanTarget_$(Get-Random)"

Write-Host "[*] Attempting custom scan on non-existent path: $fakePath (Event 2003)..."
try {
    Start-MpScan -ScanType CustomScan -ScanPath $fakePath -ErrorAction Stop
} catch {
    Write-Host "[+] Scan failed as expected: $($_.Exception.Message)"
}
Start-Sleep -Seconds 3

if ($ShowEvents) { Show-DefenderEvents -Since $start }
