# 05-Trigger-SecureBoot-TCG.ps1
# Triggers: 813 (TCG log entry missing/invalid for Secure Boot),
#           834 (TCG log invalid — filtered log for PCR[7])
# These events fire when BitLocker validates Secure Boot integrity and finds the TCG
# (Trusted Computing Group) log is missing, corrupted, or does not match expected PCR values.
# Best-effort: modifies Secure Boot validation settings to provoke validation failures.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Assert-BitLockerModule

Write-Host "[*] Attempting to trigger Secure Boot / TCG log validation events (Events 813, 834)..."
Write-Host "    NOTE: These events require TPM + Secure Boot. Best-effort on lab systems.`n"

# Check prerequisites
$tpmReady = $false
try {
    $tpm = Get-Tpm -ErrorAction Stop
    $tpmReady = $tpm.TpmReady
    Write-Host "    TPM Present : $($tpm.TpmPresent)"
    Write-Host "    TPM Ready   : $tpmReady"
} catch {
    Write-Host "    TPM not available: $($_.Exception.Message)"
}

$secureBootEnabled = $false
try {
    $secureBootEnabled = Confirm-SecureBootUEFI -ErrorAction Stop
    Write-Host "    Secure Boot : $secureBootEnabled"
} catch {
    Write-Host "    Secure Boot check failed: $($_.Exception.Message)"
}

# Strategy 1: Modify the PCR validation profile to include additional PCRs
# This can cause a mismatch on next validation cycle
Write-Host "`n[*] Strategy 1: Modifying PCR validation profile..."
$blGpoPath = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
if (-not (Test-Path $blGpoPath)) { New-Item -Path $blGpoPath -Force | Out-Null }

# Save original
$origPCR = (Get-ItemProperty -Path $blGpoPath -Name "OSPlatformValidation_BIOS" -ErrorAction SilentlyContinue).OSPlatformValidation_BIOS

# Set unusual PCR profile that includes PCR[7] (Secure Boot)
# PCR 0,2,4,7,11 — adding PCR 7 and 11 may trigger validation events
Set-ItemProperty -Path $blGpoPath -Name "UseEnhancedPin" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $blGpoPath -Name "UseTPMPIN" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Strategy 2: Force a BitLocker integrity validation via manage-bde
Write-Host "[*] Strategy 2: Running manage-bde status check to provoke validation..."
$bdeResult = & manage-bde -status C: 2>&1
Write-Host "    $($bdeResult | Select-Object -First 10 | Out-String)"

# Strategy 3: If the OS drive is encrypted, modify boot config to provoke PCR mismatch
if ($tpmReady) {
    Write-Host "[*] Strategy 3: Temporarily modifying BCD to alter boot measurements..."
    try {
        # Change boot debug setting (changes PCR values)
        $origDebug = & bcdedit /enum "{current}" 2>&1 | Select-String "debug"
        & bcdedit /set "{current}" bootlog Yes 2>&1 | Out-Null
        Start-Sleep -Seconds 3
        # Revert
        & bcdedit /set "{current}" bootlog No 2>&1 | Out-Null
        Write-Host "    BCD boot log toggled."
    } catch {
        Write-Host "    BCD modification skipped: $($_.Exception.Message)"
    }
}

# Restore originals
if ($null -ne $origPCR) {
    Set-ItemProperty -Path $blGpoPath -Name "OSPlatformValidation_BIOS" -Value $origPCR -Type DWord -Force
}
Remove-ItemProperty -Path $blGpoPath -Name "UseEnhancedPin" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $blGpoPath -Name "UseTPMPIN" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "`n[+] Secure Boot / TCG trigger attempts completed."
Write-Host "    Events 813/834 may fire on next reboot if boot measurements changed."

if ($ShowEvents) { Show-BitLockerEvents -Since $start }
