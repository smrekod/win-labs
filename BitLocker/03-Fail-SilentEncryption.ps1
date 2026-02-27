# 03-Fail-SilentEncryption.ps1
# Triggers: 851 (failed to enable Silent Encryption)
# Silent Encryption requires: TPM ready, Secure Boot, UEFI, Modern Standby, and DMA protection.
# On most lab VMs or machines missing prerequisites, this will fail and generate Event 851.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Assert-BitLockerModule

Write-Host "[*] Attempting to enable Silent Encryption on the OS drive (Event 851)..."
Write-Host "    Silent Encryption requires: TPM 2.0, Secure Boot, UEFI, DMA protection."
Write-Host "    If any prerequisite is missing, Event 851 should fire."

# Method 1: Group Policy approach — set the policy for silent encryption, then trigger
Write-Host "`n[*] Method 1: Setting registry keys for silent encryption policy..."
$blGpoPath = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
if (-not (Test-Path $blGpoPath)) { New-Item -Path $blGpoPath -Force | Out-Null }

# Save originals
$origSilent    = (Get-ItemProperty -Path $blGpoPath -Name "OSEnablePrebootInputProtectorsOnSlates" -ErrorAction SilentlyContinue).OSEnablePrebootInputProtectorsOnSlates
$origRequireAD = (Get-ItemProperty -Path $blGpoPath -Name "OSActiveDirectoryBackup" -ErrorAction SilentlyContinue).OSActiveDirectoryBackup

# Enable silent encryption policy
Set-ItemProperty -Path $blGpoPath -Name "OSEnablePrebootInputProtectorsOnSlates" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $blGpoPath -Name "OSActiveDirectoryBackup" -Value 1 -Type DWord -Force
Start-Sleep -Seconds 2

# Attempt to enable BitLocker with TPM-only protector (will fail without TPM)
try {
    Enable-BitLocker -MountPoint "C:" -TpmProtector -SkipHardwareTest -UsedSpaceOnly -ErrorAction Stop
    Write-Host "    BitLocker enabled — disabling to clean up."
    Disable-BitLocker -MountPoint "C:" -ErrorAction SilentlyContinue
} catch {
    Write-Host "[+] Silent encryption failed as expected: $($_.Exception.Message)"
}
Start-Sleep -Seconds 3

# Method 2: manage-bde approach
Write-Host "`n[*] Method 2: Using manage-bde to attempt silent encryption..."
$bdeResult = & manage-bde -on C: -SkipHardwareTest -UsedSpaceOnly 2>&1
Write-Host "    manage-bde: $bdeResult"
Start-Sleep -Seconds 3

# Restore registry
Write-Host "[*] Restoring original policy values..."
if ($null -ne $origSilent) {
    Set-ItemProperty -Path $blGpoPath -Name "OSEnablePrebootInputProtectorsOnSlates" -Value $origSilent -Type DWord -Force
} else {
    Remove-ItemProperty -Path $blGpoPath -Name "OSEnablePrebootInputProtectorsOnSlates" -ErrorAction SilentlyContinue
}
if ($null -ne $origRequireAD) {
    Set-ItemProperty -Path $blGpoPath -Name "OSActiveDirectoryBackup" -Value $origRequireAD -Type DWord -Force
} else {
    Remove-ItemProperty -Path $blGpoPath -Name "OSActiveDirectoryBackup" -ErrorAction SilentlyContinue
}

Write-Host "[+] Silent encryption failure trigger completed."

if ($ShowEvents) { Show-BitLockerEvents -Since $start }
