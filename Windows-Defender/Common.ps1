# Common.ps1 — Shared helpers for Windows Defender event-trigger scripts
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Admin {
    if (-not (Test-IsAdmin)) { throw "Run in elevated PowerShell (Administrator)." }
}

function Backup-DefenderPreferences {
    Write-Host "[*] Saving current Defender preferences..."
    return Get-MpPreference
}

function Restore-DefenderPreferences([psobject]$Saved) {
    Write-Host "[*] Restoring original Defender preferences..."
    Set-MpPreference -DisableRealtimeMonitoring          $Saved.DisableRealtimeMonitoring
    Set-MpPreference -DisableBehaviorMonitoring           $Saved.DisableBehaviorMonitoring
    Set-MpPreference -DisableIOAVProtection               $Saved.DisableIOAVProtection
    Set-MpPreference -DisableOnAccessProtection           $Saved.DisableOnAccessProtection
    Set-MpPreference -MAPSReporting                       $Saved.MAPSReporting
    Set-MpPreference -SubmitSamplesConsent                $Saved.SubmitSamplesConsent
}

function Show-DefenderEvents([datetime]$Since) {
    $defenderIds = 1000,1001,1002,1006,1007,1008,1010,1012,1013,1014,
                   1015,1016,1017,1018,1020,1021,1022,1023,1110,1111,
                   1116,1117,1118,1119,1120,1150,1151,1152,
                   2000,2001,2003,
                   3002,3004,3005,
                   5001,5004,5007,5008,5010,5011,5012,5013

    Write-Host "`n=== Windows Defender / Operational (since $Since) ==="
    Get-WinEvent -FilterHashtable @{
        LogName   = "Microsoft-Windows-Windows Defender/Operational"
        Id        = $defenderIds
        StartTime = $Since
    } -ErrorAction SilentlyContinue |
        Sort-Object TimeCreated |
        Select-Object TimeCreated, Id, Message |
        Format-Table -AutoSize -Wrap
}
