#!/usr/bin/env pwsh
# Post message to Slack channel via Web API

param(
    [Parameter(Mandatory=$true)]
    [string]$ChannelId,
    
    [Parameter(Mandatory=$true)]
    [string]$Message,
    
    [string]$BotToken = $env:SLACK_BOT_TOKEN
)

if ([string]::IsNullOrWhiteSpace($BotToken)) {
    Write-Error "SLACK_BOT_TOKEN environment variable not set"
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $BotToken"
    "Content-Type" = "application/json; charset=utf-8"
}

$body = @{
    channel = $ChannelId
    text = $Message
} | ConvertTo-Json -Depth 3

try {
    $response = Invoke-RestMethod -Uri "https://slack.com/api/chat.postMessage" `
        -Method Post `
        -Headers $headers `
        -Body $body `
        -TimeoutSec 10

    if ($response.ok) {
        Write-Host "✅ Posted to Slack channel $ChannelId"
        return $true
    } else {
        Write-Error "Slack API error: $($response.error)"
        return $false
    }
}
catch {
    Write-Error "Failed to post to Slack: $($_.Exception.Message)"
    return $false
}
