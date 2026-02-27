# 10-Trigger-EicarDetection.ps1
# Triggers: 1116 (malware detected), 1117 (cleaned/quarantined), 1008 (remediation action),
#           1119 (deleted), 1120 (quarantined)
# Drops the EICAR test string to disk so Defender detects and remediates it.
# EICAR is an industry-standard anti-malware test file — it is NOT real malware.
param(
    [string]$DropPath = "$env:TEMP\SOCLab-EICAR-Test",
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

if (-not (Test-Path $DropPath)) { New-Item -ItemType Directory -Path $DropPath -Force | Out-Null }

# The EICAR test string (split to avoid this script itself being flagged)
$part1 = 'X5O!P%@AP[4\PZX54(P^)7CC)7}'
$part2 = '$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
$eicar = $part1 + $part2

Write-Host "[*] Dropping EICAR test file to trigger detection (Events 1116, 1117, 1008, 1119, 1120)..."

# Drop multiple EICAR files to increase the chance of generating all event variants
$files = @("eicar-test1.com", "eicar-test2.txt", "eicar-test3.exe")
foreach ($file in $files) {
    $filePath = Join-Path $DropPath $file
    try {
        [System.IO.File]::WriteAllText($filePath, $eicar)
        Write-Host "    Dropped: $filePath"
    } catch {
        Write-Host "    Defender intercepted write for: $filePath (real-time protection active)"
    }
    Start-Sleep -Seconds 2
}

Write-Host "[*] Waiting for Defender to process detections..."
Start-Sleep -Seconds 10

# Trigger an on-demand scan of the drop path for any files that survived
try {
    Start-MpScan -ScanType CustomScan -ScanPath $DropPath -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
} catch {
    Write-Host "    Scan of drop path skipped: $($_.Exception.Message)"
}

# Cleanup
if (Test-Path $DropPath) { Remove-Item -Path $DropPath -Recurse -Force -ErrorAction SilentlyContinue }
Write-Host "[+] EICAR detection sequence completed."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
