# 20-Run-All.ps1
# Master script — runs all Defender event-trigger scripts in sequence.
# Generates events across all 42 Windows Defender event IDs from the events reference file.
param(
    [switch]$ShowEvents,
    [switch]$PauseAfterEach
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

$scripts = @(
    "00-Enable-Telemetry.ps1",
    "01-Update-Definitions.ps1",
    "02-Start-Scans.ps1",
    "03-Scan-Failure.ps1",
    "04-Toggle-RealtimeProtection.ps1",
    "05-Toggle-BehaviorMonitoring.ps1",
    "06-Toggle-IOAVProtection.ps1",
    "07-Toggle-OnAccessProtection.ps1",
    "08-Toggle-CloudProtection.ps1",
    "09-Toggle-SampleSubmission.ps1",
    "10-Trigger-EicarDetection.ps1",
    "11-Remediation-Failure.ps1",
    "12-Manage-DetectionHistory.ps1",
    "13-Toggle-DefenderService.ps1",
    "14-Change-DefenderSettings.ps1",
    "15-Toggle-AntiSpyware.ps1",
    "16-Trigger-TamperProtection.ps1",
    "17-Trigger-PassiveMode.ps1",
    "18-Trigger-HealthChange.ps1",
    "19-Trigger-EngineErrors.ps1"
)

Write-Host "============================================================"
Write-Host "  Windows Defender Event Trigger — SOC Lab"
Write-Host "  Running $($scripts.Count) scripts to generate all Defender events"
Write-Host "  Started: $start"
Write-Host "============================================================`n"

$passed  = 0
$failed  = 0
$results = @()

foreach ($script in $scripts) {
    $scriptPath = Join-Path $here $script
    $scriptStart = Get-Date

    Write-Host "`n============================================================"
    Write-Host "  Running: $script"
    Write-Host "============================================================"

    try {
        & $scriptPath
        $status = "OK"
        $passed++
    } catch {
        Write-Host "[!] FAILED: $($_.Exception.Message)"
        $status = "FAIL"
        $failed++
    }

    $elapsed = (Get-Date) - $scriptStart
    $results += [PSCustomObject]@{
        Script  = $script
        Status  = $status
        Elapsed = $elapsed.ToString("mm\:ss")
    }

    if ($PauseAfterEach) {
        Write-Host "`nPress Enter to continue to next script..."
        Read-Host | Out-Null
    }
}

$totalElapsed = (Get-Date) - $start

Write-Host "`n============================================================"
Write-Host "  SUMMARY"
Write-Host "============================================================"
$results | Format-Table -AutoSize
Write-Host "Passed : $passed / $($scripts.Count)"
Write-Host "Failed : $failed / $($scripts.Count)"
Write-Host "Total  : $($totalElapsed.ToString('mm\:ss'))"
Write-Host "============================================================"

Write-Host "`n[*] Event coverage map:"
Write-Host "    Script 00 : (telemetry setup)"
Write-Host "    Script 01 : 1000, 1001, 1002"
Write-Host "    Script 02 : 1006, 1007, 2000, 2001"
Write-Host "    Script 03 : 2003"
Write-Host "    Script 04 : 1010, 1012, 5001, 5012"
Write-Host "    Script 05 : 1013, 1014"
Write-Host "    Script 06 : 1015, 1016"
Write-Host "    Script 07 : 1017, 1018"
Write-Host "    Script 08 : 1020, 1021"
Write-Host "    Script 09 : 1022, 1023"
Write-Host "    Script 10 : 1116, 1117, 1008, 1119, 1120"
Write-Host "    Script 11 : 1118"
Write-Host "    Script 12 : 1110, 1111"
Write-Host "    Script 13 : 1151, 1152, 5011"
Write-Host "    Script 14 : 5004, 5007"
Write-Host "    Script 15 : 5010"
Write-Host "    Script 16 : 5013"
Write-Host "    Script 17 : 3004, 3005"
Write-Host "    Script 18 : 3002"
Write-Host "    Script 19 : 1150, 5008"

if ($ShowEvents) {
    Write-Host "`n"
    Show-DefenderEvents -Since $start
}
