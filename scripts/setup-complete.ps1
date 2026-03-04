#!/usr/bin/env pwsh
# Complete OpenClaw Agent Setup Wizard
# This script sets up a fully functional agent from scratch

param(
    [switch]$SkipGatewayService,
    [switch]$SkipTaskScheduler,
    [string]$AgentName = "Jarvis"
)

$ErrorActionPreference = "Stop"
$Workspace = "$env:USERPROFILE\.openclaw\workspace"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  OpenClaw Agent Complete Setup Wizard" -ForegroundColor Cyan
Write-Host "  Agent: $AgentName" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# Step 1: Create Directory Structure
# ============================================
Write-Host "[1/7] Creating directory structure..." -ForegroundColor Yellow
$dirs = @(
    "$Workspace",
    "$Workspace\config-templates",
    "$Workspace\config",
    "$Workspace\scripts",
    "$Workspace\systemd",
    "$Workspace\memory",
    "$Workspace\subagents",
    "$Workspace\.openclaw"
)
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}
Write-Host "✓ Directories created" -ForegroundColor Green

# ============================================
# Step 2: Copy Core Files from Templates
# ============================================
Write-Host "[2/7] Copying config templates..." -ForegroundColor Yellow
$templates = @(
    "llm-providers.json",
    "llm-providers-offline.json",
    "slack_bridge.json"
)
foreach ($tpl in $templates) {
    $src = "$Workspace\config-templates\$tpl"
    $dst = "$Workspace\config\$tpl"
    if (Test-Path $src) {
        Copy-Item $src $dst -Force
    } else {
        Write-Warning "Template missing: $tpl (will be created by docs)"
    }
}
Write-Host "✓ Config templates copied" -ForegroundColor Green

# ============================================
# Step 3: Set Environment Variables (Interactive)
# ============================================
Write-Host "[3/7] Setting environment variables..." -ForegroundColor Yellow
Write-Host "Please enter the following values. Press Enter to skip (optional)." -ForegroundColor Gray

function Prompt-EnvVar {
    param([string]$Name, [string]$Description)
    $current = [System.Environment]::GetEnvironmentVariable($Name, "User")
    if ($current) {
        Write-Host "$Name is already set to: $current" -ForegroundColor DarkGray
        $change = Read-Host "Change it? (y/N)"
        if ($change -notmatch '^[Yy]$') { return }
    }
    $value = Read-Host "$Name ($Description)"
    if ($value) {
        [System.Environment]::SetEnvironmentVariable($Name, $value, "User")
        Write-Host "✓ Set $Name" -ForegroundColor Green
    }
}

Prompt-EnvVar "OPENROUTER_API_KEY" "Your OpenRouter API key (https://openrouter.ai/keys)"
Prompt-EnvVar "OPENCLAW_TOKEN" "Gateway token (will generate if empty)"
Prompt-EnvVar "TELEGRAM_BOT_TOKEN" "Telegram bot token from @BotFather"
Prompt-EnvVar "TELEGRAM_CHAT_ID" "Your chat ID"
Prompt-EnvVar "GIT_REPO" "Backup repo URL (e.g., https://github.com/you/backup.git)"
Prompt-EnvVar "TAVILY_API_KEY" "Optional: Tavily API key"
Prompt-EnvVar "FIRECRAWL_API_KEY" "Optional: Firecrawl API key"
Prompt-EnvVar "OPENCLAW_ALLOWED_AGENTS" "Comma-separated allowed subagents (e.g., bumblebee,doctor-x)"

# Generate OPENCLAW_TOKEN if not set
if (-not [System.Environment]::GetEnvironmentVariable("OPENCLAW_TOKEN", "User")) {
    Write-Host "Generating new OPENCLAW_TOKEN..." -ForegroundColor Yellow
    $token = openclaw token generate 2>$null | Select-String -Pattern 'token: (\S+)' | ForEach-Object {$_.Matches.Groups[1].Value}
    if (-not $token) {
        $token = [System.Convert]::ToBase64String((1..32 | ForEach-Object {Get-Random -Maximum 256}))
    }
    [System.Environment]::SetEnvironmentVariable("OPENCLAW_TOKEN", $token, "User")
    Write-Host "✓ OPENCLAW_TOKEN generated: $token" -ForegroundColor Green
}

Write-Host ""

