# 07-Run-All.ps1
# Master script — runs all BitLocker event-trigger scripts in sequence.
# Generates events across all 9 BitLocker event IDs from the events reference file.
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
    "01-Encrypt-Decrypt-VHD.ps1",
    "02-Fail-RecoveryBackup.ps1",
    "03-Fail-SilentEncryption.ps1",
    "04-Suspend-Resume-Protection.ps1",
    "05-Trigger-SecureBoot-TCG.ps1",
    "06-Trigger-TPM-VMK-Failure.ps1"
)

Write-Host "============================================================"
Write-Host "  BitLocker Event Trigger — SOC Lab"
Write-Host "  Running $($scripts.Count) scripts to generate BitLocker events"
Write-Host "  Started: $start"
Write-Host "============================================================`n"

$passed  = 0
$failed  = 0
$results = @()

foreach ($script in $scripts) {
    $scriptPath  = Join-Path $here $script
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
Write-Host "    Script 01 : 24577, 24579  (encryption started / completed)"
Write-Host "    Script 02 : 846           (recovery backup failure)"
Write-Host "    Script 03 : 851           (silent encryption failure)"
Write-Host "    Script 04 : 842           (unable to reseal — protection suspended)"
Write-Host "    Script 05 : 813, 834      (Secure Boot / TCG log validation)"
Write-Host "    Script 06 : 24635, 24636  (TPM VMK failure / PCR mismatch)"

if ($ShowEvents) {
    Write-Host "`n"
    Show-BitLockerEvents -Since $start
}
