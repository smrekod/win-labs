# 02-Fail-RecoveryBackup.ps1
# Triggers: 846 (failed to back up recovery information)
# Enables BitLocker on a VHD with a recovery password, then attempts to back up the
# recovery key to Azure AD / Active Directory, which should fail in a standalone lab.
param(
    [string]$VhdPath = "$env:TEMP\SOCLab-BL-Backup-Test.vhdx",
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Assert-BitLockerModule

$driveLetter = $null

try {
    $driveLetter = New-LabVHD -VhdPath $VhdPath -SizeBytes 100MB

    $securePass = ConvertTo-SecureString "SOCLab-P@ss2024!" -AsPlainText -Force

    Write-Host "[*] Enabling BitLocker on $driveLetter with recovery password..."
    Enable-BitLocker -MountPoint $driveLetter `
                     -EncryptionMethod XtsAes128 `
                     -PasswordProtector `
                     -Password $securePass `
                     -UsedSpaceOnly `
                     -ErrorAction Stop

    # Add a recovery password protector
    $rp = Add-BitLockerKeyProtector -MountPoint $driveLetter -RecoveryPasswordProtector
    $rpId = (Get-BitLockerVolume -MountPoint $driveLetter).KeyProtector |
            Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" } |
            Select-Object -First 1 -ExpandProperty KeyProtectorId

    Write-Host "[*] Recovery password protector added: $rpId"

    # Wait for encryption
    $maxWait = 60
    $waited  = 0
    while ($waited -lt $maxWait) {
        $status = Get-BitLockerVolume -MountPoint $driveLetter -ErrorAction SilentlyContinue
        if ($status.VolumeStatus -eq "FullyEncrypted") { break }
        Start-Sleep -Seconds 3
        $waited += 3
    }

    # Attempt backup to Azure AD (will fail on non-AAD-joined machines → Event 846)
    Write-Host "[*] Attempting to back up recovery key to Azure AD (Event 846)..."
    try {
        BackupToAAD-BitLockerKeyProtector -MountPoint $driveLetter -KeyProtectorId $rpId -ErrorAction Stop
    } catch {
        Write-Host "[+] Backup to AAD failed as expected: $($_.Exception.Message)"
    }
    Start-Sleep -Seconds 3

    # Attempt backup to AD DS (will also fail on standalone machines)
    Write-Host "[*] Attempting to back up recovery key to Active Directory..."
    try {
        Backup-BitLockerKeyProtector -MountPoint $driveLetter -KeyProtectorId $rpId -ErrorAction Stop
    } catch {
        Write-Host "[+] Backup to AD failed as expected: $($_.Exception.Message)"
    }
    Start-Sleep -Seconds 3

    # Alternative: use manage-bde to force AD backup failure
    Write-Host "[*] Attempting manage-bde AD backup..."
    $bdeResult = & manage-bde -protectors -adbackup $driveLetter -id $rpId 2>&1
    Write-Host "    manage-bde: $bdeResult"
    Start-Sleep -Seconds 3

    # Cleanup
    Disable-BitLocker -MountPoint $driveLetter -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
} catch {
    Write-Host "[!] Error: $($_.Exception.Message)"
} finally {
    Remove-LabVHD -VhdPath $VhdPath
}

Write-Host "[+] Recovery backup failure sequence completed."

if ($ShowEvents) { Show-BitLockerEvents -Since $start }
