

$newRandomMinutes = Get-Random -Minimum 15 -Maximum 20
$nextRun = (Get-Date).AddMinutes($newRandomMinutes)

$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Scripts\Run-Random.ps1"
$trigger = New-ScheduledTaskTrigger -Once -At $nextRun
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "h" -Action $action -Trigger $trigger -Principal $principal -Force

Write-Host "Next run scheduled in $newRandomMinutes minutes (at $nextRun)" -ForegroundColor Green
