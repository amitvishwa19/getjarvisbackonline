# Doctor-X Complete Setup — Self-Elevating PowerShell Script
# This script will automatically request Administrator privileges

# Check for admin
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "=== Doctor-X Task Scheduler Setup (Admin) ===" -ForegroundColor Cyan
$workspace = "C:\Users\Administrator\.openclaw\workspace\subagents\doctor-x\scripts"

# Create tasks
try {
    # 1. Health Check (every 10 min)
    $action1 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$workspace\monitor_health.ps1`""
    $trigger1 = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 10) -RepetitionDuration (New-TimeSpan -Days 3650)
    Register-ScheduledTask -TaskName "Doctor-X Health Check" -Action $action1 -Trigger $trigger1 -RunLevel Highest -Force -ErrorAction Stop
    Write-Host "✅ Health Check (every 10 min)" -ForegroundColor Green

    # 2. System Report (every 5 min)
    $action2 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$workspace\system_report.ps1`""
    $trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 3650)
    Register-ScheduledTask -TaskName "Doctor-X System Report" -Action $action2 -Trigger $trigger2 -RunLevel Highest -Force -ErrorAction Stop
    Write-Host "✅ System Report (every 5 min)" -ForegroundColor Green

    # 3. Log Cleanup (daily 2 AM)
    $action3 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$workspace\cleanup_logs.ps1`""
    $trigger3 = New-ScheduledTaskTrigger -Daily -At 2:00AM
    Register-ScheduledTask -TaskName "Doctor-X Log Cleanup" -Action $action3 -Trigger $trigger3 -RunLevel Highest -Force -ErrorAction Stop
    Write-Host "✅ Log Cleanup (daily 2 AM)" -ForegroundColor Green

    # 4. Backup Verify (weekly Sun 3 AM)
    $action4 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$workspace\verify_backup.ps1`""
    $trigger4 = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3:00AM
    Register-ScheduledTask -TaskName "Doctor-X Backup Verify" -Action $action4 -Trigger $trigger4 -RunLevel Highest -Force -ErrorAction Stop
    Write-Host "✅ Backup Verify (weekly Sun 3 AM)" -ForegroundColor Green

    # 5. Auto Recovery (every 15 min)
    $action5 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$workspace\auto_recovery.ps1`""
    $trigger5 = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Days 3650)
    Register-ScheduledTask -TaskName "Doctor-X Auto Recovery" -Action $action5 -Trigger $trigger5 -RunLevel Highest -Force -ErrorAction Stop
    Write-Host "✅ Auto Recovery (every 15 min)" -ForegroundColor Green

    Write-Host "" -ForegroundColor Cyan
    Write-Host "🎉 All Doctor-X tasks scheduled successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Verifying..." -ForegroundColor Yellow
    schtasks /query /tn "Doctor-X*" /fo TABLE | findstr "Doctor-X"
    
    Write-Host "" -ForegroundColor Cyan
    Write-Host "✅ Doctor-X is now monitoring your system 24/7!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor White
    Write-Host " 1. Check Slack #doctor-x for first report (within 5 min)"
    Write-Host " 2. Test: schtasks /run /tn `"Doctor-X Health Check`""
    Write-Host " 3. View logs: Get-Content `"$workspace\..\health_log.txt`""
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
} catch {
    Write-Host "❌ ERROR: $_" -ForegroundColor Red
    Write-Host "Try running as Administrator manually." -ForegroundColor Yellow
    pause
}
