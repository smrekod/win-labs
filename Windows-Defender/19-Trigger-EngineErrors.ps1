# 19-Trigger-EngineErrors.ps1
# Triggers: 1150 (engine error), 5008 (engine critical error)
# Best-effort attempts to provoke engine errors. These events are rare in normal operation
# and may not fire reliably. Multiple strategies are attempted.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

Write-Host "[*] Attempting to trigger engine errors (Events 1150, 5008)..."
Write-Host "    NOTE: These events are difficult to trigger reliably. Multiple strategies will be tried."

# Strategy 1: Force a scan with extremely constrained resources
Write-Host "`n[*] Strategy 1: Scan with aggressive CPU throttle..."
$originalThrottle = (Get-MpPreference).ScanAvgCPULoadFactor
Set-MpPreference -ScanAvgCPULoadFactor 5
Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5
Set-MpPreference -ScanAvgCPULoadFactor $originalThrottle

# Strategy 2: Attempt to update signatures from a bogus path
Write-Host "[*] Strategy 2: Update signatures from invalid UNC path..."
try {
    $originalFallback = (Get-MpPreference).SignatureFallbackOrder
    Set-MpPreference -SignatureDefinitionUpdateFileSharesSources "\\NonExistent-SOCLab-Server\BadShare" -ErrorAction SilentlyContinue
    Update-MpSignature -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    # Restore
    Set-MpPreference -SignatureDefinitionUpdateFileSharesSources "" -ErrorAction SilentlyContinue
} catch {
    Write-Host "    Error: $($_.Exception.Message)"
}

# Strategy 3: Corrupt a temp definition file then scan
Write-Host "[*] Strategy 3: Drop a corrupt definition-like file..."
$defPath = "$env:TEMP\SOCLab-CorruptDef"
if (-not (Test-Path $defPath)) { New-Item -ItemType Directory -Path $defPath -Force | Out-Null }
$corruptFile = Join-Path $defPath "mpengine.dll"
[System.IO.File]::WriteAllBytes($corruptFile, @(0x00, 0xFF, 0xFE, 0x00, 0x42, 0x41, 0x44))
try {
    Start-MpScan -ScanType CustomScan -ScanPath $defPath -ErrorAction SilentlyContinue
} catch { }
Start-Sleep -Seconds 3
Remove-Item -Path $defPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n[+] Engine error trigger attempts completed."
Write-Host "    Events 1150/5008 may or may not have been generated — check the event log."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
