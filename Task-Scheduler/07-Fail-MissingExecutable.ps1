# 07-Fail-MissingExecutable.ps1
param(
  [string]$BaseName="SOC-Lab",
  [string]$TaskPath="\",
  [string]$OutputFile="$env:ProgramData\SocLab\ScheduledTaskTest.log",
  [switch]$RunAsSystem=$true,
  [switch]$KeepTask,
  [switch]$ShowEvents
)

$start = Get-Date
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Ensure-OutputPath $OutputFile

$TaskName = "$BaseName-FailMissingExe"
Remove-TaskIfExists -TaskPath $TaskPath -TaskName $TaskName

# Non-existent executable to force "Action start failed" / "Task start failed"
$missingExe = Join-Path $env:SystemRoot "System32\this_exe_should_not_exist_12345.exe"
$action   = New-ScheduledTaskAction -Execute $missingExe
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

try {
  $info = Get-ScheduledTaskInfo -TaskName $TaskName -TaskPath $TaskPath
  Write-Host "[*] LastRunTime: $($info.LastRunTime) | LastTaskResult: $($info.LastTaskResult)"
} catch {}

if (-not $KeepTask) {
  Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
}

if ($ShowEvents) { Show-RecentEvents -Since $start }
