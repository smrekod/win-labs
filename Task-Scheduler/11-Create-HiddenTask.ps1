# 11-Create-HiddenTask.ps1
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

$TaskName = "$BaseName-Hidden"
Remove-TaskIfExists -TaskPath $TaskPath -TaskName $TaskName

$action   = New-BenignAction -OutputFile $OutputFile -marker "HiddenTaskRun"
$trigger  = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(10)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable
$settings.Hidden = $true

if ($RunAsSystem) {
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null
} else {
  Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $action -Trigger $trigger -Settings $settings | Out-Null
}

Start-Sleep -Seconds 1
Write-Host "[*] Created hidden task: $TaskPath$TaskName"

if (-not $KeepTask) {
  Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
}

if ($ShowEvents) { Show-RecentEvents -Since $start }
