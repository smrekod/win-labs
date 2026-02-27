# 18-Create-CustomTaskFolder.ps1
param(
  [string]$BaseName="SOC-Lab",
  [string]$TaskPath="\SOC-Lab\CustomFolder\",
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

$TaskName = "$BaseName-CustomFolder"
Remove-TaskIfExists -TaskPath $TaskPath -TaskName $TaskName

Register-TestTask -TaskPath $TaskPath -TaskName $TaskName -OutputFile $OutputFile -marker "CustomFolderTaskRun" -RunAsSystem ([bool]$RunAsSystem)
Start-Sleep -Seconds 1

Write-Host "[*] Created task under custom path: $TaskPath$TaskName"

if (-not $KeepTask) {
  Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
}

if ($ShowEvents) { Show-RecentEvents -Since $start }