# ============================================
# Step 4: Create Identity Files (if missing)
# ============================================
Write-Host "[4/7] Creating identity files..." -ForegroundColor Yellow
$identityFile = "$Workspace\IDENTITY.md"
$userFile = "$Workspace\USER.md"

if (-not (Test-Path $identityFile)) {
    @"
# IDENTITY.md - Who Am I?

- **Name:** $AgentName
- **Creature:** AI assistant
- **Vibe:** Helpful, competent, straightforward
- **Emoji:** 🤖
"@ | Out-File $identityFile -Encoding UTF8
    Write-Host "✓ Created IDENTITY.md" -ForegroundColor Green
}

if (-not (Test-Path $userFile)) {
    @"
# USER.md - About Your Human

- **Name:** 
- **What to call them:** 
- **Timezone:** 
- **Notes:** 
"@ | Out-File $userFile -Encoding UTF8
    Write-Host "✓ Created USER.md (please edit)" -ForegroundColor Green
}

Write-Host ""

# ============================================
# Step 5: Initialize Git (if not already)
# ============================================
Write-Host "[5/7] Initializing Git repository..." -ForegroundColor Yellow
Set-Location $Workspace
if (-not (Test-Path ".git")) {
    git init
    git config user.email "agent@localhost"
    git config user.name $AgentName
    # Add remote if GIT_REPO set
    $gitRepo = [System.Environment]::GetEnvironmentVariable("GIT_REPO", "User")
    if ($gitRepo) {
        git remote add origin $gitRepo
        Write-Host "✓ Git remote added: $gitRepo" -ForegroundColor Green
    } else {
        Write-Host "⚠ GIT_REPO not set, skipping remote" -ForegroundColor Yellow
    }
    # Initial commit
    git add -A
    git commit -m "Initial agent workspace setup" -q
    Write-Host "✓ Initial commit created" -ForegroundColor Green
} else {
    Write-Host "✓ Git repository already exists" -ForegroundColor Green
}

Write-Host ""

# ============================================
# Step 6: Import Task Scheduler Tasks (Optional)
# ============================================
if (-not $SkipTaskScheduler) {
    Write-Host "[6/7] Importing Task Scheduler tasks..." -ForegroundColor Yellow
    $tasks = @(
        "backup_task.xml",
        "cloud-sync_task.xml",
        "health-watcher_task.xml"
    )
    foreach ($task in $tasks) {
        $xmlPath = "$Workspace\scripts\$task"
        if (Test-Path $xmlPath) {
            try {
                schtasks /create /tn "OpenClaw $($task.Replace('_task.xml',''))" /xml $xmlPath /f | Out-Null
                Write-Host "✓ Task created: $task" -ForegroundColor Green
            } catch {
                Write-Warning "Failed to create task $task: $_ (may need Admin rights)"
            }
        } else {
            Write-Warning "Task file missing: $task"
        }
    }
} else {
    Write-Host "[6/7] Skipping Task Scheduler setup" -ForegroundColor DarkGray
}

Write-Host ""

# ============================================
# Step 7: Install Gateway Service (Optional)
# ============================================
if (-not $SkipGatewayService) {
    Write-Host "[7/7] Gateway service (NSSM)..." -ForegroundColor Yellow
    $nssmPath = "C:\nssm\nssm.exe"
    if (Test-Path $nssmPath) {
        try {
            powershell -ExecutionPolicy Bypass -File "$Workspace\scripts\gateway-service-nssm.ps1"
            Write-Host "✓ Gateway service installed (NSSM)" -ForegroundColor Green
        } catch {
            Write-Warning "Service installation failed: $_"
        }
    } else {
        Write-Host "⚠ NSSM not found at C:\nssm\nssm.exe" -ForegroundColor Yellow
        Write-Host "  Download from https://nssm.cc and extract to C:\nssm" -ForegroundColor Gray
    }
} else {
    Write-Host "[7/7] Skipping gateway service setup" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "1. Edit IDENTITY.md and USER.md with your details" -ForegroundColor Gray
Write-Host "2. Ensure config/*.json files exist (copy from config-templates if missing)" -ForegroundColor Gray
Write-Host "3. Start the gateway: openclaw gateway start" -ForegroundColor Gray
Write-Host "4. Verify health: curl http://127.0.0.1:18789/health" -ForegroundColor Gray
Write-Host ""
Write-Host "Your agent workspace is ready at: $Workspace" -ForegroundColor Cyan
Write-Host ""
