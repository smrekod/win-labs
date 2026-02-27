# Common.ps1 — Shared helpers for BitLocker event-trigger scripts
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

function Assert-BitLockerModule {
    if (-not (Get-Module -ListAvailable -Name BitLocker)) {
        throw "BitLocker PowerShell module not available. Ensure the BitLocker feature is installed."
    }
    Import-Module BitLocker -ErrorAction Stop
}

function New-LabVHD {
    param(
        [string]$VhdPath,
        [uint64]$SizeBytes = 100MB
    )
    Write-Host "[*] Creating lab VHD: $VhdPath ($([math]::Round($SizeBytes / 1MB)) MB)..."
    if (Test-Path $VhdPath) { Remove-Item $VhdPath -Force }

    $diskpartScript = @"
create vdisk file="$VhdPath" maximum=$([math]::Floor($SizeBytes / 1MB)) type=expandable
select vdisk file="$VhdPath"
attach vdisk
create partition primary
format fs=ntfs label="SOCLab-BL" quick
assign
"@
    $tempScript = "$env:TEMP\SOCLab-diskpart-$(Get-Random).txt"
    Set-Content -Path $tempScript -Value $diskpartScript
    & diskpart /s $tempScript | Out-Null
    Remove-Item $tempScript -Force -ErrorAction SilentlyContinue

    # Find the drive letter that was assigned
    Start-Sleep -Seconds 2
    $vol = Get-Volume | Where-Object { $_.FileSystemLabel -eq "SOCLab-BL" } | Select-Object -First 1
    if ($null -eq $vol) { throw "Failed to mount lab VHD." }
    $driveLetter = "$($vol.DriveLetter):"
    Write-Host "[+] VHD mounted at $driveLetter"
    return $driveLetter
}

function Remove-LabVHD {
    param([string]$VhdPath)
    Write-Host "[*] Detaching and removing lab VHD: $VhdPath..."
    $diskpartScript = @"
select vdisk file="$VhdPath"
detach vdisk
"@
    $tempScript = "$env:TEMP\SOCLab-diskpart-$(Get-Random).txt"
    Set-Content -Path $tempScript -Value $diskpartScript
    & diskpart /s $tempScript 2>&1 | Out-Null
    Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (Test-Path $VhdPath) { Remove-Item $VhdPath -Force -ErrorAction SilentlyContinue }
    Write-Host "[+] Lab VHD removed."
}

function Show-BitLockerEvents([datetime]$Since) {
    # BitLocker API / Management events
    $apiIds = 813, 834, 842, 846, 851
    # BitLocker Driver events
    $driverIds = 24577, 24579, 24635, 24636

    Write-Host "`n=== BitLocker API / Management Events (since $Since) ==="
    Get-WinEvent -FilterHashtable @{
        LogName   = "Microsoft-Windows-BitLocker/BitLocker Management"
        Id        = $apiIds
        StartTime = $Since
    } -ErrorAction SilentlyContinue |
        Sort-Object TimeCreated |
        Select-Object TimeCreated, Id, Message |
        Format-Table -AutoSize -Wrap

    Write-Host "`n=== BitLocker Driver Events (since $Since) ==="
    Get-WinEvent -FilterHashtable @{
        ProviderName = "Microsoft-Windows-BitLocker-Driver"
        Id           = $driverIds
        StartTime    = $Since
    } -ErrorAction SilentlyContinue |
        Sort-Object TimeCreated |
        Select-Object TimeCreated, Id, Message |
        Format-Table -AutoSize -Wrap
}
