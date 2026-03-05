#!/usr/bin/env pwsh
# Bumblebee Slack Update — posts status to Slack channel
# This runs as scheduled task (every hour)

$SlackToken = $env:SLACK_BOT_TOKEN
$SlackChannel = $env:SLACK_CHANNEL_BUMBLEBEE

if (-not $SlackToken -or -not $SlackChannel) {
    Write-Error "SLACK_BOT_TOKEN and SLACK_CHANNEL_BUMBLEBEE must be set"
    exit 1
}

# Read PIPELINE to get current stats
$pipelinePath = "C:\Users\Administrator\.openclaw\workspace\subagents\bumblebee\PIPELINE.md"
$stats = @{
    researching = 0
    purchased = 0
    published = 0
    growing = 0
    listed = 0
    negotiating = 0
    sold = 0
}

if (Test-Path $pipelinePath) {
    $content = Get-Content $pipelinePath -Raw
    # Simple extraction - count numbers in table rows
    $stats.researching = ([regex]::Matches($content, "Researching Accounts.*?\| (\d+)").Groups[1].Value | Measure-Object -Sum).Sum
    $stats.purchased = ([regex]::Matches($content, "Accounts Purchased.*?\| (\d+)").Groups[1].Value | Measure-Object -Sum).Sum
    $stats.published = ([regex]::Matches($content, "Apps Published.*?\| (\d+)").Groups[1].Value | Measure-Object -Sum).Sum
    $stats.growing = ([regex]::Matches($content, "Growing \(downloads\):.*?(\d+)").Groups[1].Value | Measure-Object -Sum).Sum
    $stats.listed = ([regex]::Matches($content, "Listed for Sale.*?\| (\d+)").Groups[1].Value | Measure-Object -Sum).Sum
    $stats.negotiating = ([regex]::Matches($content, "Negotiating.*?\| (\d+)").Groups[1].Value | Measure-Object -Sum).Sum
    $stats.sold = ([regex]::Matches($content, "Sold.*?\| (\d+)").Groups[1].Value | Measure-Object -Sum).Sum
}

$now = Get-Date -Format "yyyy-MM-dd HH:mm"
$totalLeads = $stats.researching + $stats.purchased + $stats.listed + $stats.negotiating

$message = @"
📊 *Bumblebee Status Update* — $now

📈 Pipeline:
• Researching: $($stats.researching)
• Purchased: $($stats.purchased)
• Apps Published: $($stats.published)
• Growing: $($stats.growing)
• Listed: $($stats.listed)
• Negotiating: $($stats.negotiating)
• Sold: $($stats.sold)

🔢 Total Leads in Pipeline: $totalLeads
🤖 Agent: Active and monitoring

_Automated update from Bumblebee agent workspace_
"@

$body = @{channel=$SlackChannel; text=$message} | ConvertTo-Json
$resp = Invoke-RestMethod -Uri "https://slack.com/api/chat.postMessage" -Method Post -Headers @{Authorization="Bearer $SlackToken";"Content-Type"="application/json"} -Body $body -TimeoutSec 10

if ($resp.ok) {
    Write-Host "✅ Slack update posted ($now)"
} else {
    Write-Error "Slack post failed: $($resp.error)"
}
