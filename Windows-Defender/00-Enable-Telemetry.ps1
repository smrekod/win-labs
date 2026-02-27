# 00-Enable-Telemetry.ps1
# Ensures the Windows Defender Operational event log channel is enabled.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

Write-Host "[*] Enabling Windows Defender Operational log channel..."
& wevtutil sl "Microsoft-Windows-Windows Defender/Operational" /e:true | Out-Null

Write-Host "[+] Defender Operational log is now enabled."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
