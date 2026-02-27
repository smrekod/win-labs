# 21-Delete-Task-FileDirectly.ps1
<#
LAB ONLY.
Deletes the on-disk task definition file under:
  C:\Windows\System32\Tasks\<TaskPath><TaskName>

This can leave Task Scheduler in an inconsistent state on some systems.
Use only for your SOC testing VM snapshots.
#>
param(
  [string]$BaseName="SOC-Lab",
  [string]$TaskPath="\",
  [string]$OutputFile="$env:ProgramData\SocLab\ScheduledTaskTest.log",
  [switch]$RunAsSystem=$true,
  [switch]$AttemptCleanup,  # try to unregister after file delete (may fail)
  [switch]$ShowEvents
)

$start = Get-Date
$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Ensure-OutputPath $OutputFile

$TaskName = "$BaseName-FileDelete"
Remove-TaskIfExists -TaskPath $TaskPath -TaskName $TaskName
Register-TestTask -TaskPath $TaskPath -TaskName $TaskName -OutputFile $OutputFile -marker "FileDeleteTaskRun" -RunAsSystem ([bool]$RunAsSystem)
Start-Sleep -Seconds 1

# Convert TaskPath "\" to filesystem relative path
# "\" -> "" ; "\SOC-Lab\X\" -> "SOC-Lab\X\"
$rel = $TaskPath.Trim("\")
$taskFile = if ([string]::IsNullOrWhiteSpace($rel)) {
  Join-Path "$env:WINDIR\System32\Tasks" $TaskName
} else {
  Join-Path (Join-Path "$env:WINDIR\System32\Tasks" $rel) $TaskName
}

Write-Host "[*] Deleting task file: $taskFile"
if (Test-Path $taskFile) {
  Remove-Item -Path $taskFile -Force
  Start-Sleep -Seconds 1
  Write-Host "[*] Deleted task file directly."
} else {
  Write-Host "[!] Task file not found (path may differ on your system): $taskFile"
}

if ($AttemptCleanup) {
  Write-Host "[*] Attempting scheduler cleanup (unregister)..."
  try { Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false } catch { Write-Host "[!] Cleanup failed: $($_.Exception.Message)" }
}

if ($ShowEvents) { Show-RecentEvents -Since $start }
