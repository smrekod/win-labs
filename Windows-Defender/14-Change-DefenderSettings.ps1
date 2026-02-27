# 14-Change-DefenderSettings.ps1
# Triggers: 5004 (settings changed), 5007 (configuration changed)
# Modifies Defender settings (exclusion paths, scan preferences) to generate config-change events.
param(
    [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin

$testExclusion = "C:\SOCLab-ExclusionTest-$(Get-Random)"

Write-Host "[*] Adding exclusion path to trigger settings change (Events 5004, 5007)..."
Add-MpPreference -ExclusionPath $testExclusion
Start-Sleep -Seconds 3

Write-Host "[*] Changing scan schedule day..."
$originalDay = (Get-MpPreference).ScanScheduleDay
Set-MpPreference -ScanScheduleDay 3
Start-Sleep -Seconds 2

Write-Host "[*] Changing threat default action..."
$originalAction = (Get-MpPreference).ThreatIDDefaultAction_Actions
Set-MpPreference -ThreatIDDefaultAction_Ids 2147519003 -ThreatIDDefaultAction_Actions 6
Start-Sleep -Seconds 2

# Cleanup
Write-Host "[*] Removing test exclusion and restoring settings..."
Remove-MpPreference -ExclusionPath $testExclusion
Set-MpPreference -ScanScheduleDay $originalDay -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "[+] Settings change events generated."

if ($ShowEvents) { Show-DefenderEvents -Since $start }
