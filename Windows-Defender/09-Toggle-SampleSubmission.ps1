# 09-Toggle-SampleSubmission.ps1
# Triggers: 1022 (sample submission enabled), 1023 (sample submission disabled)
# Toggles automatic sample submission off then back on.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

$original = (Get-MpPreference).SubmitSamplesConsent

Write-Host "[*] Disabling sample submission — NeverSend (Event 1023)..."
Set-MpPreference -SubmitSamplesConsent 0
Start-Sleep -Seconds 3

Write-Host "[*] Re-enabling sample submission — SendAllSamples (Event 1022)..."
Set-MpPreference -SubmitSamplesConsent 3
Start-Sleep -Seconds 3

Set-MpPreference -SubmitSamplesConsent $original
Write-Host "[+] Sample submission restored to original state (SubmitSamplesConsent = $original)."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
