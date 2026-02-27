# 06-Trigger-TPM-VMK-Failure.ps1
# Triggers: 24635 (VMK failed — non-matching PCRs / boot integrity mismatch),
#           24636 (failure to obtain VMK from TPM)
# These events occur when the TPM refuses to unseal the volume master key because
# boot measurements (PCRs) don't match what was sealed. Best-effort strategies.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Assert-BitLockerModule

Write-Host "[*] Attempting to trigger TPM / VMK failure events (Events 24635, 24636)..."
Write-Host "    NOTE: These events normally fire at boot time when PCR values don't match."
Write-Host "    Best-effort strategies are used below.`n"

# Check TPM status
$tpmReady = $false
try {
    $tpm = Get-Tpm -ErrorAction Stop
    $tpmReady = $tpm.TpmReady
    Write-Host "    TPM Present : $($tpm.TpmPresent)"
    Write-Host "    TPM Ready   : $tpmReady"
} catch {
    Write-Host "    TPM not available: $($_.Exception.Message)"
}

# Strategy 1: If TPM is available, attempt to enable BitLocker with TPM on a VHD
# (TPM can only protect OS volumes, so this should fail → Event 24636)
if ($tpmReady) {
    Write-Host "`n[*] Strategy 1: Attempt TPM protector on a non-OS VHD (should fail)..."
    $vhdPath = "$env:TEMP\SOCLab-BL-TPM-Test.vhdx"
    $driveLetter = $null

    try {
        $driveLetter = New-LabVHD -VhdPath $vhdPath -SizeBytes 100MB

        try {
            Enable-BitLocker -MountPoint $driveLetter -TpmProtector -ErrorAction Stop
        } catch {
            Write-Host "[+] TPM protector on data volume failed as expected: $($_.Exception.Message)"
        }
        Start-Sleep -Seconds 3
    } catch {
        Write-Host "[!] VHD setup error: $($_.Exception.Message)"
    } finally {
        Remove-LabVHD -VhdPath $vhdPath
    }
}

# Strategy 2: Use manage-bde to attempt TPM unlock with wrong parameters
Write-Host "`n[*] Strategy 2: Using manage-bde to provoke TPM unlock failure..."
$bdeResult = & manage-bde -unlock C: -TPM 2>&1
Write-Host "    manage-bde -unlock: $bdeResult"
Start-Sleep -Seconds 3

# Strategy 3: Clear TPM owner auth (if available) to break VMK access
if ($tpmReady) {
    Write-Host "`n[*] Strategy 3: Attempting to read TPM endorsement key to provoke activity..."
    try {
        Get-TpmEndorsementKeyInfo -HashAlgorithm Sha256 -ErrorAction Stop | Out-Null
        Write-Host "    TPM EK info retrieved successfully."
    } catch {
        Write-Host "[+] TPM EK access failed: $($_.Exception.Message)"
    }
    Start-Sleep -Seconds 2
}

# Strategy 4: Modify PCR policy via registry to create a mismatch scenario
Write-Host "`n[*] Strategy 4: Setting mismatched PCR validation profile via registry..."
$blGpoPath = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
if (-not (Test-Path $blGpoPath)) { New-Item -Path $blGpoPath -Force | Out-Null }

# Save and modify
$origVal = (Get-ItemProperty -Path $blGpoPath -Name "OSPlatformValidation_UEFI" -ErrorAction SilentlyContinue).OSPlatformValidation_UEFI

# Set PCR profile to unusual values to trigger mismatch on next validation
Set-ItemProperty -Path $blGpoPath -Name "OSPlatformValidation_UEFI" -Value "0,1,2,3,4,5,6,7,8,9,10,11" -Type String -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# Restore
if ($null -ne $origVal) {
    Set-ItemProperty -Path $blGpoPath -Name "OSPlatformValidation_UEFI" -Value $origVal -Force
} else {
    Remove-ItemProperty -Path $blGpoPath -Name "OSPlatformValidation_UEFI" -ErrorAction SilentlyContinue
}

Write-Host "`n[+] TPM / VMK failure trigger attempts completed."
Write-Host "    Events 24635/24636 typically fire at boot time. Check logs after a reboot."

if ($ShowEvents) { Show-BitLockerEvents -Since $start }
