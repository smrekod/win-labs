# 19-Create-HighPrivilegeTask.ps1
param(
  [string]$BaseName="SOC-Lab",
  [string]$TaskPath="\",
  [string]$OutputFile="$env:ProgramData\SocLab\ScheduledTaskTest.log",
  [switch]$KeepTask,
  [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Ensure-OutputPath $OutputFile

$TaskName = "$BaseName-HighPriv"
Remove-TaskIfExists -TaskPath $TaskPath -TaskName $TaskName

$action   = New-BenignAction -OutputFile $OutputFile -marker "HighPrivTaskRun"
$trigger  = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(10)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null
Start-Sleep -Seconds 1

Write-Host "[*] Created SYSTEM + Highest task: $TaskPath$TaskName"

if (-not $KeepTask) {
  Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
}

if ($ShowEvents) { Show-RecentEvents -Since $start }
