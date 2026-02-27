# 20-Create-PowerShellEncodedTask.ps1
param(
  [string]$BaseName="SOC-Lab",
  [string]$TaskPath="\",
  [string]$OutputFile="$env:ProgramData\SocLab\ScheduledTaskTest.log",
  [switch]$RunAsSystem=$true,
  [switch]$KeepTask,
  [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Ensure-OutputPath $OutputFile

$TaskName = "$BaseName-PwshEncoded"
Remove-TaskIfExists -TaskPath $TaskPath -TaskName $TaskName

# Benign PowerShell command (writes a marker)
$cmd = "Add-Content -Path `"$OutputFile`" -Value `"$([DateTime]::UtcNow.ToString('o')) PwshEncodedTaskRun`""
# EncodedCommand expects UTF-16LE bytes then Base64
$bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
$b64   = [Convert]::ToBase64String($bytes)

$action   = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -EncodedCommand $b64"
$trigger  = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(10)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable

if ($RunAsSystem) {
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null
} else {
  Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $action -Trigger $trigger -Settings $settings | Out-Null
}

Start-Sleep -Seconds 1
Start-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
Start-Sleep -Seconds 3

Write-Host "[*] Created + ran PowerShell EncodedCommand task: $TaskPath$TaskName"

if (-not $KeepTask) {
  Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
}

if ($ShowEvents) { Show-RecentEvents -Since $start }
