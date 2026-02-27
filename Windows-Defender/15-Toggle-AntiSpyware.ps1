# 15-Toggle-AntiSpyware.ps1
# Triggers: 5010 (anti-spyware protection disabled)
# Toggles the DisableAntiSpyware preference.
# NOTE: This registry key is deprecated on modern Windows 10/11 (20H2+), but the event
#       may still be logged on older builds or when Group Policy enforces it.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

Write-Host "[*] Attempting to disable anti-spyware via Set-MpPreference (Event 5010)..."
try {
    Set-MpPreference -DisableAntiSpyware $true -ErrorAction Stop
    Start-Sleep -Seconds 3
    Write-Host "[+] DisableAntiSpyware set to true."

    Write-Host "[*] Re-enabling anti-spyware..."
    Set-MpPreference -DisableAntiSpyware $false
    Start-Sleep -Seconds 3
} catch {
    Write-Host "[!] Set-MpPreference failed: $($_.Exception.Message)"
    Write-Host "    Trying direct registry method..."

    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
    $origVal = (Get-ItemProperty -Path $regPath -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue).DisableAntiSpyware

    Set-ItemProperty -Path $regPath -Name "DisableAntiSpyware" -Value 1 -Type DWord -Force
    Start-Sleep -Seconds 3

    # Restore
    if ($null -ne $origVal) {
        Set-ItemProperty -Path $regPath -Name "DisableAntiSpyware" -Value $origVal -Type DWord -Force
    } else {
        Remove-ItemProperty -Path $regPath -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 2
}

Write-Host "[+] Anti-spyware toggle completed."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
