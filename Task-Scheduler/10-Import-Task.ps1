# 10-Import-Task.ps1
param(
  [string]$BaseName="SOC-Lab",
  [string]$TaskPath="\",
  [string]$OutputFile="$env:ProgramData\SocLab\ScheduledTaskTest.log",
  [string]$ImportXmlPath="",   # if blank, this script will generate one by exporting first
  [switch]$RunAsSystem=$true,
  [switch]$KeepTask,
  [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Ensure-OutputPath $OutputFile

$SrcTask  = "$BaseName-Import-Source"
$TaskName = "$BaseName-Import"

# If no XML provided, create and export a source task
if ([string]::IsNullOrWhiteSpace($ImportXmlPath)) {
  Remove-TaskIfExists -TaskPath $TaskPath -TaskName $SrcTask
  Register-TestTask -TaskPath $TaskPath -TaskName $SrcTask -OutputFile $OutputFile -marker "ImportSourceTask" -RunAsSystem ([bool]$RunAsSystem)
  Start-Sleep -Seconds 1

  $ImportXmlPath = Join-Path $env:ProgramData "$SrcTask.xml"
  (Get-ScheduledTask -TaskName $SrcTask -TaskPath $TaskPath).Xml | Out-File -FilePath $ImportXmlPath -Encoding UTF8
  Write-Host "[*] Generated import XML: $ImportXmlPath"
}

# Import as a new task name
Remove-TaskIfExists -TaskPath $TaskPath -TaskName $TaskName

$xml = Get-Content -Raw -Path $ImportXmlPath
Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Xml $xml | Out-Null
Start-Sleep -Seconds 1

Write-Host "[*] Imported task: $TaskPath$TaskName"

if (-not $KeepTask) {
  try { Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false } catch {}
  try { Unregister-ScheduledTask -TaskName $SrcTask  -TaskPath $TaskPath -Confirm:$false } catch {}
}

if ($ShowEvents) { Show-RecentEvents -Since $start }
