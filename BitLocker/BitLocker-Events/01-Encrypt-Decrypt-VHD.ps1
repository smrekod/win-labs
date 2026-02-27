# 01-Encrypt-Decrypt-VHD.ps1
# Triggers: 24577 (encryption started), 24579 (encryption completed)
# Creates a VHD, encrypts it with BitLocker using a password protector, waits for completion,
# then decrypts and cleans up. Uses a VHD so the OS drive is never touched.
param(
    [string]$VhdPath = "$env:TEMP\SOCLab-BitLocker-Test.vhdx",
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Assert-BitLockerModule

$driveLetter = $null

try {
    # Create and mount a lab VHD
    $driveLetter = New-LabVHD -VhdPath $VhdPath -SizeBytes 100MB

    # Use a password protector (no TPM needed for data volumes)
    $securePass = ConvertTo-SecureString "SOCLab-P@ss2024!" -AsPlainText -Force

    Write-Host "[*] Enabling BitLocker on $driveLetter (Event 24577 — encryption started)..."
    Enable-BitLocker -MountPoint $driveLetter `
                     -EncryptionMethod XtsAes128 `
                     -PasswordProtector `
                     -Password $securePass `
                     -UsedSpaceOnly `
                     -ErrorAction Stop

    # Poll until encryption finishes
    Write-Host "[*] Waiting for encryption to complete (Event 24579)..."
    $maxWait = 120
    $waited  = 0
    while ($waited -lt $maxWait) {
        $status = Get-BitLockerVolume -MountPoint $driveLetter -ErrorAction SilentlyContinue
        if ($status.VolumeStatus -eq "FullyEncrypted") {
            Write-Host "[+] Volume $driveLetter is fully encrypted."
            break
        }
        Write-Host "    Status: $($status.VolumeStatus) — $($status.EncryptionPercentage)%"
        Start-Sleep -Seconds 3
        $waited += 3
    }

    Start-Sleep -Seconds 3

    # Decrypt
    Write-Host "[*] Disabling BitLocker on $driveLetter..."
    Disable-BitLocker -MountPoint $driveLetter -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5

    # Wait for decryption
    $waited = 0
    while ($waited -lt $maxWait) {
        $status = Get-BitLockerVolume -MountPoint $driveLetter -ErrorAction SilentlyContinue
        if ($null -eq $status -or $status.VolumeStatus -eq "FullyDecrypted") {
            Write-Host "[+] Volume $driveLetter is fully decrypted."
            break
        }
        Write-Host "    Decryption: $($status.VolumeStatus) — $($status.EncryptionPercentage)%"
        Start-Sleep -Seconds 3
        $waited += 3
    }
} catch {
    Write-Host "[!] Error: $($_.Exception.Message)"
} finally {
    # Cleanup
    Remove-LabVHD -VhdPath $VhdPath
}

Write-Host "[+] Encryption / decryption cycle completed."

if ($ShowEvents) { Show-BitLockerEvents -Since $start }
