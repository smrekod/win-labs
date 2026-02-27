# 03-Disable-Task.ps1
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

$TaskName = "$BaseName-Disable"
Remove-TaskIfExists -TaskPath $TaskPath -TaskName $TaskName
Register-TestTask -TaskPath $TaskPath -TaskName $TaskName -OutputFile $OutputFile -marker "DisableTask" -RunAsSystem ([bool]$RunAsSystem)
Start-Sleep -Seconds 1

Disable-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath | Out-Null
Start-Sleep -Seconds 1

if ($ShowEvents) { Show-RecentEvents -Since $start }
