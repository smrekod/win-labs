# 12-Manage-DetectionHistory.ps1
# Triggers: 1110 (detection history deleted), 1111 (detection history restored)
# Removes detected threats from history, then attempts to restore a quarantined item.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

# --- Event 1110: Delete detection history ---
Write-Host "[*] Removing all active threats from detection history (Event 1110)..."
try {
    Remove-MpThreat -ErrorAction SilentlyContinue
    Write-Host "[+] Remove-MpThreat completed."
} catch {
    Write-Host "[!] Remove-MpThreat error: $($_.Exception.Message)"
}
Start-Sleep -Seconds 3

# --- Event 1111: Restore quarantined item ---
Write-Host "[*] Attempting to restore most recent quarantined item (Event 1111)..."
try {
    # List quarantined threats
    $threats = Get-MpThreatDetection -ErrorAction SilentlyContinue
    if ($threats) {
        Write-Host "    Found $($threats.Count) detection(s). Attempting restore via MpCmdRun..."
    } else {
        Write-Host "    No recent detections found. Dropping EICAR to create one..."
        $part1 = 'X5O!P%@AP[4\PZX54(P^)7CC)7}'
        $part2 = '$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
        $eicar = $part1 + $part2
        $eicarPath = "$env:TEMP\SOCLab-eicar-restore.com"
        try {
            [System.IO.File]::WriteAllText($eicarPath, $eicar)
        } catch { }
        Start-Sleep -Seconds 5
    }

    # Attempt restore using MpCmdRun
    $mpCmd = Join-Path $env:ProgramFiles "Windows Defender\MpCmdRun.exe"
    if (Test-Path $mpCmd) {
        Write-Host "    Running: MpCmdRun.exe -Restore -All"
        & $mpCmd -Restore -All 2>&1 | ForEach-Object { Write-Host "    $_" }
    } else {
        Write-Host "[!] MpCmdRun.exe not found at expected path."
    }
} catch {
    Write-Host "[!] Restore error: $($_.Exception.Message)"
}
Start-Sleep -Seconds 3

Write-Host "[+] Detection history operations completed."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
