# Common.ps1
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

function Ensure-OutputPath([string]$OutputFile) {
    $dir = Split-Path -Parent $OutputFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

function Enable-TaskTelemetry {
    Write-Host "[*] Enabling TaskScheduler Operational log channel..."
    & wevtutil sl "Microsoft-Windows-TaskScheduler/Operational" /e:true | Out-Null

    Write-Host "[*] Enabling audit subcategory: Other Object Access Events (4698-4702/4699)..."
    & auditpol /set /subcategory:"Other Object Access Events" /success:enable /failure:enable | Out-Null

    Write-Host "[*] Enabling audit subcategory: Process Creation (4688)..."
    & auditpol /set /subcategory:"Process Creation" /success:enable | Out-Null

    Write-Host "[*] Enabling command line in process creation events (4688)..."
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit"
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    New-ItemProperty -Path $regPath -Name "ProcessCreationIncludeCmdLine_Enabled" -PropertyType DWord -Value 1 -Force | Out-Null
}

function New-BenignAction([string]$OutputFile, [string]$marker) {
    $arg = "/c echo $([DateTime]::UtcNow.ToString('o')) $marker >> `"$OutputFile`""
    return New-ScheduledTaskAction -Execute "cmd.exe" -Argument $arg
}

function Remove-TaskIfExists([string]$TaskPath, [string]$TaskName) {
    $existing = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
    if ($null -ne $existing) {
        Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
        Start-Sleep -Seconds 1
    }
}

function Register-TestTask(
    [string]$TaskPath,
    [string]$TaskName,
    [string]$OutputFile,
    [string]$marker,
    [bool]$RunAsSystem
) {
    $action   = New-BenignAction -OutputFile $OutputFile -marker $marker
    $trigger  = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(10)
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    if ($RunAsSystem) {
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null
    } else {
        Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $action -Trigger $trigger -Settings $settings | Out-Null
    }
}

function Update-TestTask(
    [string]$TaskPath,
    [string]$TaskName,
    [string]$OutputFile,
    [string]$marker
) {
    $action = New-BenignAction -OutputFile $OutputFile -marker $marker
    Set-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $action | Out-Null
}

function Show-RecentEvents([datetime]$Since) {
    Write-Host "`n=== Security (since $Since) ==="
    $secIds = 4688,4698,4699,4700,4701,4702
    Get-WinEvent -FilterHashtable @{ LogName="Security"; Id=$secIds; StartTime=$Since } -ErrorAction SilentlyContinue |
        Sort-Object TimeCreated |
        Select-Object -Last 60 TimeCreated, Id, ProviderName, Message |
        Format-Table -AutoSize

    Write-Host "`n=== TaskScheduler/Operational (since $Since) ==="
    $tsIds = 100,101,102,103,106,129,140,141,142,200,201,311,319
    Get-WinEvent -FilterHashtable @{ LogName="Microsoft-Windows-TaskScheduler/Operational"; Id=$tsIds; StartTime=$Since } -ErrorAction SilentlyContinue |
        Sort-Object TimeCreated |
        Select-Object -Last 120 TimeCreated, Id, ProviderName, Message |
        Format-Table -AutoSize
}
