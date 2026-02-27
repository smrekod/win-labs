# 08-Fail-BadCredentials.ps1
param(
  [string]$BaseName="SOC-Lab",
  [string]$TaskPath="\",
  [string]$OutputFile="$env:ProgramData\SocLab\ScheduledTaskTest.log",
  [switch]$KeepArtifacts,   # keep user+task for inspection
  [switch]$ShowEvents
)

$start = Get-Date
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Common.ps1"

Assert-Admin
Ensure-OutputPath $OutputFile

function New-RandomPasswordPlain([int]$length = 20) {
  $chars = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%^&*()-_=+"
  -join (1..$length | ForEach-Object { $chars[Get-Random -Minimum 0 -Maximum $chars.Length] })
}

function New-TempLocalUser([string]$UserName, [string]$PlainPassword) {
  $sec = ConvertTo-SecureString $PlainPassword -AsPlainText -Force

  if (Get-Command New-LocalUser -ErrorAction SilentlyContinue) {
    # Standard local user
    New-LocalUser -Name $UserName -Password $sec -PasswordNeverExpires:$true -AccountNeverExpires:$true | Out-Null
  } else {
    # Fallback for older systems
    & net user $UserName $PlainPassword /add | Out-Null
  }
}

function Set-TempLocalUserPassword([string]$UserName, [string]$PlainPassword) {
  $sec = ConvertTo-SecureString $PlainPassword -AsPlainText -Force

  if (Get-Command Set-LocalUser -ErrorAction SilentlyContinue) {
    Set-LocalUser -Name $UserName -Password $sec | Out-Null
  } else {
    & net user $UserName $PlainPassword | Out-Null
  }
}

function Remove-TempLocalUser([string]$UserName) {
  if (Get-Command Remove-LocalUser -ErrorAction SilentlyContinue) {
    Remove-LocalUser -Name $UserName -ErrorAction SilentlyContinue
  } else {
    & net user $UserName /delete | Out-Null
  }
}

$TempUser = "$BaseName-TempTaskUser"
$TaskName = "$BaseName-FailBadCreds"

# Clean any leftovers
Remove-TaskIfExists -TaskPath $TaskPath -TaskName $TaskName
try { Remove-TempLocalUser -UserName $TempUser } catch {}

# Step 1: create temp user with Password1
$Password1 = New-RandomPasswordPlain
New-TempLocalUser -UserName $TempUser -PlainPassword $Password1

# Step 2: register task to run as the temp user (stores Password1)
$action   = New-BenignAction -OutputFile $OutputFile -marker "BadCredsTask"
$trigger  = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(10)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable

# Register with explicit -User/-Password so Task Scheduler stores credentials
Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $action -Trigger $trigger -Settings $settings -User $TempUser -Password $Password1 | Out-Null
Start-Sleep -Seconds 1

# Step 3: change user password so stored credentials are now wrong
$Password2 = New-RandomPasswordPlain
Set-TempLocalUserPassword -UserName $TempUser -PlainPassword $Password2
Start-Sleep -Seconds 1

# Step 4: attempt to run (should fail: commonly Event ID 101; may also produce 311 depending on host/policy)
Start-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
Start-Sleep -Seconds 3

try {
  $info = Get-ScheduledTaskInfo -TaskName $TaskName -TaskPath $TaskPath
  Write-Host "[*] LastRunTime: $($info.LastRunTime) | LastTaskResult: $($info.LastTaskResult)"
} catch {}

if (-not $KeepArtifacts) {
  try { Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false } catch {}
  try { Remove-TempLocalUser -UserName $TempUser } catch {}
} else {
  Write-Host "[!] KeepArtifacts set: leaving task '$TaskName' and user '$TempUser' for inspection."
}

if ($ShowEvents) { Show-RecentEvents -Since $start }
