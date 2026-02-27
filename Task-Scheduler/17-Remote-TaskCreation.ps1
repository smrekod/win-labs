# 17-Remote-TaskCreation.ps1
<#
SAFETY STUB:
Remote task creation with credentials can be abused for unauthorized access.
This script DOES NOT execute anything remotely.

Use this only to document the command you would run in an isolated, authorized lab.
#>
param(
  [string]$TargetHost = "LAB-VM-01",
  [string]$TaskName   = "SOC-Lab-Remote",
  [string]$OutputFile = "$env:ProgramData\SocLab\ScheduledTaskTest.log"
)

$tr = "cmd.exe /c echo $([DateTime]::UtcNow.ToString('o')) remote-task >> `"$OutputFile`""

Write-Host "This is a NON-EXECUTING stub."
Write-Host "In an authorized lab, a remote create command would look like:"
Write-Host ""
Write-Host "schtasks /Create /S $TargetHost /TN $TaskName /TR `"$tr`" /SC ONCE /ST 23:59 /RL HIGHEST /RU SYSTEM /F"
Write-Host ""
Write-Host "Not executed."
