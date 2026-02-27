# 11-Remediation-Failure.ps1
# Triggers: 1118 (remediation failed)
# Attempts to create a scenario where Defender cannot remediate a detected file.
# This drops an EICAR file into a locked/in-use file handle so Defender cannot delete it.
param(
    [string]$DropPath = "$env:TEMP\SOCLab-LockedEICAR",
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

if (-not (Test-Path $DropPath)) { New-Item -ItemType Directory -Path $DropPath -Force | Out-Null }

$part1 = 'X5O!P%@AP[4\PZX54(P^)7CC)7}'
$part2 = '$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
$eicar = $part1 + $part2

$filePath = Join-Path $DropPath "eicar-locked.com"

Write-Host "[*] Attempting to trigger remediation failure (Event 1118)..."
Write-Host "    Strategy: write EICAR to a file held open with an exclusive lock."

$stream = $null
try {
    # Temporarily disable real-time monitoring so the file can be written
    Set-MpPreference -DisableRealtimeMonitoring $true
    Start-Sleep -Seconds 2

    # Write EICAR content and hold the file open with an exclusive lock
    $stream = [System.IO.File]::Open($filePath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    $bytes  = [System.Text.Encoding]::ASCII.GetBytes($eicar)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()

    Write-Host "    File locked: $filePath"

    # Re-enable real-time monitoring so Defender tries to remediate
    Set-MpPreference -DisableRealtimeMonitoring $false
    Start-Sleep -Seconds 2

    # Trigger a scan while the file is locked
    Write-Host "    Scanning locked file..."
    Start-MpScan -ScanType CustomScan -ScanPath $DropPath -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 10

    Write-Host "[+] If Defender could not delete the locked file, Event 1118 should have fired."
} catch {
    Write-Host "[!] Error: $($_.Exception.Message)"
} finally {
    if ($null -ne $stream) { $stream.Close(); $stream.Dispose() }
    Set-MpPreference -DisableRealtimeMonitoring $false
    if (Test-Path $DropPath) { Remove-Item -Path $DropPath -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($ShowEvents) { Show-DefenderEvents -Since $start }
