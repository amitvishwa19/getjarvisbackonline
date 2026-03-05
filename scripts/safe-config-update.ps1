#!/usr/bin/env pwsh
# Safe Config Update Tool for Windows
# Features: backup, JSON validation, diff preview, auto-rollback on failure, optional gateway restart

param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigPath,

    [Parameter(Mandatory=$true)]
    [string]$JqExpression,

    [Parameter(Mandatory=$true)]
    [string]$NewValue,

    [switch]$RestartGateway,
    [switch]$Yes
)

$ErrorActionPreference = "Stop"

# Validate jq exists (use PowerShell ConvertFrom-Json instead, but we need jq for complex paths)
# Actually we can do without jq using PowerShell's JSON manipulation
function Update-JsonProperty {
    param([string]$Path, [string]$Expression, [string]$Value)
    $json = Get-Content $Path -Raw | ConvertFrom-Json
    # Evaluate expression like '.gateway.port'
    $parts = $Expression -split '\.'
    $current = $json
    for ($i=0; $i -lt $parts.Count-1; $i++) {
        $part = $parts[$i]
        if ($current.PSObject.Properties.Name -contains $part) {
            $current = $current.$part
        } else {
            throw "Path segment '$part' not found in JSON"
        }
    }
    $finalProp = $parts[-1]
    $current | Add-Member -Force -MemberType NoteProperty -Name $finalProp -Value ($Value | ConvertFrom-Json)
    $json | ConvertTo-Json -Depth 10 | Set-Content $Path -Encoding UTF8
}

function Test-JsonSyntax {
    param([string]$JsonString)
    try {
        $null = $JsonString | ConvertFrom-Json -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Main
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Config file not found: $ConfigPath"
    exit 1
}

# Backup
$backupDir = "backups"
$backupFile = Join-Path $backupDir "$(Get-Date -Format 'yyyyMMdd_HHmmss')_$(Split-Path $ConfigPath -Leaf).bak"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
Copy-Item $ConfigPath $backupFile -Force
Write-Host "✓ Backup created: $backupFile" -ForegroundColor Green

# Preview change
Write-Host "`n=== Preview of Changes ===" -ForegroundColor Cyan
$originalJson = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$originalValue = Invoke-Expression "`$originalJson$JqExpression" 2>$null
Write-Host "Path: $JqExpression"
Write-Host "Current: $originalValue"
Write-Host "New: $NewValue"

if (-not $Yes) {
    $confirm = Read-Host "`nApply this change? (y/N)"
    if ($confirm -notmatch '^[Yy]$') {
        Write-Host "Cancelled."
        exit 0
    }
}

# Apply change
try {
    # Parse and apply
    Update-JsonProperty -Path $ConfigPath -Expression $JqExpression -Value $NewValue
    Write-Host "✓ Config updated" -ForegroundColor Green
} catch {
    Write-Error "Failed to apply change: $_"
    # Rollback
    Write-Host "Rolling back from backup..." -ForegroundColor Yellow
    Copy-Item $backupFile $ConfigPath -Force
    Write-Host "✓ Rollback complete" -ForegroundColor Green
    exit 1
}

# Validate JSON syntax
$content = Get-Content $ConfigPath -Raw
if (-not (Test-JsonSyntax $content)) {
    Write-Error "Resulting config has invalid JSON! Rolling back..."
    Copy-Item $backupFile $ConfigPath -Force
    Write-Host "✓ Rollback complete" -ForegroundColor Green
    exit 1
}

# Show diff (simple)
Write-Host "`n=== Diff ===" -ForegroundColor Cyan
$diff = Compare-Object (Get-Content $backupFile) (Get-Content $ConfigPath) -SyncWindow 0
if ($diff) {
    $diff | ForEach-Object {
        $indicator = if ($_.SideIndicator -eq '=>') { '+' } else { '-' }
        Write-Host "$indicator $($_.InputObject)"
    }
} else {
    Write-Host "No changes (value already set?)" -ForegroundColor Yellow
}

# Restart gateway if requested
if ($RestartGateway) {
    Write-Host "`nRestarting OpenClaw gateway..." -ForegroundColor Cyan
    # Try nssm service
    $serviceName = "OpenClawGateway"
    $nssmPath = "C:\nssm\nssm.exe"
    if (Test-Path $nssmPath) {
        & $nssmPath restart $serviceName
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Gateway restarted via NSSM" -ForegroundColor Green
        } else {
            Write-Warning "NSSM restart failed, try manually: nssm start $serviceName"
        }
    } else {
        # Try openclaw CLI
        try {
            openclaw gateway restart
            Write-Host "✓ Gateway restarted via CLI" -ForegroundColor Green
        } catch {
            Write-Warning "Could not restart gateway automatically. Please restart manually."
        }
    }
}

Write-Host "`n✅ All done!" -ForegroundColor Green
