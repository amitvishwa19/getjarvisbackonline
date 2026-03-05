#!/usr/bin/env pwsh
# Debug Slack Bridge — test each component

Write-Host "=== Slack Bridge Diagnostics ==="
Write-Host ""

# 1. Check Slack bot token
$botToken = "YOUR_SLACK_BOT_TOKEN"
Write-Host "1. Testing Slack auth..."
$auth = Invoke-RestMethod -Uri "https://slack.com/api/auth.test" -Headers @{Authorization="Bearer $botToken"} -Method Get -TimeoutSec 10
if ($auth.ok) {
    Write-Host "   ✅ Slack auth OK — Bot: $($auth.user), Team: $($auth.team)"
} else {
    Write-Host "   ❌ Slack auth FAILED: $($auth.error)"
    exit 1
}

# 2. Check channel access
$channelId = "C0AHWQG9536"
Write-Host "2. Testing channel access to $channelId..."
$chResp = Invoke-RestMethod -Uri "https://slack.com/api/conversations.info" -Headers @{Authorization="Bearer $botToken"} -Method Get -Body @{channel=$channelId} -TimeoutSec 10
if ($chResp.ok) {
    Write-Host "   ✅ Channel accessible: $($chResp.channel.name)"
} else {
    Write-Host "   ❌ Channel access FAILED: $($chResp.error)"
    Write-Host "   Is bot invited to the channel? Use: /invite @Jarvis"
    exit 1
}

# 3. Check OpenClaw gateway
$openclawUrl = "http://127.0.0.1:18789"
$openclawToken = "YOUR_OPENCLAW_GATEWAY_TOKEN"
Write-Host "3. Testing OpenClaw gateway..."
try {
    $health = Invoke-RestMethod -Uri "$openclawUrl/health" -Method Get -TimeoutSec 5
    Write-Host "   ✅ Gateway healthy: $($health.status)"
} catch {
    Write-Host "   ❌ Gateway FAILED: $_"
    exit 1
}

# 4. Test sending message to agent
Write-Host "4. Testing agent message..."
$body = @{message="test";agentId="bumblebee"} | ConvertTo-Json
$resp = Invoke-RestMethod -Uri "$openclawUrl/api/v1/sessions/message" -Method Post -Headers @{Authorization="Bearer $openclawToken"} -Body $body -TimeoutSec 10 -ErrorAction Stop
if ($resp.reply -or $resp.content) {
    Write-Host "   ✅ Agent responded: $($resp.reply ?? $resp.content)"
} else {
    Write-Host "   ⚠️ Agent accepted but no reply content"
}

# 5. Test posting to Slack
Write-Host "5. Testing Slack post..."
$testMsg = "🔍 *Bridge Diagnostic* — All systems checked."
$postBody = @{channel=$channelId; text=$testMsg} | ConvertTo-Json
$post = Invoke-RestMethod -Uri "https://slack.com/api/chat.postMessage" -Method Post -Headers @{Authorization="Bearer $botToken";"Content-Type"="application/json"} -Body $postBody -TimeoutSec 10
if ($post.ok) {
    Write-Host "   ✅ Slack post successful"
} else {
    Write-Host "   ❌ Slack post FAILED: $($post.error)"
}

Write-Host ""
Write-Host "=== Diagnostics Complete ==="
