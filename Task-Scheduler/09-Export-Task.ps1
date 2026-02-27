# 09-Export-Task.ps1
param(
  [string]$BaseName="SOC-Lab",
  [string]$TaskPath="\",
  [string]$OutputFile="$env:ProgramData\SocLab\ScheduledTaskTest.log",
  [string]$ExportDir="$env:ProgramData\SocLab\TaskExports",
  [switch]$RunAsSystem=$true,
  [switch]$KeepTask,
  [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Ensure-OutputPath $OutputFile
if (-not (Test-Path $ExportDir)) { New-Item -ItemType Directory -Path $ExportDir -Force | Out-Null }

$TaskName = "$BaseName-Export"
Remove-TaskIfExists -TaskPath $TaskPath -TaskName $TaskName
Register-TestTask -TaskPath $TaskPath -TaskName $TaskName -OutputFile $OutputFile -marker "ExportTask" -RunAsSystem ([bool]$RunAsSystem)
Start-Sleep -Seconds 1

# Export XML
$xmlPath = Join-Path $ExportDir "$TaskName.xml"
$taskObj = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
$xml     = $taskObj.Xml
$xml | Out-File -FilePath $xmlPath -Encoding UTF8

Write-Host "[*] Exported: $xmlPath"

if (-not $KeepTask) {
  Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
}

if ($ShowEvents) { Show-RecentEvents -Since $start }
