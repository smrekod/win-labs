# 04-Suspend-Resume-Protection.ps1
# Triggers: 842 (unable to reseal boot settings to TPM — protection temporarily suspended)
# Suspends BitLocker protection on the OS drive, which prevents TPM resealing, then resumes.
# If the OS drive is not encrypted, this script encrypts a VHD and suspends protection there.
param(
    [string]$VhdPath = "$env:TEMP\SOCLab-BL-Suspend-Test.vhdx",
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Assert-BitLockerModule

# Check if the OS drive is BitLocker-encrypted
$osVol = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue

if ($osVol -and $osVol.VolumeStatus -eq "FullyEncrypted") {
    Write-Host "[*] OS drive (C:) is BitLocker-encrypted. Suspending protection (Event 842)..."
    Suspend-BitLocker -MountPoint "C:" -RebootCount 1
    Start-Sleep -Seconds 5

    Write-Host "[*] Resuming protection on OS drive..."
    Resume-BitLocker -MountPoint "C:"
    Start-Sleep -Seconds 3

    Write-Host "[+] Suspend/resume cycle on OS drive completed."
} else {
    Write-Host "[*] OS drive is not encrypted. Using a VHD to demonstrate suspend/resume..."
    $driveLetter = $null

    try {
        $driveLetter = New-LabVHD -VhdPath $VhdPath -SizeBytes 100MB
        $securePass = ConvertTo-SecureString "SOCLab-P@ss2024!" -AsPlainText -Force

        Write-Host "[*] Enabling BitLocker on $driveLetter..."
        Enable-BitLocker -MountPoint $driveLetter `
                         -EncryptionMethod XtsAes128 `
                         -PasswordProtector `
                         -Password $securePass `
                         -UsedSpaceOnly `
                         -ErrorAction Stop

        # Wait for encryption
        $maxWait = 60
        $waited  = 0
        while ($waited -lt $maxWait) {
            $status = Get-BitLockerVolume -MountPoint $driveLetter -ErrorAction SilentlyContinue
            if ($status.VolumeStatus -eq "FullyEncrypted") { break }
            Start-Sleep -Seconds 3
            $waited += 3
        }

        Write-Host "[*] Suspending BitLocker protection on $driveLetter (Event 842)..."
        Suspend-BitLocker -MountPoint $driveLetter -RebootCount 0 -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5

        Write-Host "[*] Resuming BitLocker protection on $driveLetter..."
        Resume-BitLocker -MountPoint $driveLetter -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3

        Write-Host "[*] Cleaning up VHD..."
        Disable-BitLocker -MountPoint $driveLetter -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
    } catch {
        Write-Host "[!] Error: $($_.Exception.Message)"
    } finally {
        Remove-LabVHD -VhdPath $VhdPath
    }
}

Write-Host "[+] Suspend/resume protection sequence completed."

if ($ShowEvents) { Show-BitLockerEvents -Since $start }
