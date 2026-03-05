#!/usr/bin/env pwsh
# Simple Slack → OpenClaw Bridge (Polling)
$ConfigPath = "C:\Users\Administrator\.openclaw\workspace\config\slack_bridge.json"
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$botToken = $config.slack.botToken
$openclawToken = $config.openclaw.token
$openclawUrl = "http://127.0.0.1:18789"
$channels = $config.channels

$auth = Invoke-RestMethod -Uri "https://slack.com/api/auth.test" -Headers @{Authorization="Bearer $botToken"} -Method Get -TimeoutSec 10
if (-not $auth.ok) { Write-Error "Slack auth failed"; exit 1 }
$botId = $auth.user_id

$lastTs = @{}

Write-Host "Slack bridge running..."

while ($true) {
    foreach ($kv in $channels.PSObject.Properties) {
        $agentId = $kv.Name
        $channelId = $kv.Value
        try {
            $response = Invoke-RestMethod -Uri "https://slack.com/api/conversations.history" -Method Get -Headers @{Authorization="Bearer $botToken"} -Body @{channel=$channelId;limit=1;inclusive=1} -TimeoutSec 10
            if ($response.ok -and $response.messages.Count -gt 0) {
                $msg = $response.messages[0]
                if ($msg.user -eq $botId) { continue }
                if ($lastTs.ContainsKey($channelId) -and $msg.ts -le $lastTs[$channelId]) { continue }
                $lastTs[$channelId] = $msg.ts
                $text = $msg.text.Trim()
                Write-Host "[$agentId] $text"
                $resp = Invoke-RestMethod -Uri "$openclawUrl/api/v1/sessions/message" -Method Post -Headers @{Authorization="Bearer $openclawToken"} -Body (@{message=$text;agentId=$agentId} | ConvertTo-Json) -TimeoutSec 30 -ErrorAction Stop
                $reply = if ($resp.reply) { $resp.reply } elseif ($resp.content) { $resp.content } else { "..." }
                $slackBody = @{channel=$channelId;text="🤖 *$agentId*: $reply"} | ConvertTo-Json
                Invoke-RestMethod -Uri "https://slack.com/api/chat.postMessage" -Method Post -Headers @{Authorization="Bearer $botToken";"Content-Type"="application/json"} -Body $slackBody -TimeoutSec 10 | Out-Null
                Write-Host "  ✓ Replied"
            }
        } catch { }
    }
    Start-Sleep -Seconds 2
}
