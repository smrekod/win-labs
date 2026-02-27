# 02-Start-Scans.ps1
# Triggers: 1006 (scan started), 1007 (scan completed), 2000 (scan started), 2001 (scan completed)
# Runs a quick scan against a small safe directory.
param(
    [string]$ScanPath = "$env:SystemRoot\Temp",
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

Write-Host "[*] Starting quick scan (Events 1006, 1007, 2000, 2001)..."
Start-MpScan -ScanType QuickScan
Start-Sleep -Seconds 10

Write-Host "[+] Quick scan completed."

Write-Host "`n[*] Starting custom scan on $ScanPath..."
Start-MpScan -ScanType CustomScan -ScanPath $ScanPath
Start-Sleep -Seconds 5

Write-Host "[+] Custom scan completed."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
