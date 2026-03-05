#!/usr/bin/env pwsh
# Doctor-X Task Scheduler Setup
# Run as Administrator

$workspace = "C:\Users\Administrator\.openclaw\workspace\subagents\doctor-x\scripts"

# 1. Health Check (every 10 min)
$action1 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$workspace\monitor_health.ps1`""
$trigger1 = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 10) -RepetitionDuration (New-TimeSpan -Days 3650)
Register-ScheduledTask -TaskName "Doctor-X Health Check" -Action $action1 -Trigger $trigger1 -RunLevel Highest -Force
Write-Host "✅ Scheduled: Health Check every 10 min"

# 2. System Report (every 5 min)
$action2 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$workspace\system_report.ps1`""
$trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 3650)
Register-ScheduledTask -TaskName "Doctor-X System Report" -Action $action2 -Trigger $trigger2 -RunLevel Highest -Force
Write-Host "✅ Scheduled: System Report every 5 min"

# 3. Log Cleanup (daily 2 AM)
$action3 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$workspace\cleanup_logs.ps1`""
$trigger3 = New-ScheduledTaskTrigger -Daily -At 2:00AM
Register-ScheduledTask -TaskName "Doctor-X Log Cleanup" -Action $action3 -Trigger $trigger3 -RunLevel Highest -Force
Write-Host "✅ Scheduled: Log Cleanup daily 2 AM"

# 4. Backup Verify (weekly Sunday 3 AM)
$action4 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$workspace\verify_backup.ps1`""
$trigger4 = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3:00AM
Register-ScheduledTask -TaskName "Doctor-X Backup Verify" -Action $action4 -Trigger $trigger4 -RunLevel Highest -Force
Write-Host "✅ Scheduled: Backup Verify weekly Sun 3 AM"

# 5. Auto Recovery (every 15 min)
$action5 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$workspace\auto_recovery.ps1`""
$trigger5 = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Days 3650)
Register-ScheduledTask -TaskName "Doctor-X Auto Recovery" -Action $action5 -Trigger $trigger5 -RunLevel Highest -Force
Write-Host "✅ Scheduled: Auto Recovery every 15 min"

Write-Host ""
Write-Host "🎉 All Doctor-X tasks scheduled successfully!"
Write-Host "Check with: schtasks /query /tn `"Doctor-X*`" /fo TABLE"
