# 23-Enumerate-AllTasks.ps1
param(
  [string]$OutDir="$env:ProgramData\SocLab\TaskInventory",
  [switch]$IncludeXml,     # export XML for each task (can be slow)
  [switch]$AlsoUseSchtasks # run schtasks /query for verbose output
)

$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$csvPath = Join-Path $OutDir "scheduled_tasks.csv"
$txtPath = Join-Path $OutDir "schtasks_query_verbose.txt"
$xmlDir  = Join-Path $OutDir "xml"

if ($IncludeXml -and -not (Test-Path $xmlDir)) { New-Item -ItemType Directory -Path $xmlDir -Force | Out-Null }

Write-Host "[*] Enumerating tasks via Get-ScheduledTask..."
$tasks = Get-ScheduledTask | ForEach-Object {
  [pscustomobject]@{
    TaskName   = $_.TaskName
    TaskPath   = $_.TaskPath
    State      = $_.State
    Author     = $_.Author
    URI        = $_.URI
    Description= $_.Description
  }
}

$tasks | Sort-Object TaskPath, TaskName | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csvPath
Write-Host "[*] Wrote: $csvPath"

if ($IncludeXml) {
  Write-Host "[*] Exporting task XML (may take time)..."
  foreach ($t in Get-ScheduledTask) {
    try {
      $safeName = ($t.TaskPath.Trim("\") + "_" + $t.TaskName) -replace '[\\/:*?"<>|]', '_'
      $p = Join-Path $xmlDir "$safeName.xml"
      $t.Xml | Out-File -FilePath $p -Encoding UTF8
    } catch {}
  }
  Write-Host "[*] XML exported to: $xmlDir"
}

if ($AlsoUseSchtasks) {
  Write-Host "[*] Running schtasks verbose query..."
  & schtasks /Query /FO LIST /V | Out-File -FilePath $txtPath -Encoding UTF8
  Write-Host "[*] Wrote: $txtPath"
}
