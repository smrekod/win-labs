# 00-Enable-Telemetry.ps1
# Ensures BitLocker event log channels are enabled.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

Write-Host "[*] Enabling BitLocker Management log channel..."
& wevtutil sl "Microsoft-Windows-BitLocker/BitLocker Management" /e:true 2>&1 | Out-Null

Write-Host "[*] Enabling BitLocker Operational log channel..."
& wevtutil sl "Microsoft-Windows-BitLocker/BitLocker Operational" /e:true 2>&1 | Out-Null

Write-Host "[*] Enabling BitLocker-Driver Operational log channel..."
& wevtutil sl "Microsoft-Windows-BitLocker-Driver-Performance/Operational" /e:true 2>&1 | Out-Null

Write-Host "[+] BitLocker event log channels enabled."

if ($ShowEvents) { Show-BitLockerEvents -Since $start }
