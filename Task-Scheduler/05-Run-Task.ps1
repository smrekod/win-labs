# 05-Run-Task.ps1
param(
  [string]$BaseName="SOC-Lab",
  [string]$TaskPath="\",
  [string]$OutputFile="$env:ProgramData\SocLab\ScheduledTaskTest.log",
  [switch]$RunAsSystem=$true,
  [switch]$ShowEvents
)

$start = Get-Date
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Ensure-OutputPath $OutputFile

$TaskName = "$BaseName-Run"
Remove-TaskIfExists -TaskPath $TaskPath -TaskName $TaskName
Register-TestTask -TaskPath $TaskPath -TaskName $TaskName -OutputFile $OutputFile -marker "RunTask" -RunAsSystem ([bool]$RunAsSystem)
Start-Sleep -Seconds 1

Start-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
Start-Sleep -Seconds 3

try {
  $info = Get-ScheduledTaskInfo -TaskName $TaskName -TaskPath $TaskPath
  Write-Host "[*] LastRunTime: $($info.LastRunTime) | LastTaskResult: $($info.LastTaskResult)"
} catch {}

if ($ShowEvents) { Show-RecentEvents -Since $start }
