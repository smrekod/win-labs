# 17-Trigger-PassiveMode.ps1
# Triggers: 3004 (entered passive mode), 3005 (exited passive mode)
# Forces Defender into passive mode using the ForcePassiveMode registry key, then removes it.
# NOTE: On some builds this may require a service restart to take effect.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"

Write-Host "[*] Forcing Defender into passive mode via registry (Event 3004)..."
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }

$origVal = (Get-ItemProperty -Path $regPath -Name "ForcePassiveMode" -ErrorAction SilentlyContinue).ForcePassiveMode

Set-ItemProperty -Path $regPath -Name "ForcePassiveMode" -Value 1 -Type DWord -Force
Write-Host "    ForcePassiveMode = 1"
Start-Sleep -Seconds 5

# Alternative: use Set-MpPreference on supported builds
try {
    Set-MpPreference -PassiveMode $true -ErrorAction SilentlyContinue
} catch { }

Write-Host "[*] Checking passive mode status..."
try {
    $status = Get-MpComputerStatus
    Write-Host "    AMRunningMode: $($status.AMRunningMode)"
} catch {
    Write-Host "    Could not query status."
}
Start-Sleep -Seconds 3

Write-Host "[*] Exiting passive mode (Event 3005)..."
if ($null -ne $origVal) {
    Set-ItemProperty -Path $regPath -Name "ForcePassiveMode" -Value $origVal -Type DWord -Force
} else {
    Remove-ItemProperty -Path $regPath -Name "ForcePassiveMode" -ErrorAction SilentlyContinue
}

try {
    Set-MpPreference -PassiveMode $false -ErrorAction SilentlyContinue
} catch { }

Start-Sleep -Seconds 5

Write-Host "[+] Passive mode toggle completed."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
